import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../../../app.dart';
import '../../../core/photos/photo_service.dart';
import '../../../data/models/check_in.dart';
import '../../../data/models/enums.dart';
import '../../../data/repositories/check_in_repository.dart';
import '../../../data/repositories/diary_repository.dart';
import '../../../data/repositories/timeline_note_repository.dart';
import '../../../shared/widgets/app_states.dart';
import '../../../shared/widgets/photo_thumb_row.dart';
import '../../checkin/presentation/photo_strip.dart';
import '../../map/presentation/map_drawing.dart';
import 'providers/timeline_provider.dart';

const _kCheckinBlue = 0xFF2196F3;
const _kNoteAmber = 0xFFF59E0B;

enum _NodeKind { checkIn, stamp, note }

/// A generalized timeline node — a check-in, a stamp, or a free-text note.
class _TlItem {
  final String id;
  final _NodeKind kind;
  final String name; // place name ('' for notes)
  final double? lat;
  final double? lng;
  final DateTime time;
  final String? text; // note / caption body
  final List<String> photoUrls;
  final bool isPublic;
  final bool isAuto; // passive auto check-in (gray)
  const _TlItem({
    required this.id,
    required this.kind,
    required this.name,
    required this.time,
    this.lat,
    this.lng,
    this.text,
    this.photoUrls = const [],
    this.isPublic = false,
    this.isAuto = false,
  });

  bool get isStamp => kind == _NodeKind.stamp;
  bool get isNote => kind == _NodeKind.note;
  bool get hasLocation => lat != null && lng != null;
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
    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      builder: (_) => _CalendarSheet(initial: _day),
    );
    if (picked != null) _load(DateTime(picked.year, picked.month, picked.day));
  }

  // ── Data → items + map ────────────────────────────────────────
  List<_TlItem> _buildItems(DayBundle b) {
    // A promoted check-in is represented by its stamp — don't show it twice.
    final promoted = {
      for (final s in b.stamps)
        if (s.checkInId != null) s.checkInId!
    };
    final items = <_TlItem>[
      for (final c in b.checkIns)
        if (!promoted.contains(c.id))
          _TlItem(
            id: c.id,
            kind: _NodeKind.checkIn,
            name: c.placeName,
            lat: c.lat,
            lng: c.lng,
            time: c.visitedAt,
            text: c.note,
            photoUrls: c.photoUrls,
            isAuto: c.source == CheckInSource.auto,
          ),
      for (final s in b.stamps)
        _TlItem(
          id: s.id,
          kind: _NodeKind.stamp,
          name: s.placeName,
          lat: s.lat,
          lng: s.lng,
          time: s.visitedAt,
          text: s.caption,
          photoUrls: s.photoUrls,
          isPublic: s.visibility == StampVisibility.public,
        ),
      for (final n in b.notes)
        _TlItem(
          id: n.id,
          kind: _NodeKind.note,
          name: '',
          time: n.notedAt,
          text: n.body,
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
    final located = items.where((i) => i.hasLocation).toList();

    // Trace = the day's located nodes (check-ins, auto anchors, stamps) joined
    // in time order. (Auto anchors sample movement, so this follows the path.)
    final coords = [for (final i in located) [i.lng!, i.lat!]];
    await drawLine(map, coords, kBrandGreen.toARGB32(), idPrefix: 'tl-path');

    await drawPins(
      map,
      sourceId: 'tl-checkins-source',
      layerId: 'tl-checkins-layer',
      pins: [
        for (final i in located.where((i) => !i.isStamp))
          MapPin(id: i.id, kind: 'checkin', name: i.name, lat: i.lat!, lng: i.lng!),
      ],
      color: _kCheckinBlue,
    );
    await drawPins(
      map,
      sourceId: 'tl-stamps-source',
      layerId: 'tl-stamps-layer',
      pins: [
        for (final i in located.where((i) => i.isStamp))
          MapPin(id: i.id, kind: 'stamp', name: i.name, lat: i.lat!, lng: i.lng!),
      ],
      color: kBrandGreen.toARGB32(),
    );
    await _drawSelection();

    if (located.isNotEmpty) {
      await map.flyTo(
        CameraOptions(
          center:
              Point(coordinates: Position(located.first.lng!, located.first.lat!)),
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
      (sel == null || !sel.hasLocation)
          ? null
          : MapPin(
              id: sel.id,
              kind: sel.isStamp ? 'stamp' : 'checkin',
              name: sel.name,
              lat: sel.lat!,
              lng: sel.lng!),
      kBrandGreen.toARGB32(),
    );
  }

  // ── Selection / detail ────────────────────────────────────────
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
    if (item != null && item.hasLocation) {
      _map?.flyTo(
        CameraOptions(
          center: Point(coordinates: Position(item.lng!, item.lat!)),
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
    switch (item.kind) {
      case _NodeKind.stamp:
        context.push('/stamp/${item.id}');
      case _NodeKind.checkIn:
        _showCheckInDetail(item.id);
      case _NodeKind.note:
        _editNote(item);
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
    final existing =
        await ref.read(checkInRepositoryProvider).getCheckInPhotos(ci.id);
    if (!mounted) return;
    final result = await showModalBottomSheet<_CheckInEdit>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _EditCheckInSheet(checkIn: ci, existing: existing),
    );
    if (result == null) return;
    final repo = ref.read(checkInRepositoryProvider);
    for (final pid in result.removedPhotoIds) {
      await repo.deletePhoto(pid);
    }
    final urls = <String>[];
    final photoService = PhotoService();
    for (final p in result.newPaths) {
      final u = await photoService.uploadFile(File(p));
      if (u != null) urls.add(u);
    }
    await repo.addCheckInPhotos(ci.id, urls);
    await repo.updateCheckIn(ci.id, {
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

  // ── Notes ─────────────────────────────────────────────────────
  Future<void> _addNote() async {
    final now = DateTime.now();
    final defaultAt = _isToday
        ? now
        : DateTime(_day.year, _day.month, _day.day, 12);
    final result = await showModalBottomSheet<({String body, DateTime at})>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _NoteSheet(day: _day, initialAt: defaultAt),
    );
    if (result == null || result.body.trim().isEmpty) return;
    await ref
        .read(timelineNoteRepositoryProvider)
        .add(_day, result.body.trim(), result.at);
    _reload();
  }

  Future<void> _editNote(_TlItem item) async {
    final result = await showModalBottomSheet<({String body, DateTime at})>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _NoteSheet(
        day: _day,
        initialAt: item.time,
        initialBody: item.text ?? '',
        allowDelete: true,
      ),
    );
    if (result == null) return;
    final repo = ref.read(timelineNoteRepositoryProvider);
    if (result.body == _kDeleteSentinel) {
      await repo.delete(item.id);
    } else {
      await repo.update(item.id, result.body.trim());
      await repo.setTime(item.id, result.at);
    }
    _reload();
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

  // Long-press drag of a note → reposition it. Its time becomes the next
  // node's time minus one minute (so it sorts just before that node).
  void _onReorder(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= _items.length) return;
    final moved = _items[oldIndex];
    if (moved.kind != _NodeKind.note) return; // only notes are movable
    // onReorderItem already adjusts newIndex for the removed item.
    final list = [..._items];
    list.removeAt(oldIndex);
    if (newIndex > list.length) newIndex = list.length;
    list.insert(newIndex, moved);

    final next = newIndex + 1 < list.length ? list[newIndex + 1] : null;
    final prev = newIndex - 1 >= 0 ? list[newIndex - 1] : null;
    final DateTime newTime;
    if (next != null) {
      newTime = next.time.subtract(const Duration(minutes: 1));
    } else if (prev != null) {
      newTime = prev.time.add(const Duration(minutes: 1));
    } else {
      newTime = moved.time;
    }
    _persistNoteTime(moved.id, newTime);
  }

  Future<void> _persistNoteTime(String id, DateTime t) async {
    await ref.read(timelineNoteRepositoryProvider).setTime(id, t);
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
                onAddNote: _addNote,
                onEditDiary: _editDiary,
                onReorder: _onReorder,
              ),
            ],
          );
        },
      ),
    );
  }
}

const _kDeleteSentinel = ' __delete__';

class _CheckInEdit {
  final String place;
  final String note;
  final Set<String> removedPhotoIds;
  final List<String> newPaths;
  const _CheckInEdit(
      this.place, this.note, this.removedPhotoIds, this.newPaths);
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
  final VoidCallback onAddNote;
  final VoidCallback onEditDiary;
  final void Function(int oldIndex, int newIndex) onReorder;

  const _ListPanel({
    required this.items,
    required this.itemKeys,
    required this.selectedId,
    required this.diary,
    required this.day,
    required this.isToday,
    required this.controller,
    required this.onTapItem,
    required this.onAddNote,
    required this.onEditDiary,
    required this.onReorder,
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
              // ── Drag handle / header. Drags the sheet; not a tap target. ──
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onVerticalDragUpdate: (d) {
                  if (!controller.isAttached) return;
                  final h = MediaQuery.of(context).size.height;
                  final next =
                      (controller.size - d.primaryDelta! / h).clamp(0.12, 0.85);
                  controller.jumpTo(next);
                },
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
                  ],
                ),
              ),
              // ── Scrollable nodes + diary ───────────────────
              // Notes are long-press draggable (ReorderableDelayedDragStartListener);
              // check-ins/stamps are fixed in time and not draggable.
              Expanded(
                child: CustomScrollView(
                  controller: scrollController,
                  slivers: [
                    if (items.isEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: EmptyView(
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
                        ),
                      ),
                    SliverReorderableList(
                      itemCount: items.length,
                      onReorderItem: onReorder,
                      itemBuilder: (ctx, i) {
                        final it = items[i];
                        final node = KeyedSubtree(
                          key: itemKeys[it.id]!,
                          child: _TimelineNode(
                            item: it,
                            isFirst: i == 0,
                            isLast: i == items.length - 1,
                            selected: it.id == selectedId,
                            onTap: () => onTapItem(it),
                          ),
                        );
                        if (it.isNote) {
                          return ReorderableDelayedDragStartListener(
                            key: ValueKey(it.id),
                            index: i,
                            child: node,
                          );
                        }
                        return KeyedSubtree(key: ValueKey(it.id), child: node);
                      },
                    ),
                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          const Divider(height: 1),
                          ListTile(
                            leading: Icon(Icons.add, color: scheme.primary),
                            title: const Text('Add a note'),
                            onTap: onAddNote,
                          ),
                        ],
                      ),
                    ),
                    SliverToBoxAdapter(
                        child: _DiaryCard(diary: diary, onEdit: onEditDiary)),
                    const SliverToBoxAdapter(child: SizedBox(height: 32)),
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

  Color _color(ColorScheme scheme) {
    if (item.isAuto) return Colors.grey;
    return switch (item.kind) {
      _NodeKind.stamp => scheme.primary,
      _NodeKind.checkIn => const Color(_kCheckinBlue),
      _NodeKind.note => const Color(_kNoteAmber),
    };
  }

  IconData get _icon => item.isAuto
      ? Icons.gps_fixed
      : switch (item.kind) {
          _NodeKind.stamp => Icons.auto_awesome,
          _NodeKind.checkIn => Icons.pin_drop,
          _NodeKind.note => Icons.sticky_note_2_outlined,
        };

  String get _label => item.isAuto
      ? 'Auto'
      : switch (item.kind) {
          _NodeKind.stamp => 'Stamp',
          _NodeKind.checkIn => 'Check-in',
          _NodeKind.note => 'Note',
        };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = _color(scheme);
    final hasText = item.text != null && item.text!.trim().isNotEmpty;

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
                // Node rail.
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
                            Icon(_icon, size: 16, color: color),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                item.isNote ? 'Note' : item.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: item.isAuto ? Colors.grey : null,
                                ),
                              ),
                            ),
                            _KindChip(label: _label, color: color),
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
                          ],
                        ),
                        if (hasText) ...[
                          const SizedBox(height: 4),
                          Text(
                            item.text!,
                            maxLines: item.isNote ? 4 : 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 13, color: scheme.onSurfaceVariant),
                          ),
                        ],
                        if (item.photoUrls.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          PhotoThumbRow(urls: item.photoUrls, size: 64),
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
  final String label;
  final Color color;
  const _KindChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
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

// ── Modal: add/edit a timeline note ─────────────────────────────
class _NoteSheet extends StatefulWidget {
  final DateTime day;
  final DateTime initialAt;
  final String initialBody;
  final bool allowDelete;
  const _NoteSheet({
    required this.day,
    required this.initialAt,
    this.initialBody = '',
    this.allowDelete = false,
  });

  @override
  State<_NoteSheet> createState() => _NoteSheetState();
}

class _NoteSheetState extends State<_NoteSheet> {
  late final TextEditingController _ctrl =
      TextEditingController(text: widget.initialBody);
  late TimeOfDay _time = TimeOfDay.fromDateTime(widget.initialAt);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  DateTime get _at => DateTime(
      widget.day.year, widget.day.month, widget.day.day, _time.hour, _time.minute);

  Future<void> _pickTime() async {
    final t = await showTimePicker(context: context, initialTime: _time);
    if (t != null) setState(() => _time = t);
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
          Text(widget.allowDelete ? 'Edit note' : 'Add a note',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          TextField(
            controller: _ctrl,
            autofocus: true,
            maxLines: 4,
            minLines: 2,
            decoration: const InputDecoration(
                hintText: 'Anything you want to remember…',
                border: OutlineInputBorder()),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.schedule, size: 18, color: Colors.grey),
              const SizedBox(width: 8),
              Text(_time.format(context)),
              const Spacer(),
              TextButton(onPressed: _pickTime, child: const Text('Change time')),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (widget.allowDelete)
                TextButton.icon(
                  onPressed: () => Navigator.pop(
                      context, (body: _kDeleteSentinel, at: _at)),
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  label: const Text('Delete',
                      style: TextStyle(color: Colors.red)),
                ),
              const Spacer(),
              FilledButton(
                onPressed: _ctrl.text.trim().isEmpty
                    ? null
                    : () =>
                        Navigator.pop(context, (body: _ctrl.text, at: _at)),
                child: const Text('Save'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Modal: edit a check-in (place, note, photos) ────────────────
class _EditCheckInSheet extends StatefulWidget {
  final CheckIn checkIn;
  final List<({String id, String url})> existing;
  const _EditCheckInSheet({required this.checkIn, required this.existing});

  @override
  State<_EditCheckInSheet> createState() => _EditCheckInSheetState();
}

class _EditCheckInSheetState extends State<_EditCheckInSheet> {
  late final TextEditingController _place =
      TextEditingController(text: widget.checkIn.placeName);
  late final TextEditingController _note =
      TextEditingController(text: widget.checkIn.note ?? '');
  final Set<String> _removed = {};
  final List<String> _newPaths = [];

  @override
  void dispose() {
    _place.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remaining =
        widget.existing.where((e) => !_removed.contains(e.id)).toList();
    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: SingleChildScrollView(
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
            Text('Photos', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            if (remaining.isNotEmpty)
              SizedBox(
                height: 80,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: remaining.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) => Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: remaining[i].url,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        right: 2,
                        top: 2,
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _removed.add(remaining[i].id)),
                          child: const CircleAvatar(
                            radius: 11,
                            backgroundColor: Colors.black54,
                            child: Icon(Icons.close,
                                size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 8),
            PhotoStrip(
              paths: _newPaths,
              onChanged: (p) => setState(() {
                _newPaths
                  ..clear()
                  ..addAll(p);
              }),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _place.text.trim().isEmpty
                    ? null
                    : () => Navigator.pop(
                        context,
                        _CheckInEdit(_place.text.trim(), _note.text.trim(),
                            _removed, _newPaths)),
                child: const Text('Save'),
              ),
            ),
          ],
        ),
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
              PhotoThumbRow(urls: checkIn.photoUrls, size: 84),
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

// ── Bottom sheet: month calendar with check-in counts ───────────
class _CalendarSheet extends ConsumerStatefulWidget {
  final DateTime initial;
  const _CalendarSheet({required this.initial});

  @override
  ConsumerState<_CalendarSheet> createState() => _CalendarSheetState();
}

class _CalendarSheetState extends ConsumerState<_CalendarSheet> {
  late DateTime _month;
  Map<int, int> _counts = {};

  @override
  void initState() {
    super.initState();
    _month = DateTime(widget.initial.year, widget.initial.month);
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    final c =
        await ref.read(checkInRepositoryProvider).monthlyVisitCounts(_month);
    if (mounted) setState(() => _counts = c);
  }

  void _prevMonth() {
    setState(() => _month = DateTime(_month.year, _month.month - 1));
    _loadCounts();
  }

  void _nextMonth() {
    final now = DateTime.now();
    final next = DateTime(_month.year, _month.month + 1);
    if (next.isAfter(DateTime(now.year, now.month))) return;
    setState(() => _month = next);
    _loadCounts();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final leadingBlanks = DateTime(_month.year, _month.month, 1).weekday % 7;
    final atCurrentMonth =
        _month.year == now.year && _month.month == now.month;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: _prevMonth),
                Expanded(
                  child: Text(
                    DateFormat('MMMM yyyy').format(_month),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: atCurrentMonth ? null : _nextMonth),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                for (final d in const ['S', 'M', 'T', 'W', 'T', 'F', 'S'])
                  Expanded(
                    child: Center(
                      child: Text(d,
                          style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7, childAspectRatio: 0.8),
              itemCount: leadingBlanks + daysInMonth,
              itemBuilder: (ctx, i) {
                if (i < leadingBlanks) return const SizedBox.shrink();
                final day = i - leadingBlanks + 1;
                final date = DateTime(_month.year, _month.month, day);
                final count = _counts[day] ?? 0;
                final isFuture = date.isAfter(today);
                final isSelected = date.year == widget.initial.year &&
                    date.month == widget.initial.month &&
                    date.day == widget.initial.day;
                return InkWell(
                  onTap: isFuture ? null : () => Navigator.pop(context, date),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? scheme.primaryContainer
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('$day',
                            style: TextStyle(
                              color: isFuture ? Colors.grey.shade400 : null,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.normal,
                            )),
                        const SizedBox(height: 2),
                        // Check-in count badge (0 omitted).
                        if (count > 0)
                          Container(
                            width: 18,
                            height: 18,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              color: Color(_kCheckinBlue),
                              shape: BoxShape.circle,
                            ),
                            child: Text('$count',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700)),
                          )
                        else
                          const SizedBox(height: 18),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
