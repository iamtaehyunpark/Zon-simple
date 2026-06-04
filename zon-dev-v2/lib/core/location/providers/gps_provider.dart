import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import '../gps_service.dart';
import '../location_batcher.dart';
import '../../../data/models/raw_location_event.dart';
import '../../../data/models/enums.dart';

part 'gps_provider.g.dart';

@riverpod
GpsService gpsService(GpsServiceRef ref) => GpsService();

/// App-wide foreground location tracker. Kept alive so a single subscription
/// records the route the whole time the app is open (started/stopped from the
/// app lifecycle), not just while the map is on screen.
@Riverpod(keepAlive: true)
class GpsNotifier extends _$GpsNotifier {
  StreamSubscription<Position>? _sub;
  static const _uuid = Uuid();

  @override
  AsyncValue<Position?> build() {
    ref.onDispose(_stop);
    return const AsyncValue.data(null);
  }

  bool get isTracking => _sub != null;

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

  void _stop() {
    _sub?.cancel();
    _sub = null;
  }

  void stopTracking() => _stop();
}
