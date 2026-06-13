import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'shared_voice_service.dart';
import '../../features/photo_import/presentation/photo_checkin_inspection_screen.dart';

/// Receives photos shared to ZON from the iOS Photos app via the Share Extension.
///
/// The Share Extension saves image files + EXIF metadata to the App Group
/// container. AppDelegate reads them and pushes `sharedPhotos` / buffers for
/// `getPending` on the `app.getzon.zon/sharing` MethodChannel. That channel is
/// owned by [SharedVoiceService] — this handler subscribes to its [photoStream]
/// rather than setting up a competing handler on the same channel.
class SharedPhotosHandler {
  static final _controller = StreamController<List<InspectionGroup>>.broadcast();

  /// Stream that fires each time a batch of shared photos is ready to review.
  static Stream<List<InspectionGroup>> get stream => _controller.stream;

  static bool _initialized = false;

  /// Call once from [ZonApp.initState] after [SharedVoiceService] is set up.
  static void init(PlaceServiceFactory placeServiceFactory) {
    if (_initialized) return;
    _initialized = true;

    // Subscribe to the shared channel's photo stream.
    SharedVoiceService.instance.photoStream.listen(
      (raw) => _process(raw, placeServiceFactory),
    );

    // Cold-start poll — photos shared while the app was closed.
    SharedVoiceService.instance.getPendingPhotos().then(
      (raw) {
        if (raw.isNotEmpty) _process(raw, placeServiceFactory);
      },
      onError: (Object e) => debugPrint('[SharedPhotos] getPending error: $e'),
    );
  }

  static Future<void> _process(
      List<Map<dynamic, dynamic>> items, PlaceServiceFactory factory) async {
    if (items.isEmpty) return;

    Position? fallback;
    try {
      fallback = await Geolocator.getLastKnownPosition();
    } catch (_) {}

    final groups = <InspectionGroup>[];

    for (final item in items) {
      final path = item['path'] as String?;
      if (path == null) continue;
      final file = File(path);
      if (!file.existsSync()) continue;

      final rawLat = (item['lat'] as num?)?.toDouble() ?? 0.0;
      final rawLng = (item['lng'] as num?)?.toDouble() ?? 0.0;
      final hasGps = rawLat != 0.0 || rawLng != 0.0;

      final lat = hasGps ? rawLat : (fallback?.latitude ?? 0.0);
      final lng = hasGps ? rawLng : (fallback?.longitude ?? 0.0);

      final ts = item['timestamp'] as String?;
      final takenAt =
          ts != null ? DateTime.tryParse(ts) ?? DateTime.now() : DateTime.now();

      String placeName = 'Photo location';
      if (lat != 0.0 || lng != 0.0) {
        try {
          final svc = factory(lat, lng);
          final results = await svc.nearby(lat, lng);
          if (results.isNotEmpty) placeName = results.first.name;
        } catch (e) {
          debugPrint('[SharedPhotos] place resolve error: $e');
        }
      }

      groups.add(InspectionGroup(
        files: [file],
        lat: lat,
        lng: lng,
        takenAt: takenAt,
        placeName: placeName,
      ));
    }

    if (groups.isNotEmpty) _controller.add(groups);
  }
}

/// Convenience typedef so the factory can be passed around without carrying the
/// full Riverpod ref.
typedef PlaceServiceFactory = dynamic Function(double lat, double lng);
