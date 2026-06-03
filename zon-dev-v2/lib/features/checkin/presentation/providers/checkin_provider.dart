import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../data/models/stamp.dart';
import '../../../../data/repositories/stamp_repository.dart';
import '../../../../core/location/gps_service.dart';
import '../../../../core/places/place_models.dart';
import '../../../../core/places/place_service_provider.dart';

part 'checkin_provider.freezed.dart';
part 'checkin_provider.g.dart';

// ExternalPlace wraps a PlaceResult for the UI layer.
// Keeps PlaceResult (provider-agnostic) internal and
// exposes only what the UI/stamp model needs.
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
  const factory CheckinState.editing({
    required StampDraft draft,
    required List<Stamp> nearbyStamps,
  }) = _Editing;
  const factory CheckinState.saving() = _Saving;
  const factory CheckinState.complete(Stamp stamp) = _Complete;
  const factory CheckinState.error(String message) = _Error;
}

@riverpod
class CheckinNotifier extends _$CheckinNotifier {
  @override
  CheckinState build() => const CheckinState.idle();

  Future<void> startCheckin({double? lat, double? lng}) async {
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
      debugPrint('[PlaceService] using ${service.runtimeType} at ($lat,$lng) query="${query ?? 'nearby'}"');
      final results = query != null && query.trim().isNotEmpty
          ? await service.search(query.trim(), lat, lng)
          : await service.nearby(lat, lng);
      debugPrint('[PlaceService] got ${results.length} results');
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
    final draft = StampDraft(
      placeName: place?.name ?? 'My Location',
      lat: place?.lat ?? current.lat,
      lng: place?.lng ?? current.lng,
      externalPlaceId: place?.externalPlaceId,
      externalSource: place?.externalSource,
    );
    state = CheckinState.editing(
      draft: draft,
      nearbyStamps: current.nearbyStamps,
    );
  }

  void updateDraft(StampDraft draft) {
    final current = state;
    if (current is! _Editing) return;
    state = CheckinState.editing(draft: draft, nearbyStamps: current.nearbyStamps);
  }

  Future<void> saveStamp() async {
    final current = state;
    if (current is! _Editing) return;
    state = const CheckinState.saving();
    try {
      final result =
          await ref.read(stampRepositoryProvider).createStamp(current.draft);
      result.fold(
        (err) => state = CheckinState.error(err.toString()),
        (stamp) => state = CheckinState.complete(stamp),
      );
    } catch (e) {
      state = CheckinState.error(e.toString());
    }
  }

  void reset() => state = const CheckinState.idle();
}
