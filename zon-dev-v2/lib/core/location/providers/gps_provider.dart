import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import '../gps_service.dart';
import '../location_batcher.dart';
import '../../auth/auth_provider.dart';
import '../../../data/models/raw_location_event.dart';
import '../../../data/models/enums.dart';

part 'gps_provider.g.dart';

@riverpod
GpsService gpsService(GpsServiceRef ref) => GpsService();

@riverpod
class GpsNotifier extends _$GpsNotifier {
  StreamSubscription<Position>? _sub;
  static const _uuid = Uuid();

  @override
  AsyncValue<Position?> build() {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const AsyncValue.data(null);
    ref.onDispose(_stop);
    return const AsyncValue.data(null);
  }

  Future<void> startTracking() async {
    final service = ref.read(gpsServiceProvider);
    final hasPermission = await service.requestPermission();
    if (!hasPermission) {
      state = AsyncError('Location permission denied', StackTrace.current);
      return;
    }

    state = const AsyncValue.loading();
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
