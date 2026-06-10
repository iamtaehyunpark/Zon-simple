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
import '../../supabase/supabase_provider.dart';

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

  /// When the current foreground session began. Lets the map count today's
  /// total distance as (prior recorded route) + (this live session) without
  /// double-counting the session's already-flushed breadcrumbs.
  DateTime? sessionStartedAt;

  double? _lastLat;
  double? _lastLng;
  static const _uuid = Uuid();

  // Monotonically-increasing session counter. Incremented each time a new
  // subscription is opened. _anchorPath captures it at stop-time and aborts
  // if it has changed by the time the DB write would happen — prevents phantom
  // anchors when the app resumes before _anchorPath finishes.
  int _sessionId = 0;

  // Skip a new auto anchor only if today already has a check-in this close.
  static const double _kMinAnchorGapM = 50;

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
    sessionStartedAt = DateTime.now();
    bool isFirstPosition = true;

    // Read userId directly from Supabase auth — avoids creating a temporary
    // autoDispose checkInRepositoryProvider that thrashes the Riverpod graph.
    final batchUserId = ref.read(supabaseClientProvider).auth.currentUser?.id;

    // Fetch initial current position to resolve location immediately
    service.currentPosition().then((position) {
      if (position != null && _sub != null) {
        state = AsyncValue.data(position);
        _lastLat = position.latitude;
        _lastLng = position.longitude;
        if (sessionPath.isEmpty) {
          sessionPath.add([position.longitude, position.latitude]);
        }
        if (isFirstPosition) {
          isFirstPosition = false;
          _addAutoCheckIn(position.latitude, position.longitude);
        }
      }
    }).catchError((e) {
      debugPrint('[GpsNotifier] failed to fetch initial position: $e');
    });

    _sub = service.startTracking().listen(
      (position) {
        state = AsyncValue.data(position);
        _lastLat = position.latitude;
        _lastLng = position.longitude;
        if (sessionPath.isEmpty || sessionPath.last[0] != position.longitude || sessionPath.last[1] != position.latitude) {
          sessionPath.add([position.longitude, position.latitude]);
        }
        if (batchUserId != null) {
          ref.read(locationBatcherProvider).add(RawLocationEvent(
            id: _uuid.v4(),
            userId: batchUserId,
            lat: position.latitude,
            lng: position.longitude,
            accuracyM: position.accuracy,
            source: LocationSource.gps,
            capturedAt: DateTime.now(),
          ));
        }

        if (isFirstPosition) {
          isFirstPosition = false;
          _addAutoCheckIn(position.latitude, position.longitude);
        }
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
    // Persist the session's queued GPS breadcrumbs now, so the timeline's trace
    // reflects the full session as soon as it ends — not only after the 5-min
    // batch timer. Events stay queued in Hive if this flush fails.
    await ref.read(locationBatcherProvider).flush();
    await _anchorPath(sessionAtStop);
  }

  Future<void> _anchorPath(int sessionAtStop) async {
    final lat = _lastLat, lng = _lastLng;
    if (lat == null || lng == null) return;

    // If a new session started while we were awaiting, abort — we'd be
    // anchoring in the middle of a live session, not at its end.
    if (_sessionId != sessionAtStop) return;

    await _addAutoCheckIn(lat, lng, sessionAtStop: sessionAtStop);
  }

  Future<void> _addAutoCheckIn(double lat, double lng, {int? sessionAtStop}) async {
    final repo = ref.read(checkInRepositoryProvider);
    final userId = repo.currentUserId;
    if (userId == null) return;

    if (sessionAtStop != null && _sessionId != sessionAtStop) return;

    // Proximity check:
    // If the current location is close enough to the day's last check-in/stamp, it should not be added.
    try {
      final now = DateTime.now();
      final startOfToday = DateTime.utc(now.year, now.month, now.day).toIso8601String();

      // Fetch latest check-in and stamp for today concurrently.
      final (latestCheckIns, latestStamps) = await (
        repo.client
            .from('check_ins')
            .select('lat, lng, visited_at')
            .eq('user_id', userId)
            .not('lat', 'is', null)
            .not('lng', 'is', null)
            .gte('visited_at', startOfToday)
            .order('visited_at', ascending: false)
            .limit(1),
        repo.client
            .from('stamps')
            .select('lat, lng, visited_at')
            .eq('user_id', userId)
            .not('lat', 'is', null)
            .not('lng', 'is', null)
            .gte('visited_at', startOfToday)
            .order('visited_at', ascending: false)
            .limit(1),
      ).wait;

      Map<String, dynamic>? lastNode;

      if (latestCheckIns.isNotEmpty && latestStamps.isNotEmpty) {
        final ci = latestCheckIns.first;
        final st = latestStamps.first;
        final ciTime = DateTime.parse(ci['visited_at'] as String);
        final stTime = DateTime.parse(st['visited_at'] as String);
        lastNode = ciTime.isAfter(stTime) ? ci : st;
      } else if (latestCheckIns.isNotEmpty) {
        lastNode = latestCheckIns.first;
      } else if (latestStamps.isNotEmpty) {
        lastNode = latestStamps.first;
      }

      if (lastNode != null) {
        final nodeLat = (lastNode['lat'] as num).toDouble();
        final nodeLng = (lastNode['lng'] as num).toDouble();
        final dist = Geolocator.distanceBetween(lat, lng, nodeLat, nodeLng);
        if (dist < _kMinAnchorGapM) return;
      }
    } catch (e) {
      debugPrint('[auto check-in] proximity check failed: $e');
    }

    if (sessionAtStop != null && _sessionId != sessionAtStop) return;

    var name = 'On the move';
    try {
      final svc = ref.read(placeServiceForProvider(lat, lng));
      final results = await svc.nearby(lat, lng);
      if (results.isNotEmpty) name = results.first.name;
    } catch (_) {/* keep fallback */}

    if (sessionAtStop != null && _sessionId != sessionAtStop) return;

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
