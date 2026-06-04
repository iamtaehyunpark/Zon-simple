import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../../../app.dart';
import '../../../data/models/check_in.dart';
import '../../../data/models/enums.dart';
import '../../../data/repositories/check_in_repository.dart';
import '../../../shared/widgets/app_states.dart';
import '../../map/presentation/map_drawing.dart';
import 'providers/timeline_provider.dart';

const _kCheckinBlue = 0xFF2196F3;

/// One row on the timeline — a check-in or a stamp, time-ordered.
class _TlItem {
  final String id;
  final bool isStamp;
  final String name;
  final double lat;
  final double lng;
  final DateTime time;
  final String? note;
  final int photoCount;
  final bool isPublic;
  const _TlItem({
    required this.id,
    required this.isStamp,
    required this.name,
    required this.lat,
    required this.lng,
    required this.time,
    required this.photoCount,
    required this.isPublic,
    this.note,
  });
}

class TimelineScreen extends ConsumerStatefulWidget {
  const TimelineScreen({super.key});

  @override
  ConsumerState<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends ConsumerState<TimelineScreen> {
  MapboxMap? _map;
  late DateTime _day;
  List<_TlItem> _items = const [];
  DayBundle? _bundle;
  DayBundle? _drawn;

  @override
  void initState() {
    super.initState();
    final n = DateTime.now();
    _day = DateTime(n.year, n.month, n.day);
  }

  bool get _isToday {
    final n = DateTime.now();
    return _day.year == n.year && _day.month == n.month && _day.day == n.day;
  }

  // ── Day navigation ────────────────────────────────────────────
  void _load(DateTime d) {
    setState(() => _day = d);
    ref.read(timelineNotifierProvider.notifier).loadDay(d);
  }

  void _shift(int days) {
    final next = _day.add(Duration(days: days));
    final n = DateTime.now();
    if (next.isAfter(DateTime(n.year, n.month, n.day))) return;
    _load(next);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _day,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      _load(DateTime(picked.year, picked.month, picked.day));
    }
  }

  // ── Data → items + map ────────────────────────────────────────
  List<_TlItem> _buildItems(DayBundle b) {
    final items = <_TlItem>[
      for (final c in b.checkIns)
        _TlItem(
          id: c.id,
          isStamp: false,
          name: c.placeName,
          lat: c.lat,
          lng: c.lng,
          time: c.visitedAt,
          note: c.note,
          photoCount: c.photoCount,
          isPublic: false,
        ),
      for (final s in b.stamps)
        _TlItem(
          id: s.id,
          isStamp: true,
          name: s.placeName,
          lat: s.lat,
          lng: s.lng,
          time: s.visitedAt,
          note: s.caption,
          photoCount: s.photoCount,
          isPublic: s.visibility == StampVisibility.public,
        ),
    ]..sort((a, b) => a.time.compareTo(b.time));
    return items;
  }

  _TlItem? _itemById(String id) {
    for (final i in _items) {
      if (i.id == id) return i;
    }
    return null;
  }

  void _maybeRedraw(DayBundle b) {
    if (identical(b, _drawn)) return;
    _drawn = b;
    _redraw(b);
  }

  Future<void> _redraw(DayBundle b) async {
    final map = _map;
    if (map == null) return;
    final items = _buildItems(b);

    // Path: prefer the actual GPS breadcrumb route; otherwise connect the
    // day's check-ins/stamps in chronological order (Google-Timeline style).
    final coords = b.route.length >= 2
        ? [for (final e in b.route) [e.lng, e.lat]]
        : [for (final i in items) [i.lng, i.lat]];
    await drawLine(map, coords, kBrandGreen.toARGB32(), idPrefix: 'tl-path');

    await drawPins(
      map,
      sourceId: 'tl-checkins-source',
      layerId: 'tl-checkins-layer',
      pins: [
        for (final i in items.where((i) => !i.isStamp))
          MapPin(id: i.id, kind: 'checkin', name: i.name, lat: i.lat, lng: i.lng),
      ],
      color: _kCheckinBlue,
    );
    await drawPins(
      map,
      sourceId: 'tl-stamps-source',
      layerId: 'tl-stamps-layer',
      pins: [
        for (final i in items.where((i) => i.isStamp))
          MapPin(id: i.id, kind: 'stamp', name: i.name, lat: i.lat, lng: i.lng),
      ],
      color: kBrandGreen.toARGB32(),
    );

    if (items.isNotEmpty) {
      await map.flyTo(
        CameraOptions(
          center: Point(coordinates: Position(items.first.lng, items.first.lat)),
          zoom: 13.5,
        ),
        MapAnimationOptions(duration: 500),
      );
    }
  }

  // ── Interaction: tap pin or row → open that item's detail ─────
  Future<void> _onMapTap(MapContentGestureContext ctx) async {
    final map = _map;
    if (map == null) return;
    try {
      final features = await map.queryRenderedFeatures(
        RenderedQueryGeometry.fromScreenCoordinate(ctx.touchPosition),
        RenderedQueryOptions(
          layerIds: const ['tl-checkins-layer', 'tl-stamps-layer'],
          filter: null,
        ),
      );
      for (final f in features) {
        final props = f?.queriedFeature.feature['properties'];
        if (props is Map) {
          final id = props['id'] as String?;
          final item = id == null ? null : _itemById(id);
          if (item != null) {
            _openDetail(item);
            return;
          }
        }
      }
    } catch (e) {
      debugPrint('timeline queryRenderedFeatures: $e');
    }
  }

  void _openDetail(_TlItem item) {
    if (item.isStamp) {
      context.push('/stamp/${item.id}');
    } else {
      _showCheckInDetail(item.id);
    }
  }

  Future<void> _showCheckInDetail(String id) async {
    final res = await ref.read(checkInRepositoryProvider).getCheckIn(id);
    final ci = res.fold((_) => null, (c) => c);
    if (ci == null || !mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => _CheckInDetailSheet(
        checkIn: ci,
        onPromote: () => _promote(ctx, ci),
        onViewStamp: ci.stampId != null
            ? () {
                Navigator.pop(ctx);
                context.push('/stamp/${ci.stampId}');
              }
            : null,
      ),
    );
  }

  Future<void> _promote(BuildContext sheetCtx, CheckIn ci) async {
    Navigator.pop(sheetCtx);
    final r = await ref
        .read(checkInRepositoryProvider)
        .promoteToStamp(ci.id, visibility: StampVisibility.public);
    r.fold(
      (err) => ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(err.message))),
      (stampId) {
        if (!mounted) return;
        context.push('/stamp/$stampId');
        ref.read(timelineNotifierProvider.notifier).loadDay(_day);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(timelineNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => _shift(-1)),
            TextButton(
              onPressed: _pickDate,
              child: Text(
                _isToday ? 'Today' : DateFormat('EEE, MMM d').format(_day),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: _isToday ? null : () => _shift(1),
            ),
          ],
        ),
        actions: [
          IconButton(
              icon: const Icon(Icons.calendar_month), onPressed: _pickDate),
        ],
      ),
      body: state.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(message: errorMessage(e)),
        data: (bundle) {
          _bundle = bundle;
          _items = _buildItems(bundle);
          WidgetsBinding.instance
              .addPostFrameCallback((_) => _maybeRedraw(bundle));
          return Stack(
            children: [
              MapWidget(
                key: const ValueKey('timeline-map'),
                viewport: CameraViewportState(
                  center: Point(coordinates: Position(126.9780, 37.5665)),
                  zoom: 12.0,
                ),
                onMapCreated: (controller) {
                  _map = controller;
                  controller.addInteraction(TapInteraction.onMap(_onMapTap));
                  if (_bundle != null) _redraw(_bundle!);
                },
              ),
              _ListPanel(
                items: _items,
                day: _day,
                isToday: _isToday,
                onTapItem: _openDetail,
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── The hovering, draggable list panel ──────────────────────────
class _ListPanel extends StatelessWidget {
  final List<_TlItem> items;
  final DateTime day;
  final bool isToday;
  final void Function(_TlItem) onTapItem;

  const _ListPanel({
    required this.items,
    required this.day,
    required this.isToday,
    required this.onTapItem,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DraggableScrollableSheet(
      initialChildSize: 0.35,
      minChildSize: 0.12,
      maxChildSize: 0.85,
      snap: true,
      snapSizes: const [0.12, 0.35, 0.85],
      builder: (ctx, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 12,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: scheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                child: Row(
                  children: [
                    Text(
                      '${items.length} place${items.length == 1 ? '' : 's'}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const Spacer(),
                    Text(DateFormat('MMM d').format(day),
                        style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: items.isEmpty
                    ? ListView(
                        controller: scrollController,
                        children: [
                          const SizedBox(height: 40),
                          EmptyView(
                            icon: Icons.map_outlined,
                            message: 'Nothing logged this day',
                            subtitle: isToday
                                ? 'Check in to start your trace.'
                                : null,
                            action: isToday
                                ? FilledButton.icon(
                                    onPressed: () =>
                                        context.push('/checkin?mode=checkin'),
                                    icon: const Icon(
                                        Icons.add_location_alt_outlined),
                                    label: const Text('Check in'),
                                  )
                                : null,
                          ),
                        ],
                      )
                    : ListView.builder(
                        controller: scrollController,
                        itemExtent: 76,
                        itemCount: items.length,
                        itemBuilder: (ctx, i) => _TimelineTile(
                          item: items[i],
                          index: i,
                          total: items.length,
                          onTap: () => onTapItem(items[i]),
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TimelineTile extends StatelessWidget {
  final _TlItem item;
  final int index;
  final int total;
  final VoidCallback onTap;
  const _TimelineTile({
    required this.item,
    required this.index,
    required this.total,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Distinguish the two kinds: stamps = brand green ✦, check-ins = blue 📍.
    final color = item.isStamp ? scheme.primary : const Color(_kCheckinBlue);
    final subtitle = [
      DateFormat('h:mm a').format(item.time),
      if (item.note != null && item.note!.isNotEmpty) item.note!,
    ].join(' · ');

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            // Time-rail: connecting line + dot.
            SizedBox(
              width: 28,
              child: Column(
                children: [
                  Expanded(
                    child: Container(
                      width: 2,
                      color: index == 0
                          ? Colors.transparent
                          : scheme.outlineVariant,
                    ),
                  ),
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(color: scheme.surface, width: 2),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      width: 2,
                      color: index == total - 1
                          ? Colors.transparent
                          : scheme.outlineVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(item.isStamp ? Icons.auto_awesome : Icons.pin_drop,
                color: color, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(item.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 6),
                      _KindChip(isStamp: item.isStamp, color: color),
                    ],
                  ),
                  Text(subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            if (item.isStamp)
              Icon(item.isPublic ? Icons.public : Icons.lock,
                  size: 15, color: Colors.grey)
            else if (item.photoCount > 0)
              Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.photo, size: 13, color: Colors.grey),
                const SizedBox(width: 2),
                Text('${item.photoCount}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ]),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }
}

/// Small label distinguishing a stamp from a check-in.
class _KindChip extends StatelessWidget {
  final bool isStamp;
  final Color color;
  const _KindChip({required this.isStamp, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        isStamp ? 'Stamp' : 'Check-in',
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

class _CheckInDetailSheet extends StatelessWidget {
  final CheckIn checkIn;
  final VoidCallback onPromote;
  final VoidCallback? onViewStamp;
  const _CheckInDetailSheet({
    required this.checkIn,
    required this.onPromote,
    this.onViewStamp,
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
            if (checkIn.photoUrls.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 84,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: checkIn.photoUrls.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) => ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: checkIn.photoUrls[i],
                      width: 84,
                      height: 84,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: onViewStamp != null
                  ? FilledButton.tonal(
                      onPressed: onViewStamp,
                      child: const Text('View stamp'),
                    )
                  : FilledButton(
                      onPressed: onPromote,
                      child: const Text('Make a stamp'),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
