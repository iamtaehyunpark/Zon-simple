import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../app.dart';
import '../../../data/models/stamp.dart';
import '../../../data/models/check_in.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/raw_location_event.dart';
import '../../../data/repositories/stamp_repository.dart';
import '../../../data/repositories/check_in_repository.dart';
import '../../../data/repositories/location_repository.dart';
import '../../../core/location/providers/gps_provider.dart';
import '../../../core/auth/auth_provider.dart';
import 'map_drawing.dart';

const _kCheckinBlue = 0xFF2196F3;
const _kFollowedOrange = 0xFFFF9800;

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  MapboxMap? _map;
  List<Stamp> _myStamps = [];
  List<CheckIn> _myCheckIns = [];
  List<RawLocationEvent> _route = [];
  List<Stamp> _followedStamps = [];
  List<CheckIn> _sharedCheckIns = [];
  final List<List<double>> _livePath = [];
  bool _loading = false;

  DateTime get _today {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
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
    final day = _today;
    final stampRepo = ref.read(stampRepositoryProvider);
    final checkInRepo = ref.read(checkInRepositoryProvider);
    final locationRepo = ref.read(locationRepositoryProvider);

    final (myStamps, myCheckIns, route, followedStamps, sharedCheckIns) = await (
      stampRepo.getMyStampsForDay(day),
      checkInRepo.getForDay(day),
      locationRepo.getRouteForDay(day),
      stampRepo.getFollowingStampsForDay(day),
      checkInRepo.getSharedCheckInsForDay(day),
    ).wait;

    if (!mounted) return;
    setState(() {
      _myStamps = myStamps.getOrElse((_) => []);
      _myCheckIns = myCheckIns.getOrElse((_) => []);
      _route = route.getOrElse((_) => []);
      _followedStamps = followedStamps.getOrElse((_) => []);
      _sharedCheckIns = sharedCheckIns.getOrElse((_) => []);
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

    await drawRouteLine(map, _route, kBrandGreen.toARGB32());
    await drawPins(
      map,
      sourceId: 'my-stamps-source',
      layerId: 'my-stamps-layer',
      pins: [
        for (final s in _myStamps)
          MapPin(id: s.id, kind: 'stamp', name: s.placeName, lat: s.lat, lng: s.lng),
      ],
      color: kBrandGreen.toARGB32(),
    );
    await drawPins(
      map,
      sourceId: 'my-checkins-source',
      layerId: 'my-checkins-layer',
      pins: [
        for (final c in _myCheckIns)
          MapPin(id: c.id, kind: 'checkin', name: c.placeName, lat: c.lat, lng: c.lng),
      ],
      color: _kCheckinBlue,
    );
    await drawPins(
      map,
      sourceId: 'followed-source',
      layerId: 'followed-layer',
      pins: [
        for (final s in _followedStamps)
          MapPin(id: s.id, kind: 'stamp', name: s.placeName, lat: s.lat, lng: s.lng),
        for (final c in _sharedCheckIns)
          MapPin(id: c.id, kind: 'checkin', name: c.placeName, lat: c.lat, lng: c.lng),
      ],
      color: _kFollowedOrange,
    );
  }

  /// Live route line for the current foreground session.
  Future<void> _drawLive() async {
    final map = _map;
    if (map == null || _livePath.length < 2) return;
    await drawLine(map, _livePath, kBrandGreen.toARGB32(),
        idPrefix: 'live-route');
  }

  Future<void> _onMapTap(MapContentGestureContext context) async {
    final map = _map;
    if (map == null) return;
    try {
      final features = await map.queryRenderedFeatures(
        RenderedQueryGeometry.fromScreenCoordinate(context.touchPosition),
        RenderedQueryOptions(
          layerIds: const [
            'my-stamps-layer',
            'my-checkins-layer',
            'followed-layer',
          ],
          filter: null,
        ),
      );
      for (final f in features) {
        final feature = f?.queriedFeature.feature;
        final props = feature?['properties'];
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
    if (kind == 'stamp') {
      final stamp = _find(_myStamps, (s) => s.id == id) ??
          _find(_followedStamps, (s) => s.id == id);
      if (stamp == null) return;
      showModalBottomSheet<void>(
        context: context,
        builder: (ctx) => _StampSheet(stamp: stamp),
      );
      return;
    }
    final checkIn = _find(_myCheckIns, (c) => c.id == id) ??
        _find(_sharedCheckIns, (c) => c.id == id);
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

  Future<void> _promote(BuildContext sheetCtx, CheckIn checkIn) async {
    Navigator.pop(sheetCtx);
    final res = await ref
        .read(checkInRepositoryProvider)
        .promoteToStamp(checkIn.id, visibility: StampVisibility.public);
    res.fold(
      (err) => ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(err.message))),
      (stampId) {
        if (mounted) context.push('/stamp/$stampId');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(gpsNotifierProvider, (previous, next) {
      final pos = next.valueOrNull;
      if (pos == null) return;
      // Center the camera on the first fix.
      if (previous?.valueOrNull == null) {
        _map?.flyTo(
          CameraOptions(
            center: Point(coordinates: Position(pos.longitude, pos.latitude)),
            zoom: 14.0,
          ),
          MapAnimationOptions(duration: 800),
        );
      }
      // Grow the live route as the user moves.
      _livePath.add([pos.longitude, pos.latitude]);
      _drawLive();
    });

    final pos = ref.watch(gpsNotifierProvider).valueOrNull;
    final count = _myStamps.length + _myCheckIns.length;

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
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            child: Card(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    const Icon(Icons.today, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Today · $count place${count == 1 ? '' : 's'}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    if (_loading)
                      const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2)),
                  ],
                ),
              ),
            ),
          ),
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
                    _LegendRow(color: Color(_kCheckinBlue), label: 'Check-ins'),
                    SizedBox(height: 4),
                    _LegendRow(
                        color: Color(_kFollowedOrange), label: 'Following'),
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
                center: Point(coordinates: Position(p.longitude, p.latitude)),
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
            Text(stamp.placeName,
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(DateFormat('EEE, MMM d').format(stamp.visitedAt),
                style: const TextStyle(color: Colors.grey)),
            if (stamp.caption != null && stamp.caption!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(stamp.caption!, maxLines: 3, overflow: TextOverflow.ellipsis),
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
                const Icon(Icons.pin_drop, color: Color(_kCheckinBlue)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(checkIn.placeName,
                      style: Theme.of(context).textTheme.titleLarge),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(DateFormat('EEE, MMM d · h:mm a').format(checkIn.visitedAt),
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
