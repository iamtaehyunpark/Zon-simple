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
/// the route while the app is open, and drops a passive "auto" check-in anchor
/// at the start of each session (linking the trace across launches).
@Riverpod(keepAlive: true)
class GpsNotifier extends _$GpsNotifier {
  StreamSubscription<Position>? _sub;

  /// In-memory path (lng,lat) of this foreground session — the live map line.
  final List<List<double>> sessionPath = [];

  bool _sessionAnchored = false;
  DateTime? _lastAnchorAt;
  double? _lastAnchorLat;
  double? _lastAnchorLng;
  static const _uuid = Uuid();

  @override
  AsyncValue<Position?> build() {
    ref.onDispose(_stop);
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

    final batcher = ref.read(locationBatcherProvider);
    _sub = service.startTracking().listen(
      (position) {
        state = AsyncValue.data(position);
        sessionPath.add([position.longitude, position.latitude]);
        if (!_sessionAnchored) {
          _sessionAnchored = true;
          _maybeAnchor(position);
        }
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

  /// Drop a passive auto check-in at session start — skipped if we anchored
  /// recently and haven't really moved (avoids spam on quick re-opens).
  Future<void> _maybeAnchor(Position pos) async {
    final last = _lastAnchorAt;
    if (last != null && _lastAnchorLat != null) {
      final recent =
          DateTime.now().difference(last) < const Duration(minutes: 30);
      final near = Geolocator.distanceBetween(_lastAnchorLat!, _lastAnchorLng!,
              pos.latitude, pos.longitude) <
          100;
      if (recent && near) return;
    }
    _lastAnchorAt = DateTime.now();
    _lastAnchorLat = pos.latitude;
    _lastAnchorLng = pos.longitude;

    var name = 'On the move';
    try {
      final svc =
          ref.read(placeServiceForProvider(pos.latitude, pos.longitude));
      final results = await svc.nearby(pos.latitude, pos.longitude);
      if (results.isNotEmpty) name = results.first.name;
    } catch (_) {/* keep fallback */}

    await ref.read(checkInRepositoryProvider).createCheckIn(
          CheckInDraft(
            placeName: name,
            lat: pos.latitude,
            lng: pos.longitude,
            source: CheckInSource.auto,
          ),
        );
  }

  void _stop() {
    _sub?.cancel();
    _sub = null;
    _sessionAnchored = false;
  }

  void stopTracking() => _stop();
}
