import 'dart:async';
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
/// "auto" check-in at the end of the tracked path (linking the trace across
/// launches), skipped when it lands too close to the last one.
@Riverpod(keepAlive: true)
class GpsNotifier extends _$GpsNotifier {
  StreamSubscription<Position>? _sub;

  /// In-memory path (lng,lat) of this foreground session — the live map line.
  final List<List<double>> sessionPath = [];

  // Latest fix this session, and the location of the last auto anchor we
  // dropped (kept in memory across sessions so re-opens in place don't spam).
  double? _lastLat;
  double? _lastLng;
  static const _uuid = Uuid();

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
    if (_sub != null) return; // guard against re-entrancy across the await

    // Fresh session: the map shows only the path since this open.
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

  /// Drop a passive auto check-in at the end of the tracked path. Skipped only
  /// if *today* already has a check-in within [_kMinAnchorGapM] — so re-opening
  /// in place mid-day doesn't spam, but a new day always gets a fresh anchor
  /// even when you haven't moved (the dedup window is per-day, DB-backed so it
  /// survives app restarts).
  Future<void> _anchorPath() async {
    final lat = _lastLat, lng = _lastLng;
    if (lat == null || lng == null) return;

    final repo = ref.read(checkInRepositoryProvider);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final res = await repo.getForDay(today);
    final todays = res.fold((_) => const <CheckIn>[], (l) => l);
    final nearbyToday = todays.any((c) =>
        Geolocator.distanceBetween(c.lat, c.lng, lat, lng) < _kMinAnchorGapM);
    if (nearbyToday) return;

    var name = 'On the move';
    try {
      final svc = ref.read(placeServiceForProvider(lat, lng));
      final results = await svc.nearby(lat, lng);
      if (results.isNotEmpty) name = results.first.name;
    } catch (_) {/* keep fallback */}

    await repo.createCheckIn(
      CheckInDraft(
        placeName: name,
        lat: lat,
        lng: lng,
        source: CheckInSource.auto,
      ),
    );
  }

  Future<void> stopTracking() async {
    final sub = _sub;
    if (sub == null) return;
    _sub = null;
    await sub.cancel();
    await _anchorPath();
  }
}
