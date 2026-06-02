import 'dart:async';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/raw_location_event.dart';
import '../../data/models/enums.dart';
import '../../data/repositories/location_repository.dart';

part 'location_batcher.g.dart';

@riverpod
LocationBatcher locationBatcher(LocationBatcherRef ref) {
  final repo = ref.watch(locationRepositoryProvider);
  final batcher = LocationBatcher(repo);
  ref.onDispose(batcher.dispose);
  // Initialize async — GPS events won't batch until the box is open,
  // which happens fast enough that no events are lost in practice.
  batcher.initialize();
  return batcher;
}

class LocationBatcher {
  static const _boxName = 'pending_gps_events';
  static const _batchInterval = Duration(minutes: 5);
  static const _maxBatchSize = 100;

  final LocationRepository _repo;
  Timer? _timer;
  Box<dynamic>? _box;

  LocationBatcher(this._repo);

  Future<void> initialize() async {
    _box = await Hive.openBox<dynamic>(_boxName);
    _timer = Timer.periodic(_batchInterval, (_) => flush());
  }

  void add(RawLocationEvent event) {
    _box?.add({
      'id': event.id,
      'lat': event.lat,
      'lng': event.lng,
      'accuracy_m': event.accuracyM,
      'source': event.source.dbValue,
      'captured_at': event.capturedAt.toIso8601String(),
    });
  }

  Future<void> flush() async {
    final box = _box;
    if (box == null || box.isEmpty) return;

    final keys = box.keys.take(_maxBatchSize).toList();
    final events = keys
        .map((k) => box.get(k))
        .whereType<Map>()
        .map(_mapToEvent)
        .toList();

    if (events.isEmpty) return;

    final result = await _repo.batchIngest(events);
    result.fold(
      (_) => null, // keep in box, retry next interval
      (_) => box.deleteAll(keys),
    );
  }

  RawLocationEvent _mapToEvent(Map<dynamic, dynamic> m) {
    return RawLocationEvent(
      id: m['id'] as String? ?? const Uuid().v4(),
      userId: '',
      lat: (m['lat'] as num).toDouble(),
      lng: (m['lng'] as num).toDouble(),
      accuracyM: (m['accuracy_m'] as num?)?.toDouble(),
      source: LocationSource.fromString(m['source'] as String? ?? 'gps'),
      capturedAt: DateTime.parse(m['captured_at'] as String),
    );
  }

  void dispose() {
    _timer?.cancel();
    _box?.close();
  }
}
