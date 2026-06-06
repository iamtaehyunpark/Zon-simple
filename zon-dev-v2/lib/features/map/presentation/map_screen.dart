import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Size;
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../app.dart';
import '../../../data/models/stamp.dart';
import '../../../data/models/check_in.dart';
import '../../../data/models/friend_location.dart';
import '../../../data/repositories/stamp_repository.dart';
import '../../../data/repositories/check_in_repository.dart';
import '../../../data/repositories/location_sharing_repository.dart';
import '../../../core/location/providers/gps_provider.dart';
import '../../../core/auth/auth_provider.dart';
import 'map_drawing.dart';

const _kCheckinBlue = 0xFF2196F3;
const _kFollowedOrange = 0xFFFF9800;
const _kFollowedCheckinPink = 0xFFE91E63;

// Location broadcast thresholds (Snapchat-style: update on open + significant moves)
const _kBroadcastIntervalSec = 30;
const _kBroadcastMinDistM = 50.0;

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

  // Friend live locations (Snap Map layer)
  List<FriendLocation> _friendLocations = [];
  Map<String, Offset> _friendScreenPos = {}; // userId → screen offset
  Timer? _positionTimer;

  // Location broadcasting state
  DateTime? _lastBroadcast;
  geo.Position? _lastBroadcastPos;

  MapFilter _filter = MapFilter.today;
  DateTimeRange? _customRange;
  bool _loading = false;

  DateTime get _today {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  (DateTime, DateTime) _filterRange() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return switch (_filter) {
      MapFilter.today => (today, now),
      MapFilter.week => (now.subtract(const Duration(days: 7)), now),
      MapFilter.month => (DateTime(now.year, now.month - 1, now.day), now),
      MapFilter.year => (DateTime(now.year - 1, now.month, now.day), now),
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

  @override
  void dispose() {
    _positionTimer?.cancel();
    super.dispose();
  }

  // ── Data loading ──────────────────────────────────────────────────────────

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

  // ── Friend avatar overlay ─────────────────────────────────────────────────

  void _onFriendLocationsChanged(List<FriendLocation> locations) {
    if (!mounted) return;
    setState(() => _friendLocations = locations.where((f) => !f.isStale).toList());
    _startPositionTimer();
    _updateFriendScreenPositions();
  }

  void _startPositionTimer() {
    if (_positionTimer?.isActive == true) return;
    _positionTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (!mounted || _friendLocations.isEmpty) return;
      _updateFriendScreenPositions();
    });
  }

  Future<void> _updateFriendScreenPositions() async {
    final map = _map;
    if (map == null || _friendLocations.isEmpty) return;
    final positions = <String, Offset>{};
    for (final fl in _friendLocations) {
      try {
        final sc = await map.pixelForCoordinate(
          Point(coordinates: Position(fl.lng, fl.lat)),
        );
        positions[fl.userId] = Offset(sc.x, sc.y);
      } catch (_) {}
    }
    if (mounted) setState(() => _friendScreenPos = positions);
  }

  // ── Location broadcasting ─────────────────────────────────────────────────

  void _maybeBroadcast(geo.Position pos) {
    final now = DateTime.now();
    final last = _lastBroadcast;
    final lastPos = _lastBroadcastPos;

    bool should = last == null ||
        now.difference(last).inSeconds >= _kBroadcastIntervalSec;

    if (!should && lastPos != null) {
      final dist = geo.Geolocator.distanceBetween(
        lastPos.latitude, lastPos.longitude,
        pos.latitude, pos.longitude,
      );
      if (dist >= _kBroadcastMinDistM) should = true;
    }

    if (!should) return;
    _lastBroadcast = now;
    _lastBroadcastPos = pos;

    ref.read(locationSharingRepositoryProvider).upsertMyLocation(
          pos.latitude, pos.longitude,
          pos.accuracy > 0 ? pos.accuracy : null,
          pos.heading >= 0 ? pos.heading : null,
        );
  }

  // ── Map layers ────────────────────────────────────────────────────────────

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
          if (c.source != CheckInSource.auto)
            MapPin(id: c.id, kind: 'checkin', name: c.placeName, lat: c.lat, lng: c.lng),
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
            MapPin(id: c.id, kind: 'checkin', name: c.placeName, lat: c.lat, lng: c.lng),
      ],
      color: 0xFF9E9E9E,
      circleRadius: 2.5,
      strokeWidth: 0.0,
      opacity: 0.55,
    );
    await drawPins(
      map,
      sourceId: 'followed-stamps-source',
      layerId: 'followed-stamps-layer',
      pins: [
        for (final s in _followedStamps)
          MapPin(id: s.id, kind: 'fstamp', name: s.placeName, lat: s.lat, lng: s.lng),
      ],
      color: _kFollowedOrange,
    );
    await drawPins(
      map,
      sourceId: 'followed-checkins-source',
      layerId: 'followed-checkins-layer',
      pins: [
        for (final c in _followedCheckIns)
          MapPin(id: c.id, kind: 'fcheckin', name: c.placeName, lat: c.lat, lng: c.lng),
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

  // ── Tap handling ──────────────────────────────────────────────────────────

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

  void _showFriendSheet(String userId) {
    final fl = _find(_friendLocations, (f) => f.userId == userId);
    if (fl == null) return;
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => _FriendLocationSheet(
        location: fl,
        onViewProfile: () {
          Navigator.pop(ctx);
          context.push('/profile/$userId');
        },
      ),
    );
  }

  // ── Filter ────────────────────────────────────────────────────────────────

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

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // GPS: draw live route + broadcast position
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
      _maybeBroadcast(pos);
    });

    // Friend locations: subscribe to Realtime stream
    ref.listen(
      friendLocationsProvider,
      (_, next) => next.whenData(_onFriendLocationsChanged),
    );

    // Ghost Mode indicator
    final ghostMode = ref.watch(ghostModeProvider).valueOrNull ?? false;

    final pos = ref.watch(gpsNotifierProvider).valueOrNull;
    final myCount = _myStamps.length +
        _myCheckIns.where((c) => c.source != CheckInSource.auto).length;

    return Scaffold(
      body: Stack(
        children: [
          // ── Mapbox base ─────────────────────────────────────────────
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
              _updateFriendScreenPositions();
            },
          ),

          // ── Friend avatar bubbles ───────────────────────────────────
          for (final entry in _friendScreenPos.entries)
            Builder(builder: (ctx) {
              final fl = _find(_friendLocations, (f) => f.userId == entry.key);
              if (fl == null) return const SizedBox.shrink();
              return Positioned(
                left: entry.value.dx - 28,
                top: entry.value.dy - 80,
                child: _FriendBubble(
                  location: fl,
                  onTap: () => _showFriendSheet(fl.userId),
                ),
              );
            }),

          // ── Top info card ───────────────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                            '· ${_followedStamps.length} stamps'
                            '${_followedCheckIns.isNotEmpty ? ', ${_followedCheckIns.length} stories' : ''}',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        const Spacer(),
                        if (ghostMode)
                          Tooltip(
                            message: 'Ghost Mode on — your location is hidden',
                            child: Icon(Icons.visibility_off,
                                size: 18, color: Colors.grey[500]),
                          ),
                        if (_loading) ...[
                          const SizedBox(width: 8),
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
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

          // ── Legend ──────────────────────────────────────────────────
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 16,
            left: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _LegendRow(color: kBrandGreen, label: 'My stamps'),
                    const SizedBox(height: 4),
                    const _LegendRow(
                        color: Color(_kCheckinBlue), label: 'My check-ins'),
                    const SizedBox(height: 4),
                    const _LegendRow(
                        color: Color(_kFollowedOrange),
                        label: 'Following stamps'),
                    const SizedBox(height: 4),
                    const _LegendRow(
                        color: Color(_kFollowedCheckinPink),
                        label: 'Stories (24h)'),
                    if (_friendLocations.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      _LegendRow(
                        color: Colors.purple[300]!,
                        label: 'Friends live (${_friendLocations.length})',
                        isCircleAvatar: true,
                      ),
                    ],
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

// ── Friend avatar bubble (Snapchat-style) ─────────────────────────────────────

class _FriendBubble extends StatelessWidget {
  final FriendLocation location;
  final VoidCallback onTap;
  const _FriendBubble({required this.location, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Circular avatar with white ring
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2.5),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 2)),
              ],
            ),
            child: CircleAvatar(
              radius: 22,
              backgroundImage: location.avatarUrl != null
                  ? CachedNetworkImageProvider(location.avatarUrl!)
                  : null,
              backgroundColor: Colors.purple[100],
              child: location.avatarUrl == null
                  ? Text(
                      location.username[0].toUpperCase(),
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700),
                    )
                  : null,
            ),
          ),
          // Small downward pointer (speech bubble tip)
          CustomPaint(
            size: const Size(10, 6),
            painter: _BubbleTipPainter(),
          ),
          // Name + time chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 4),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  location.username,
                  style: const TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w700),
                ),
                Text(
                  location.timeLabel,
                  style: TextStyle(fontSize: 9, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BubbleTipPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}

// ── Friend location bottom sheet ──────────────────────────────────────────────

class _FriendLocationSheet extends StatelessWidget {
  final FriendLocation location;
  final VoidCallback onViewProfile;
  const _FriendLocationSheet(
      {required this.location, required this.onViewProfile});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundImage: location.avatarUrl != null
                      ? CachedNetworkImageProvider(location.avatarUrl!)
                      : null,
                  backgroundColor: Colors.purple[100],
                  child: location.avatarUrl == null
                      ? Text(location.username[0].toUpperCase(),
                          style: const TextStyle(fontSize: 20))
                      : null,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('@${location.username}',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.circle, size: 8,
                            color: location.timeLabel == 'Just now'
                                ? Colors.green
                                : Colors.grey[400]),
                        const SizedBox(width: 4),
                        Text(
                          location.timeLabel == 'Just now'
                              ? 'Active now'
                              : location.timeLabel,
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onViewProfile,
                child: const Text('View profile'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Stamp sheet ───────────────────────────────────────────────────────────────

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
            Text(stamp.placeName, style: Theme.of(context).textTheme.titleLarge),
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

// ── Legend row ────────────────────────────────────────────────────────────────

class _LegendRow extends StatelessWidget {
  final Color color;
  final String label;
  final bool isCircleAvatar;
  const _LegendRow(
      {required this.color, required this.label, this.isCircleAvatar = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        isCircleAvatar
            ? CircleAvatar(radius: 5, backgroundColor: color)
            : Container(
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

// ── Check-in sheet ────────────────────────────────────────────────────────────

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
                Icon(Icons.pin_drop,
                    color: Color(isMine ? _kCheckinBlue : _kFollowedCheckinPink)),
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
              Text(checkIn.note!, maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      context.push('/check-in/${checkIn.id}');
                    },
                    child: const Text('View details'),
                  ),
                ),
                if (onPromote != null) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: onPromote,
                      child: const Text('Make a stamp'),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
