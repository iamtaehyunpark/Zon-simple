import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import '../gps_service.dart';
import '../location_batcher.dart';
import '../../places/place_service_provider.dart';
import '../../../data/models/check_in.dart';
import '../../../data/models/raw_location_event.dart';
import '../../../data/models/enums.dart';
import '../../../data/repositories/check_in_repository.dart';

part 'gps_provider.g.dart';

@riverpod
GpsService gpsService(GpsServiceRef ref) => GpsService();

/// App-wide foreground location tracker (keepAlive): one subscription records
/// the route while the app is open, and when the session ends drops a passive
/// "auto" check-in at the last known position.
@Riverpod(keepAlive: true)
class GpsNotifier extends _$GpsNotifier {
  StreamSubscription<Position>? _sub;

  /// In-memory path (lng,lat) of this foreground session — the live map line.
  final List<List<double>> sessionPath = [];

  double? _lastLat;
  double? _lastLng;
  static const _uuid = Uuid();

  // Monotonically-increasing session counter. Incremented each time a new
  // subscription is opened. _anchorPath captures it at stop-time and aborts
  // if it has changed by the time the DB write would happen — prevents phantom
  // anchors when the app resumes before _anchorPath finishes.
  int _sessionId = 0;

  // Skip a new auto anchor only if today already has a check-in this close.
  static const double _kMinAnchorGapM = 80;

  @override
  AsyncValue<Position?> build() {
    ref.onDispose(() {
      _sub?.cancel();
      _sub = null;
    });
    return const AsyncValue.data(null);
  }

  Future<void> startTracking() async {
    if (_sub != null) return; // already tracking
    final service = ref.read(gpsServiceProvider);
    final hasPermission = await service.requestPermission();
    if (!hasPermission) {
      state = AsyncError('Location permission denied', StackTrace.current);
      return;
    }
    if (_sub != null) return; // guard re-entrancy across the await

    // Increment session ID here — any _anchorPath from a previous stopTracking
    // call that is still in-flight will now see a stale ID and abort.
    _sessionId++;

    sessionPath.clear();
    final batcher = ref.read(locationBatcherProvider);
    _sub = service.startTracking().listen(
      (position) {
        state = AsyncValue.data(position);
        _lastLat = position.latitude;
        _lastLng = position.longitude;
        sessionPath.add([position.longitude, position.latitude]);
        batcher.add(RawLocationEvent(
          id: _uuid.v4(),
          userId: '',
          lat: position.latitude,
          lng: position.longitude,
          accuracyM: position.accuracy,
          source: LocationSource.gps,
          capturedAt: DateTime.now(),
        ));
      },
      onError: (e) => state = AsyncError(e, StackTrace.current),
    );
  }

  Future<void> stopTracking() async {
    final sub = _sub;
    if (sub == null) return;
    _sub = null;
    // Capture the session ID at stop-time. If startTracking() is called before
    // _anchorPath completes (rapid foreground/background), the ID will have
    // incremented and _anchorPath will abort without writing.
    final sessionAtStop = _sessionId;
    await sub.cancel();
    await _anchorPath(sessionAtStop);
  }

  Future<void> _anchorPath(int sessionAtStop) async {
    final lat = _lastLat, lng = _lastLng;
    if (lat == null || lng == null) return;

    final repo = ref.read(checkInRepositoryProvider);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final res = await repo.getForDay(today);
    final todays = res.fold((_) => const <CheckIn>[], (l) => l);

    // If a new session started while we were awaiting, abort — we'd be
    // anchoring in the middle of a live session, not at its end.
    if (_sessionId != sessionAtStop) return;

    final nearbyToday = todays.any((c) =>
        Geolocator.distanceBetween(c.lat, c.lng, lat, lng) < _kMinAnchorGapM);
    if (nearbyToday) return;

    var name = 'On the move';
    try {
      final svc = ref.read(placeServiceForProvider(lat, lng));
      final results = await svc.nearby(lat, lng);
      if (results.isNotEmpty) name = results.first.name;
    } catch (_) {/* keep fallback */}

    // Final session check after the place lookup (also async).
    if (_sessionId != sessionAtStop) return;

    final result = await repo.createCheckIn(
      CheckInDraft(
        placeName: name,
        lat: lat,
        lng: lng,
        source: CheckInSource.auto,
      ),
    );
    result.fold(
      (e) => debugPrint('[auto check-in] failed: $e'),
      (_) {},
    );
  }
}
