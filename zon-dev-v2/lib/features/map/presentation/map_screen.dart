import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../app.dart';
import '../../../data/models/stamp.dart';
import '../../../data/models/check_in.dart';
import '../../../data/repositories/stamp_repository.dart';
import '../../../data/repositories/check_in_repository.dart';
import '../../../core/location/providers/gps_provider.dart';
import '../../../core/auth/auth_provider.dart';
import 'map_drawing.dart';

const _kCheckinBlue = 0xFF2196F3;
const _kFollowedOrange = 0xFFFF9800;
const _kFollowedCheckinPink = 0xFFE91E63;

enum MapFilter { today, week, month, year, all, custom }

extension _MapFilterExt on MapFilter {
  String get label => switch (this) {
        MapFilter.today => 'Today',
        MapFilter.week => 'Week',
        MapFilter.month => 'Month',
        MapFilter.year => 'Year',
        MapFilter.all => 'All time',
        MapFilter.custom => 'Custom',
      };
}

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  MapboxMap? _map;

  // Own data — always "today"
  List<Stamp> _myStamps = [];
  List<CheckIn> _myCheckIns = [];

  // Following data
  List<Stamp> _followedStamps = [];
  List<CheckIn> _followedCheckIns = []; // public, last 24h always

  MapFilter _filter = MapFilter.today;
  DateTimeRange? _customRange;
  bool _loading = false;

  DateTime get _today {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  /// [from, to) for the following-stamps query based on the selected filter.
  (DateTime, DateTime) _filterRange() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return switch (_filter) {
      MapFilter.today => (today, now),
      MapFilter.week => (now.subtract(const Duration(days: 7)), now),
      MapFilter.month =>
        (DateTime(now.year, now.month - 1, now.day), now),
      MapFilter.year =>
        (DateTime(now.year - 1, now.month, now.day), now),
      MapFilter.all => (DateTime(2020), now),
      MapFilter.custom => (
          _customRange?.start ?? today,
          (_customRange?.end ?? now).add(const Duration(days: 1)),
        ),
    };
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _load();
      ref.read(gpsNotifierProvider.notifier).startTracking();
    });
  }

  Future<void> _load() async {
    if (ref.read(currentUserProvider) == null) return;
    setState(() => _loading = true);
    final stampRepo = ref.read(stampRepositoryProvider);
    final checkInRepo = ref.read(checkInRepositoryProvider);
    final (from, to) = _filterRange();

    final (myStamps, myCheckIns, followedStamps, followedCheckIns) = await (
      stampRepo.getMyStampsForDay(_today),
      checkInRepo.getForDay(_today),
      stampRepo.getFollowingStamps(from: from, to: to),
      checkInRepo.getFollowingPublicCheckIns(),
    ).wait;

    if (!mounted) return;
    setState(() {
      _myStamps = myStamps.getOrElse((_) => []);
      _myCheckIns = myCheckIns.getOrElse((_) => []);
      _followedStamps = followedStamps.getOrElse((_) => []);
      _followedCheckIns = followedCheckIns.getOrElse((_) => []);
      _loading = false;
    });
    _updateLayers();
  }

  Future<void> _updateLayers() async {
    final map = _map;
    if (map == null) return;
    try {
      await map.location.updateSettings(LocationComponentSettings(
        enabled: true,
        pulsingEnabled: true,
        showAccuracyRing: true,
      ));
    } catch (e) {
      debugPrint('puck: $e');
    }

    await drawPins(
      map,
      sourceId: 'my-stamps-source',
      layerId: 'my-stamps-layer',
      pins: [
        for (final s in _myStamps)
          MapPin(
              id: s.id,
              kind: 'stamp',
              name: s.placeName,
              lat: s.lat,
              lng: s.lng),
      ],
      color: kBrandGreen.toARGB32(),
    );
    await drawPins(
      map,
      sourceId: 'my-checkins-source',
      layerId: 'my-checkins-layer',
      pins: [
        for (final c in _myCheckIns)
          if (c.source != CheckInSource.auto)
            MapPin(
                id: c.id,
                kind: 'checkin',
                name: c.placeName,
                lat: c.lat,
                lng: c.lng),
      ],
      color: _kCheckinBlue,
    );
    await drawPins(
      map,
      sourceId: 'my-auto-source',
      layerId: 'my-auto-layer',
      pins: [
        for (final c in _myCheckIns)
          if (c.source == CheckInSource.auto)
            MapPin(
                id: c.id,
                kind: 'checkin',
                name: c.placeName,
                lat: c.lat,
                lng: c.lng),
      ],
      color: 0xFF9E9E9E,
      circleRadius: 2.5,
      strokeWidth: 0.0,
      opacity: 0.55,
    );

    // Following stamps — filtered by selected time range
    await drawPins(
      map,
      sourceId: 'followed-stamps-source',
      layerId: 'followed-stamps-layer',
      pins: [
        for (final s in _followedStamps)
          MapPin(
              id: s.id,
              kind: 'fstamp',
              name: s.placeName,
              lat: s.lat,
              lng: s.lng),
      ],
      color: _kFollowedOrange,
    );

    // Following public check-ins — always last 24h (story layer)
    await drawPins(
      map,
      sourceId: 'followed-checkins-source',
      layerId: 'followed-checkins-layer',
      pins: [
        for (final c in _followedCheckIns)
          MapPin(
              id: c.id,
              kind: 'fcheckin',
              name: c.placeName,
              lat: c.lat,
              lng: c.lng),
      ],
      color: _kFollowedCheckinPink,
      circleRadius: 6.0,
      strokeWidth: 1.5,
      opacity: 0.85,
    );

    await _drawLive();
  }

  Future<void> _drawLive() async {
    final map = _map;
    if (map == null) return;
    final path = ref.read(gpsNotifierProvider.notifier).sessionPath;
    if (path.length < 2) {
      await removeLine(map, idPrefix: 'live-route');
      return;
    }
    await upsertLine(map, path, kBrandGreen.toARGB32(), idPrefix: 'live-route');
  }

  Future<void> _onMapTap(MapContentGestureContext ctx) async {
    final map = _map;
    if (map == null) return;
    try {
      final features = await map.queryRenderedFeatures(
        RenderedQueryGeometry.fromScreenCoordinate(ctx.touchPosition),
        RenderedQueryOptions(
          layerIds: const [
            'my-stamps-layer',
            'my-checkins-layer',
            'my-auto-layer',
            'followed-stamps-layer',
            'followed-checkins-layer',
          ],
          filter: null,
        ),
      );
      for (final f in features) {
        final props = f?.queriedFeature.feature['properties'];
        if (props is Map) {
          final id = props['id'] as String?;
          final kind = props['kind'] as String?;
          if (id != null && kind != null) {
            _showSheet(kind, id);
            return;
          }
        }
      }
    } catch (e) {
      debugPrint('queryRenderedFeatures: $e');
    }
  }

  static T? _find<T>(List<T> list, bool Function(T) test) {
    for (final e in list) {
      if (test(e)) return e;
    }
    return null;
  }

  void _showSheet(String kind, String id) {
    if (kind == 'stamp' || kind == 'fstamp') {
      final stamp = _find(_myStamps, (s) => s.id == id) ??
          _find(_followedStamps, (s) => s.id == id);
      if (stamp == null) return;
      showModalBottomSheet<void>(
        context: context,
        builder: (ctx) => _StampSheet(stamp: stamp),
      );
      return;
    }
    if (kind == 'checkin' || kind == 'fcheckin') {
      final checkIn = _find(_myCheckIns, (c) => c.id == id) ??
          _find(_followedCheckIns, (c) => c.id == id);
      if (checkIn == null) return;
      final isMine = _find(_myCheckIns, (c) => c.id == id) != null;
      showModalBottomSheet<void>(
        context: context,
        builder: (ctx) => _CheckInSheet(
          checkIn: checkIn,
          isMine: isMine,
          onPromote: isMine ? () => _promote(ctx, checkIn) : null,
        ),
      );
    }
  }

  void _promote(BuildContext sheetCtx, CheckIn checkIn) {
    Navigator.pop(sheetCtx);
    context.push('/checkin?fromCheckIn=${checkIn.id}');
  }

  Future<void> _onFilterTap(MapFilter f) async {
    if (f == MapFilter.custom) {
      final range = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2020),
        lastDate: DateTime.now(),
        initialDateRange: _customRange,
      );
      if (range == null) return;
      setState(() {
        _filter = MapFilter.custom;
        _customRange = range;
      });
    } else {
      setState(() => _filter = f);
    }
    _load();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(gpsNotifierProvider, (previous, next) {
      final pos = next.valueOrNull;
      if (pos == null) return;
      if (previous?.valueOrNull == null) {
        _map?.flyTo(
          CameraOptions(
            center: Point(coordinates: Position(pos.longitude, pos.latitude)),
            zoom: 14.0,
          ),
          MapAnimationOptions(duration: 800),
        );
      }
      _drawLive();
    });

    final pos = ref.watch(gpsNotifierProvider).valueOrNull;
    final myCount = _myStamps.length +
        _myCheckIns.where((c) => c.source != CheckInSource.auto).length;

    return Scaffold(
      body: Stack(
        children: [
          MapWidget(
            key: const ValueKey('mapbox-map'),
            viewport: CameraViewportState(
              center: Point(
                coordinates: Position(
                  pos?.longitude ?? 126.9780,
                  pos?.latitude ?? 37.5665,
                ),
              ),
              zoom: 13.0,
            ),
            onMapCreated: (controller) {
              _map = controller;
              controller.addInteraction(TapInteraction.onMap(_onMapTap));
              _updateLayers();
            },
          ),
          // Top info card
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            child: Card(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.today, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Mine: $myCount today',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 12),
                        if (_followedStamps.isNotEmpty ||
                            _followedCheckIns.isNotEmpty)
                          Text(
                            '· Following: ${_followedStamps.length} stamps'
                            '${_followedCheckIns.isNotEmpty ? ', ${_followedCheckIns.length} stories' : ''}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        const Spacer(),
                        if (_loading)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child:
                                CircularProgressIndicator(strokeWidth: 2),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Filter chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final f in MapFilter.values)
                            Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: FilterChip(
                                label: Text(f.label,
                                    style: const TextStyle(fontSize: 12)),
                                selected: _filter == f,
                                onSelected: (_) => _onFilterTap(f),
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Legend
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 16,
            left: 16,
            child: const Card(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _LegendRow(color: kBrandGreen, label: 'My stamps'),
                    SizedBox(height: 4),
                    _LegendRow(
                        color: Color(_kCheckinBlue), label: 'My check-ins'),
                    SizedBox(height: 4),
                    _LegendRow(
                        color: Color(_kFollowedOrange),
                        label: 'Following stamps'),
                    SizedBox(height: 4),
                    _LegendRow(
                        color: Color(_kFollowedCheckinPink),
                        label: 'Stories (24h)'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.small(
        heroTag: 'locate-me',
        tooltip: 'My location',
        onPressed: () {
          final p = ref.read(gpsNotifierProvider).valueOrNull;
          if (p != null) {
            _map?.flyTo(
              CameraOptions(
                center:
                    Point(coordinates: Position(p.longitude, p.latitude)),
                zoom: 15.0,
              ),
              MapAnimationOptions(duration: 500),
            );
          }
        },
        child: const Icon(Icons.my_location),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

class _StampSheet extends StatelessWidget {
  final Stamp stamp;
  const _StampSheet({required this.stamp});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (stamp.username != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('@${stamp.username}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              ),
            Text(stamp.placeName,
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(DateFormat('EEE, MMM d').format(stamp.visitedAt),
                style: const TextStyle(color: Colors.grey)),
            if (stamp.caption != null && stamp.caption!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(stamp.caption!,
                  maxLines: 3, overflow: TextOverflow.ellipsis),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.push('/stamp/${stamp.id}');
                },
                child: const Text('View stamp'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendRow({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}

class _CheckInSheet extends StatelessWidget {
  final CheckIn checkIn;
  final bool isMine;
  final VoidCallback? onPromote;
  const _CheckInSheet({
    required this.checkIn,
    required this.isMine,
    this.onPromote,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.pin_drop,
                  color: Color(
                      isMine ? _kCheckinBlue : _kFollowedCheckinPink),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(checkIn.placeName,
                      style: Theme.of(context).textTheme.titleLarge),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
                DateFormat('EEE, MMM d · h:mm a').format(checkIn.visitedAt),
                style: const TextStyle(color: Colors.grey)),
            if (checkIn.note != null && checkIn.note!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(checkIn.note!),
            ],
            if (onPromote != null) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onPromote,
                  child: const Text('Make a stamp'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
