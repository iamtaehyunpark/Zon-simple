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
  double? _lastAnchorLat;
  double? _lastAnchorLng;
  static const _uuid = Uuid();

  // A session must cover at least this much ground before it's worth anchoring,
  // and the end point must be at least this far from the previous anchor.
  static const double _kMinSessionMoveM = 50;
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

  /// Drop a passive auto check-in at the end of the tracked path — skipped if
  /// the session barely moved, or it lands within [_kMinAnchorGapM] of the last
  /// anchor (e.g. you opened and closed the app without leaving).
  Future<void> _anchorPath() async {
    final lat = _lastLat, lng = _lastLng;
    if (lat == null || lng == null) return;

    if (sessionPath.length >= 2) {
      final start = sessionPath.first; // [lng, lat]
      final moved =
          Geolocator.distanceBetween(start[1], start[0], lat, lng);
      if (moved < _kMinSessionMoveM) return;
    }
    if (_lastAnchorLat != null && _lastAnchorLng != null) {
      final gap = Geolocator.distanceBetween(
          _lastAnchorLat!, _lastAnchorLng!, lat, lng);
      if (gap < _kMinAnchorGapM) return;
    }
    _lastAnchorLat = lat;
    _lastAnchorLng = lng;

    var name = 'On the move';
    try {
      final svc = ref.read(placeServiceForProvider(lat, lng));
      final results = await svc.nearby(lat, lng);
      if (results.isNotEmpty) name = results.first.name;
    } catch (_) {/* keep fallback */}

    await ref.read(checkInRepositoryProvider).createCheckIn(
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
