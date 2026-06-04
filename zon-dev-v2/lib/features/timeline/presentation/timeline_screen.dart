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
import '../../../data/repositories/diary_repository.dart';
import '../../../shared/widgets/app_states.dart';
import '../../map/presentation/map_drawing.dart';
import 'providers/timeline_provider.dart';

const _kCheckinBlue = 0xFF2196F3;

/// One node on the timeline — a check-in or a stamp, time-ordered.
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
  String _diary = '';
  String? _selectedId;
  DayBundle? _bundle;
  DayBundle? _drawn;

  final _sheetController = DraggableScrollableController();
  final Map<String, GlobalKey> _itemKeys = {};

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
    setState(() {
      _day = d;
      _selectedId = null;
    });
    ref.read(timelineNotifierProvider.notifier).loadDay(d);
  }

  void _reload() => ref.read(timelineNotifierProvider.notifier).loadDay(_day);

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
    if (picked != null) _load(DateTime(picked.year, picked.month, picked.day));
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
    await _drawSelection();

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

  Future<void> _drawSelection() async {
    final map = _map;
    if (map == null) return;
    final sel = _selectedId == null ? null : _itemById(_selectedId!);
    await drawHighlight(
      map,
      sel == null
          ? null
          : MapPin(
              id: sel.id,
              kind: sel.isStamp ? 'stamp' : 'checkin',
              name: sel.name,
              lat: sel.lat,
              lng: sel.lng),
      kBrandGreen.toARGB32(),
    );
  }

  // ── Selection / detail ────────────────────────────────────────
  // Tapping a pin highlights its node in the list (no detail). Tapping a
  // node in the list opens the detail.
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
          if (id != null && _itemById(id) != null) {
            _highlight(id);
            return;
          }
        }
      }
    } catch (e) {
      debugPrint('timeline queryRenderedFeatures: $e');
    }
  }

  void _highlight(String id) {
    setState(() => _selectedId = id);
    _drawSelection();
    final item = _itemById(id);
    if (item != null) {
      _map?.flyTo(
        CameraOptions(
          center: Point(coordinates: Position(item.lng, item.lat)),
          zoom: 15.0,
        ),
        MapAnimationOptions(duration: 400),
      );
    }
    if (_sheetController.isAttached && _sheetController.size < 0.4) {
      _sheetController.animateTo(0.5,
          duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final keyCtx = _itemKeys[id]?.currentContext;
      if (keyCtx != null) {
        Scrollable.ensureVisible(keyCtx,
            duration: const Duration(milliseconds: 300),
            alignment: 0.3,
            curve: Curves.easeOut);
      }
    });
  }

  void _openDetail(_TlItem item) {
    setState(() => _selectedId = item.id);
    _drawSelection();
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
        onEdit: () {
          Navigator.pop(ctx);
          _editCheckIn(ci);
        },
        onDelete: () {
          Navigator.pop(ctx);
          _deleteCheckIn(ci);
        },
        onViewStamp: ci.stampId != null
            ? () {
                Navigator.pop(ctx);
                context.push('/stamp/${ci.stampId}');
              }
            : null,
      ),
    );
  }

  Future<void> _editCheckIn(CheckIn ci) async {
    final result = await showModalBottomSheet<({String place, String note})>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _EditCheckInSheet(checkIn: ci),
    );
    if (result == null) return;
    await ref.read(checkInRepositoryProvider).updateCheckIn(ci.id, {
      'place_name': result.place,
      'normalized_place_name': result.place.toLowerCase().trim(),
      'note': result.note,
    });
    _reload();
  }

  Future<void> _deleteCheckIn(CheckIn ci) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete check-in?'),
        content: Text('Remove "${ci.placeName}" from your trace?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(checkInRepositoryProvider).deleteCheckIn(ci.id);
    if (_selectedId == ci.id) _selectedId = null;
    _reload();
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
        _reload();
      },
    );
  }

  Future<void> _editDiary() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _EditDiarySheet(initial: _diary, day: _day),
    );
    if (result == null) return;
    await ref.read(diaryRepositoryProvider).saveDiary(_day, result);
    _reload();
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
          _diary = bundle.diary;
          for (final i in _items) {
            _itemKeys.putIfAbsent(i.id, () => GlobalKey());
          }
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
                itemKeys: _itemKeys,
                selectedId: _selectedId,
                diary: _diary,
                day: _day,
                isToday: _isToday,
                controller: _sheetController,
                onTapItem: _openDetail,
                onEditDiary: _editDiary,
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
  final Map<String, GlobalKey> itemKeys;
  final String? selectedId;
  final String diary;
  final DateTime day;
  final bool isToday;
  final DraggableScrollableController controller;
  final void Function(_TlItem) onTapItem;
  final VoidCallback onEditDiary;

  const _ListPanel({
    required this.items,
    required this.itemKeys,
    required this.selectedId,
    required this.diary,
    required this.day,
    required this.isToday,
    required this.controller,
    required this.onTapItem,
    required this.onEditDiary,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DraggableScrollableSheet(
      controller: controller,
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
              // ── Fixed, non-interactive header ──────────────
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
              // ── Scrollable nodes + diary ───────────────────
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.zero,
                  children: [
                    if (items.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 28),
                        child: EmptyView(
                          icon: Icons.map_outlined,
                          message: 'Nothing logged this day',
                          subtitle:
                              isToday ? 'Check in to start your trace.' : null,
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
                      ),
                    for (int i = 0; i < items.length; i++)
                      KeyedSubtree(
                        key: itemKeys[items[i].id],
                        child: _TimelineNode(
                          item: items[i],
                          isFirst: i == 0,
                          isLast: i == items.length - 1,
                          selected: items[i].id == selectedId,
                          onTap: () => onTapItem(items[i]),
                        ),
                      ),
                    _DiaryCard(diary: diary, onEdit: onEditDiary),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TimelineNode extends StatelessWidget {
  final _TlItem item;
  final bool isFirst;
  final bool isLast;
  final bool selected;
  final VoidCallback onTap;
  const _TimelineNode({
    required this.item,
    required this.isFirst,
    required this.isLast,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = item.isStamp ? scheme.primary : const Color(_kCheckinBlue);
    final hasNote = item.note != null && item.note!.trim().isNotEmpty;

    return Material(
      color: selected
          ? scheme.primary.withValues(alpha: 0.10)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: IntrinsicHeight(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Node rail: connecting line + dot.
                SizedBox(
                  width: 28,
                  child: Column(
                    children: [
                      Expanded(
                        child: Container(
                          width: 2,
                          color: isFirst
                              ? Colors.transparent
                              : scheme.outlineVariant,
                        ),
                      ),
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(color: scheme.surface, width: 3),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          width: 2,
                          color: isLast
                              ? Colors.transparent
                              : scheme.outlineVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                                item.isStamp
                                    ? Icons.auto_awesome
                                    : Icons.pin_drop,
                                size: 16,
                                color: color),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(item.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                            ),
                            _KindChip(isStamp: item.isStamp, color: color),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(DateFormat('h:mm a').format(item.time),
                                style: const TextStyle(
                                    color: Colors.grey, fontSize: 12)),
                            if (item.isStamp) ...[
                              const SizedBox(width: 6),
                              Icon(item.isPublic ? Icons.public : Icons.lock,
                                  size: 12, color: Colors.grey),
                            ],
                            if (item.photoCount > 0) ...[
                              const SizedBox(width: 6),
                              const Icon(Icons.photo,
                                  size: 12, color: Colors.grey),
                              const SizedBox(width: 2),
                              Text('${item.photoCount}',
                                  style: const TextStyle(
                                      color: Colors.grey, fontSize: 12)),
                            ],
                          ],
                        ),
                        if (hasNote) ...[
                          const SizedBox(height: 4),
                          Text(
                            item.note!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 13, color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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
      child: Text(isStamp ? 'Stamp' : 'Check-in',
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

class _DiaryCard extends StatelessWidget {
  final String diary;
  final VoidCallback onEdit;
  const _DiaryCard({required this.diary, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final empty = diary.trim().isEmpty;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Card(
        margin: EdgeInsets.zero,
        child: InkWell(
          onTap: onEdit,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.menu_book_outlined, size: 18),
                    const SizedBox(width: 8),
                    const Text('Diary',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                    const Spacer(),
                    Icon(empty ? Icons.edit_outlined : Icons.edit,
                        size: 18, color: Colors.grey),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  empty ? 'Write about your day…' : diary,
                  style: TextStyle(
                    color: empty ? Colors.grey : null,
                    fontStyle: empty ? FontStyle.italic : FontStyle.normal,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Modal: edit a check-in ──────────────────────────────────────
class _EditCheckInSheet extends StatefulWidget {
  final CheckIn checkIn;
  const _EditCheckInSheet({required this.checkIn});

  @override
  State<_EditCheckInSheet> createState() => _EditCheckInSheetState();
}

class _EditCheckInSheetState extends State<_EditCheckInSheet> {
  late final TextEditingController _place =
      TextEditingController(text: widget.checkIn.placeName);
  late final TextEditingController _note =
      TextEditingController(text: widget.checkIn.note ?? '');

  @override
  void dispose() {
    _place.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Edit check-in',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          TextField(
            controller: _place,
            decoration: const InputDecoration(
                labelText: 'Place name', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _note,
            maxLines: 3,
            decoration: const InputDecoration(
                labelText: 'Note', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _place.text.trim().isEmpty
                  ? null
                  : () => Navigator.pop(context,
                      (place: _place.text.trim(), note: _note.text.trim())),
              child: const Text('Save'),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Modal: edit the day's diary ─────────────────────────────────
class _EditDiarySheet extends StatefulWidget {
  final String initial;
  final DateTime day;
  const _EditDiarySheet({required this.initial, required this.day});

  @override
  State<_EditDiarySheet> createState() => _EditDiarySheetState();
}

class _EditDiarySheetState extends State<_EditDiarySheet> {
  late final TextEditingController _ctrl =
      TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.menu_book_outlined, size: 20),
              const SizedBox(width: 8),
              Text(DateFormat('EEEE, MMM d').format(widget.day),
                  style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _ctrl,
            autofocus: true,
            maxLines: 8,
            minLines: 4,
            decoration: const InputDecoration(
              hintText: 'How was your day?',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.pop(context, _ctrl.text.trim()),
              child: const Text('Save'),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bottom sheet: check-in detail + actions ─────────────────────
class _CheckInDetailSheet extends StatelessWidget {
  final CheckIn checkIn;
  final VoidCallback onPromote;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onViewStamp;
  const _CheckInDetailSheet({
    required this.checkIn,
    required this.onPromote,
    required this.onEdit,
    required this.onDelete,
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
                IconButton(
                    icon: const Icon(Icons.edit_outlined), onPressed: onEdit),
                IconButton(
                    icon:
                        const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: onDelete),
              ],
            ),
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
                      onPressed: onViewStamp, child: const Text('View stamp'))
                  : FilledButton(
                      onPressed: onPromote,
                      child: const Text('Make a stamp')),
            ),
          ],
        ),
      ),
    );
  }
}
