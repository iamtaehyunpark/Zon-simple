import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../data/models/stamp.dart';
import '../../../../data/models/check_in.dart';
import '../../../../data/repositories/stamp_repository.dart';
import '../../../../data/repositories/check_in_repository.dart';
import '../../../../core/location/gps_service.dart';
import '../../../../core/photos/photo_service.dart';
import '../../../../core/places/place_models.dart';
import '../../../../core/places/place_service_provider.dart';

part 'checkin_provider.freezed.dart';
part 'checkin_provider.g.dart';

/// Which artifact the entry flow produces.
enum CheckinMode { checkIn, stamp }

// ExternalPlace wraps a PlaceResult for the UI layer.
@freezed
class ExternalPlace with _$ExternalPlace {
  const factory ExternalPlace({
    required String externalPlaceId,
    required String externalSource,
    required String name,
    required double lat,
    required double lng,
    String? address,
    String? category,
  }) = _ExternalPlace;

  factory ExternalPlace.fromResult(PlaceResult r) => ExternalPlace(
        externalPlaceId: r.placeId,
        externalSource: r.externalSource,
        name: r.name,
        lat: r.lat,
        lng: r.lng,
        address: r.address,
        category: r.categories.isNotEmpty ? r.categories.first : null,
      );
}

@freezed
class CheckinState with _$CheckinState {
  const factory CheckinState.idle() = _Idle;
  const factory CheckinState.locating() = _Locating;
  const factory CheckinState.placeSelected({
    required double lat,
    required double lng,
    required List<Stamp> nearbyStamps,
    ExternalPlace? suggestedPlace,
    @Default([]) List<ExternalPlace> placeSuggestions,
  }) = _PlaceSelected;
  const factory CheckinState.editingCheckIn({required CheckInDraft draft}) =
      _EditingCheckIn;
  const factory CheckinState.editingStamp({required StampDraft draft}) =
      _EditingStamp;
  const factory CheckinState.saving() = _Saving;
  const factory CheckinState.completeCheckIn(CheckIn checkIn) = _CompleteCheckIn;
  const factory CheckinState.completeStamp(String stampId) = _CompleteStamp;
  const factory CheckinState.error(String message) = _Error;
}

@riverpod
class CheckinNotifier extends _$CheckinNotifier {
  CheckinMode _mode = CheckinMode.checkIn;

  @override
  CheckinState build() => const CheckinState.idle();

  Future<void> startCheckin({
    double? lat,
    double? lng,
    CheckinMode mode = CheckinMode.checkIn,
  }) async {
    _mode = mode;
    state = const CheckinState.locating();
    try {
      double resolvedLat = lat ?? 0;
      double resolvedLng = lng ?? 0;

      if (lat == null || lng == null) {
        final position = await GpsService().currentPosition();
        if (position == null) {
          state = const CheckinState.error('Could not get your location');
          return;
        }
        resolvedLat = position.latitude;
        resolvedLng = position.longitude;
      }

      await selectPlace(resolvedLat, resolvedLng);
    } catch (e) {
      state = CheckinState.error(e.toString());
    }
  }

  Future<void> selectPlace(double lat, double lng) async {
    final repo = ref.read(stampRepositoryProvider);
    final (nearbyResult, places) = await (
      repo.nearbyStamps(lat, lng),
      _fetchSuggestions(lat, lng),
    ).wait;
    final nearby = nearbyResult.getOrElse((_) => []);

    state = CheckinState.placeSelected(
      lat: lat,
      lng: lng,
      nearbyStamps: nearby,
      suggestedPlace: places.isNotEmpty ? places.first : null,
      placeSuggestions: places,
    );
  }

  Future<List<ExternalPlace>> _fetchSuggestions(
    double lat,
    double lng, {
    String? query,
  }) async {
    try {
      final service = ref.read(placeServiceForProvider(lat, lng));
      final results = query != null && query.trim().isNotEmpty
          ? await service.search(query.trim(), lat, lng)
          : await service.nearby(lat, lng);
      return results.map(ExternalPlace.fromResult).toList();
    } catch (e, st) {
      debugPrint('[PlaceService] error: $e\n$st');
      return [];
    }
  }

  Future<List<ExternalPlace>> searchPlaces(
    double lat,
    double lng,
    String query,
  ) =>
      _fetchSuggestions(lat, lng, query: query);

  void beginEditing(ExternalPlace? place) {
    final current = state;
    if (current is! _PlaceSelected) return;
    final name = place?.name ?? 'My Location';
    final lat = place?.lat ?? current.lat;
    final lng = place?.lng ?? current.lng;
    if (_mode == CheckinMode.stamp) {
      state = CheckinState.editingStamp(
        draft: StampDraft(
          placeName: name,
          lat: lat,
          lng: lng,
          externalPlaceId: place?.externalPlaceId,
          externalSource: place?.externalSource,
        ),
      );
    } else {
      state = CheckinState.editingCheckIn(
        draft: CheckInDraft(
          placeName: name,
          lat: lat,
          lng: lng,
          externalPlaceId: place?.externalPlaceId,
          externalSource: place?.externalSource,
        ),
      );
    }
  }

  void updateCheckInDraft(CheckInDraft draft) {
    if (state is _EditingCheckIn) {
      state = CheckinState.editingCheckIn(draft: draft);
    }
  }

  void updateStampDraft(StampDraft draft) {
    if (state is _EditingStamp) {
      state = CheckinState.editingStamp(draft: draft);
    }
  }

  Future<void> save() async {
    final current = state;
    final photoService = PhotoService();

    if (current is _EditingCheckIn) {
      state = const CheckinState.saving();
      final urls = await _uploadAll(photoService, current.draft.photoPaths);
      final res = await ref
          .read(checkInRepositoryProvider)
          .createCheckIn(current.draft, photoUrls: urls);
      res.fold(
        (err) => state = CheckinState.error(err.toString()),
        (ci) => state = CheckinState.completeCheckIn(ci),
      );
      return;
    }

    if (current is _EditingStamp) {
      state = const CheckinState.saving();
      final d = current.draft;
      final urls = await _uploadAll(photoService, d.selectedPhotoPaths);
      final ciRepo = ref.read(checkInRepositoryProvider);
      // stamp ⊂ check-in: create the underlying check-in first, then promote.
      final ciRes = await ciRepo.createCheckIn(
        CheckInDraft(
          placeName: d.placeName,
          lat: d.lat,
          lng: d.lng,
          externalPlaceId: d.externalPlaceId,
          externalSource: d.externalSource,
          taggedUserIds: d.taggedUserIds,
        ),
        photoUrls: urls,
      );
      await ciRes.fold(
        (err) async => state = CheckinState.error(err.toString()),
        (ci) async {
          final promo = await ciRepo.promoteToStamp(
            ci.id,
            visibility: d.visibility,
            caption: d.caption,
            sensoryTags: d.sensoryTags,
            taggedUserIds: d.taggedUserIds,
          );
          promo.fold(
            (err) => state = CheckinState.error(err.toString()),
            (stampId) => state = CheckinState.completeStamp(stampId),
          );
        },
      );
    }
  }

  Future<List<String>> _uploadAll(PhotoService service, List<String> paths) async {
    final urls = <String>[];
    for (final p in paths) {
      final url = await service.uploadFile(File(p));
      if (url != null) urls.add(url);
    }
    return urls;
  }

  void reset() => state = const CheckinState.idle();
}
