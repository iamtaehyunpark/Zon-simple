import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:record/record.dart' show Amplitude;
import 'package:geolocator/geolocator.dart' show Geolocator;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../core/audio/voice_memo_service.dart';
import '../../../core/photos/photo_service.dart';
import '../../../shared/widgets/place_search_field.dart';
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
  final String? audioUrl; // voice-memo recording (note nodes only)
  final int? audioDurationMs;
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
    this.audioUrl,
    this.audioDurationMs,
  });

  bool get isStamp => kind == _NodeKind.stamp;
  bool get isNote => kind == _NodeKind.note;
  bool get isVoice => audioUrl != null && audioUrl!.isNotEmpty;
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
  String? _expandedId; // node whose inline editor is open
  DayBundle? _bundle;
  DayBundle? _drawn;
  bool _isGeneratingDiary = false;
  Map<String, int> _monthlyActivity = {};
  final Set<String> _loadedMonths = {};
  Set<String> _diaryDays = {};

  List<DateTime>? _slidableDaysCache;
  DateTime? _slidableDaysCacheKey;

  final _sheetController = DraggableScrollableController();
  final _dateStripController = ScrollController();
  final Map<String, GlobalKey> _itemKeys = {};

  @override
  void initState() {
    super.initState();
    // Restore the last-selected day from the keepAlive provider so navigating
    // away and back doesn't reset to today or trigger a refetch.
    final existing = ref.read(timelineNotifierProvider).valueOrNull;
    if (existing != null) {
      _day = existing.date;
    } else {
      final n = DateTime.now();
      _day = DateTime(n.year, n.month, n.day);
      // Provider is fresh — build() already enqueued loadDay(today) via microtask.
    }
    _loadActivity(_day);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelectedDate();
    });
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
    _loadActivity(d);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelectedDate();
    });
  }

  Future<void> _loadActivity(DateTime date) async {
    final checkInRepo = ref.read(checkInRepositoryProvider);
    final now = DateTime.now();
    
    // Fetch diary dates
    final days = _slidableDays;
    if (days.isNotEmpty) {
      final firstDateStr = days.first.toIso8601String().substring(0, 10);
      final diaryDays = await ref
          .read(diaryRepositoryProvider)
          .getDiaryDates(from: firstDateStr);
      if (mounted) {
        setState(() {
          _diaryDays = diaryDays;
        });
      }
    }
    
    // We always want to ensure the last 6 months are loaded, plus the active selected month.
    final targetMonths = <DateTime>[];
    for (int i = 0; i <= 6; i++) {
      targetMonths.add(DateTime(now.year, now.month - i, 1));
    }
    final selectedMonth = DateTime(date.year, date.month, 1);
    if (!targetMonths.any((m) => m.year == selectedMonth.year && m.month == selectedMonth.month)) {
      targetMonths.add(selectedMonth);
    }
    
    // Filter to only those months we haven't loaded yet
    final toLoad = targetMonths.where((m) {
      final key = '${m.year}-${m.month.toString().padLeft(2, '0')}';
      return !_loadedMonths.contains(key);
    }).toList();
    
    if (toLoad.isEmpty) return;
    
    final List<Map<int, int>> results = await Future.wait<Map<int, int>>(
      toLoad.map((m) => checkInRepo.monthlyVisitCounts(m))
    );
    
    final newActivity = <String, int>{..._monthlyActivity};
    for (int i = 0; i < toLoad.length; i++) {
      final m = toLoad[i];
      final counts = results[i];
      final monthKey = '${m.year}-${m.month.toString().padLeft(2, '0')}';
      _loadedMonths.add(monthKey);
      
      counts.forEach((day, count) {
        final dateKey = '$monthKey-${day.toString().padLeft(2, '0')}';
        newActivity[dateKey] = count;
      });
    }
    
    if (mounted) {
      setState(() {
        _monthlyActivity = newActivity;
      });
    }
  }

  @override
  void dispose() {
    _sheetController.dispose();
    _dateStripController.dispose();
    super.dispose();
  }

  void _jumpToToday() {
    final now = DateTime.now();
    _load(DateTime(now.year, now.month, now.day));
  }

  List<DateTime> get _slidableDays {
    if (_slidableDaysCache != null && _slidableDaysCacheKey == _day) {
      return _slidableDaysCache!;
    }
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final days = <DateTime>[];
    for (int i = 180; i >= 0; i--) {
      days.add(today.subtract(Duration(days: i)));
    }
    if (_day.isBefore(days.first)) {
      final diff = days.first.difference(_day).inDays;
      for (int i = diff; i >= 1; i--) {
        days.insert(0, _day.subtract(Duration(days: i)));
      }
      days.insert(0, _day);
    }
    _slidableDaysCacheKey = _day;
    _slidableDaysCache = days;
    return days;
  }

  void _scrollToSelectedDate() {
    if (!_dateStripController.hasClients) return;
    final screenWidth = MediaQuery.of(context).size.width;
    final days = _slidableDays;
    final idx = days.indexWhere((d) =>
        d.year == _day.year && d.month == _day.month && d.day == _day.day);
    if (idx != -1) {
      const itemWidth = 64.0;
      final target = (idx * itemWidth) - (screenWidth / 2) + (itemWidth / 2);
      final maxScroll = _dateStripController.position.maxScrollExtent;
      final minScroll = _dateStripController.position.minScrollExtent;
      final clampedTarget = target.clamp(minScroll, maxScroll);
      
      _dateStripController.animateTo(
        clampedTarget,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _reload() => ref.read(timelineNotifierProvider.notifier).loadDay(_day);

  /// YYYY-MM-DD string for the currently displayed day.
  String get _currentDateKey =>
      '${_day.year}-${_day.month.toString().padLeft(2, '0')}-${_day.day.toString().padLeft(2, '0')}';

  /// Update `_diaryDays` state and reload after the user saves a diary edit.
  void _applyDiaryResult(String saved) {
    if (mounted) {
      setState(() {
        if (saved.trim().isEmpty) {
          _diaryDays.remove(_currentDateKey);
        } else {
          _diaryDays.add(_currentDateKey);
        }
      });
    }
    _reload();
  }

  void _shift(int days) {
    final next = _day.add(Duration(days: days));
    final n = DateTime.now();
    if (next.isAfter(DateTime(n.year, n.month, n.day))) return;
    _load(next);
  }

  Future<void> _pickDate() async {
    final picked = await showModalBottomSheet<DateTime>(
      useRootNavigator: true,
      context: context,
      isScrollControlled: true,
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
          audioUrl: n.audioUrl,
          audioDurationMs: n.audioDurationMs,
        ),
    ]..sort((a, b) => a.time.compareTo(b.time));

    // Proximity check:
    // Only filter out an auto check-in if it is close (< 80m) to the immediately preceding
    // location node (indicating a continuous stay) or close to the immediately succeeding
    // manual/stamp node (preventing double entries for a manual check-in).
    final filtered = <_TlItem>[];
    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      if (item.isAuto && item.lat != null && item.lng != null) {
        final prev = _nearestLocated(items, i - 1, -1);
        final next = _nearestLocated(items, i + 1, 1);
        bool within80(_TlItem? o) => o != null &&
            Geolocator.distanceBetween(item.lat!, item.lng!, o.lat!, o.lng!) < 80;
        // Skip an auto pin hugging the preceding location node (continuous
        // stay) or an immediately following manual/stamp node (duplicate entry).
        if (within80(prev) || (next != null && !next.isAuto && within80(next))) {
          continue;
        }
      }
      filtered.add(item);
    }

    return filtered;
  }

  /// First non-note, located item scanning from [start] by [step] (±1).
  _TlItem? _nearestLocated(List<_TlItem> items, int start, int step) {
    for (int j = start; j >= 0 && j < items.length; j += step) {
      final it = items[j];
      if (!it.isNote && it.lat != null && it.lng != null) return it;
    }
    return null;
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

  /// The day's trace polyline: raw GPS breadcrumbs merged with every located
  /// node (check-ins, auto anchors — including ones hidden from the list — and
  /// stamps), ordered by time. Makes the timeline trace follow real movement
  /// like the live map, instead of straight pin-to-pin segments.
  List<List<double>> _traceCoords(DayBundle b) {
    final points = <(DateTime, double, double)>[
      for (final e in b.route) (e.capturedAt, e.lng, e.lat),
      for (final c in b.checkIns) (c.visitedAt, c.lng, c.lat),
      for (final s in b.stamps) (s.visitedAt, s.lng, s.lat),
    ]..sort((x, y) => x.$1.compareTo(y.$1));

    // Drop consecutive duplicate coordinates to keep the line lean.
    final coords = <List<double>>[];
    for (final p in points) {
      if (coords.isEmpty || coords.last[0] != p.$2 || coords.last[1] != p.$3) {
        coords.add([p.$2, p.$3]);
      }
    }
    return coords;
  }

  Future<void> _redraw(DayBundle b) async {
    final map = _map;
    if (map == null) return;
    final items = _buildItems(b);
    final located = items.where((i) => i.hasLocation).toList();

    // Trace = the day's raw GPS breadcrumbs merged with every located node, so
    // the line follows actual movement (like the live map) and still threads
    // through each check-in / anchor / stamp.
    await drawLine(map, _traceCoords(b), Z.brand.toARGB32(),
        idPrefix: 'tl-path');

    await drawPins(
      map,
      sourceId: 'tl-checkins-source',
      layerId: 'tl-checkins-layer',
      pins: [
        for (final i in located.where((i) => !i.isStamp && !i.isAuto))
          MapPin(id: i.id, kind: 'checkin', name: i.name, lat: i.lat!, lng: i.lng!),
      ],
      color: _kCheckinBlue,
    );
    // Auto anchors: tiny, faint dots so the trace reads but stays uncluttered.
    await drawPins(
      map,
      sourceId: 'tl-auto-source',
      layerId: 'tl-auto-layer',
      pins: [
        for (final i in located.where((i) => !i.isStamp && i.isAuto))
          MapPin(id: i.id, kind: 'checkin', name: i.name, lat: i.lat!, lng: i.lng!),
      ],
      color: 0xFF9E9E9E,
      circleRadius: 2.5,
      strokeWidth: 0.0,
      opacity: 0.55,
    );
    await drawPins(
      map,
      sourceId: 'tl-stamps-source',
      layerId: 'tl-stamps-layer',
      pins: [
        for (final i in located.where((i) => i.isStamp))
          MapPin(id: i.id, kind: 'stamp', name: i.name, lat: i.lat!, lng: i.lng!),
      ],
      color: Z.brand.toARGB32(),
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
      Z.brand.toARGB32(),
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
          layerIds: const [
            'tl-checkins-layer',
            'tl-auto-layer',
            'tl-stamps-layer'
          ],
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

  // Tap a node — highlight it (syncs the map), then navigate to detail for
  // check-ins and stamps.
  void _onTapNode(_TlItem item) => _highlight(item.id);

  // Long-press → act on it: stamp opens its page; check-in/note opens the
  // inline editor.
  void _onLongPressNode(_TlItem item) {
    if (item.isStamp) {
      setState(() => _selectedId = item.id);
      _drawSelection();
      context.push('/stamp/${item.id}');
      return;
    }
    setState(() {
      _selectedId = item.id;
      _expandedId = _expandedId == item.id ? null : item.id;
    });
    _drawSelection();
  }

  Future<void> _saveText(_TlItem item, String text) async {
    if (item.isNote) {
      await ref.read(timelineNoteRepositoryProvider).update(item.id, text);
    } else {
      await ref
          .read(checkInRepositoryProvider)
          .updateCheckIn(item.id, {'note': text});
    }
    if (mounted) setState(() => _expandedId = null);
    _reload();
  }

  Future<void> _addPhotosInline(_TlItem item) async {
    final picked = await ImagePicker().pickMultiImage();
    if (picked.isEmpty) return;
    final service = PhotoService();
    final results = await Future.wait([
      for (final x in picked) service.uploadFile(File(x.path)),
    ]);
    final urls = [for (final u in results) if (u != null) u];
    await ref.read(checkInRepositoryProvider).addCheckInPhotos(item.id, urls);
    _reload();
  }

  Future<void> _deletePhoto(String url) async {
    await ref.read(checkInRepositoryProvider).deletePhotoByUrl(url);
    _reload();
  }

  // Swipe-left to delete a check-in or note.
  Future<void> _deleteItem(_TlItem item) async {
    if (item.isNote) {
      await ref.read(timelineNoteRepositoryProvider).delete(item.id);
    } else if (item.kind == _NodeKind.checkIn) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Delete check-in?'),
          content: Text('Remove "${item.name}" from your trace?'),
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
      await ref.read(checkInRepositoryProvider).deleteCheckIn(item.id);
    } else {
      return;
    }
    if (_selectedId == item.id) _selectedId = null;
    if (_expandedId == item.id) _expandedId = null;
    _reload();
  }

  // Long-press drag of a note → reposition it.
  void _onReorder(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= _items.length) return;
    final moved = _items[oldIndex];
    if (moved.kind != _NodeKind.note) return; // Only allow notes to be reordered
    
    final list = [..._items];
    list.removeAt(oldIndex);
    
    // Adjust newIndex if it's past the removed element
    final adjustedNew = newIndex > oldIndex ? newIndex - 1 : newIndex;
    final clampedNew = adjustedNew.clamp(0, list.length);
    list.insert(clampedNew, moved);

    final next = clampedNew + 1 < list.length ? list[clampedNew + 1] : null;
    final prev = clampedNew - 1 >= 0 ? list[clampedNew - 1] : null;
    final DateTime newTime;
    
    if (prev != null && next != null) {
      final diffMs = next.time.difference(prev.time).inMilliseconds;
      if (diffMs > 1000) {
        newTime = prev.time.add(Duration(milliseconds: diffMs ~/ 2));
      } else {
        newTime = prev.time.add(const Duration(milliseconds: 500));
      }
    } else if (next != null) {
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

  // Edit a note's time from a time picker.
  Future<void> _changeNoteTime(_TlItem item) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(item.time),
    );
    if (picked == null) return;
    final t = DateTime(
        _day.year, _day.month, _day.day, picked.hour, picked.minute);
    await _persistNoteTime(item.id, t);
  }

  void _moreCheckIn(_TlItem item) => _showCheckInDetail(item.id);

  Future<void> _showCheckInDetail(String id) async {
    final res = await ref.read(checkInRepositoryProvider).getCheckIn(id);
    final ci = res.fold((_) => null, (c) => c);
    if (ci == null || !mounted) return;
    await showModalBottomSheet<void>(
      useRootNavigator: true,
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
        onMerge: () {
          Navigator.pop(ctx);
          _mergeCheckIn(ci);
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
      useRootNavigator: true,
      context: context,
      isScrollControlled: true,
      builder: (_) => _EditCheckInSheet(checkIn: ci, existing: existing),
    );
    if (result == null) return;
    final repo = ref.read(checkInRepositoryProvider);
    for (final pid in result.removedPhotoIds) {
      await repo.deletePhoto(pid);
    }
    final photoService = PhotoService();
    final uploadResults = await Future.wait([
      for (final p in result.newPaths) photoService.uploadFile(File(p)),
    ]);
    final urls = [for (final u in uploadResults) if (u != null) u];
    await repo.addCheckInPhotos(ci.id, urls);
    await repo.updateCheckIn(ci.id, {
      'place_name': result.place,
      'normalized_place_name': result.place.toLowerCase().trim(),
      'note': result.note,
      'visibility': result.isPublic ? 'public' : 'private',
    });
    _reload();
  }

  Future<void> _mergeCheckIn(CheckIn keep) async {
    // Collect other manual check-ins from the same day as merge candidates.
    final candidates = (_bundle?.checkIns ?? [])
        .where((c) => c.id != keep.id && c.source != CheckInSource.auto)
        .toList()
      ..sort((a, b) => a.visitedAt.compareTo(b.visitedAt));

    if (candidates.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No other check-ins to merge with today')),
        );
      }
      return;
    }

    final into = await showModalBottomSheet<CheckIn>(
      useRootNavigator: true,
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text('Merge "${keep.placeName}" into…',
                  style: Theme.of(ctx).textTheme.titleMedium),
            ),
            const Divider(height: 1),
            for (final c in candidates)
              ListTile(
                leading: const Icon(Icons.pin_drop_outlined),
                title: Text(c.placeName),
                subtitle: Text(DateFormat('h:mm a').format(c.visitedAt)),
                onTap: () => Navigator.pop(ctx, c),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (into == null || !mounted) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Merge check-ins?'),
        content: Text(
            'Photos and notes from "${keep.placeName}" will be added to '
            '"${into.placeName}". "${keep.placeName}" will be deleted.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Merge')),
        ],
      ),
    );
    if (ok != true) return;

    final result = await ref
        .read(checkInRepositoryProvider)
        .mergeCheckIns(into.id, keep.id);
    result.fold(
      (e) => ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Merge failed: $e'))),
      (_) {
        // Remove the absorbed node immediately so it can't be tapped while
        // the async reload is in-flight (tapping a deleted ID causes a 404).
        setState(() => _items.removeWhere((i) => i.id == keep.id));
        _reload();
      },
    );
  }

  Future<void> _deleteCheckIn(CheckIn ci) async {
    final item = _itemById(ci.id);
    if (item != null) await _deleteItem(item);
  }

  Future<void> _mergeNote(_TlItem note) async {
    // A note can merge into any other visible node — a check-in or another
    // note — appending its text to the target's body.
    final candidates = _items
        .where((i) =>
            i.id != note.id && (i.kind == _NodeKind.checkIn || i.isNote))
        .toList()
      ..sort((a, b) => a.time.compareTo(b.time));

    if (candidates.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nothing else today to merge into')),
        );
      }
      return;
    }

    String labelFor(_TlItem c) {
      if (!c.isNote) return c.name;
      final body = c.text?.trim() ?? '';
      if (body.isNotEmpty) return body;
      return c.isVoice ? 'Voice note' : 'Note';
    }

    final target = await showModalBottomSheet<_TlItem>(
      useRootNavigator: true,
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text('Merge note into…',
                  style: Theme.of(ctx).textTheme.titleMedium),
            ),
            const Divider(height: 1),
            // Scrolls when there are more candidates than fit the sheet,
            // instead of overflowing the Column.
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.only(bottom: 8),
                children: [
                  for (final c in candidates)
                    ListTile(
                      leading: Icon(c.isNote
                          ? (c.isVoice
                              ? Icons.mic_none
                              : Icons.sticky_note_2_outlined)
                          : Icons.pin_drop_outlined),
                      title: Text(labelFor(c),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(DateFormat('h:mm a').format(c.time)),
                      onTap: () => Navigator.pop(ctx, c),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    if (target == null || !mounted) return;

    final noteText = note.text?.trim() ?? '';
    final existing = target.text?.trim() ?? '';
    final merged = existing.isEmpty ? noteText : '$existing\n$noteText';

    final targetLabel =
        target.isNote ? (target.isVoice ? 'the voice note' : 'the note') : '"${target.name}"';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Merge note?'),
        content: Text(
            'This note\'s text will be added to $targetLabel and the note will be deleted.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Merge')),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    final noteRepo = ref.read(timelineNoteRepositoryProvider);
    if (target.isNote) {
      await noteRepo.update(target.id, merged);
    } else {
      await ref
          .read(checkInRepositoryProvider)
          .updateCheckIn(target.id, {'note': merged});
    }
    await noteRepo.delete(note.id);

    setState(() => _items.removeWhere((i) => i.id == note.id));
    _reload();
  }

  // Promote = open the stamp editor pre-filled from the check-in (note, photos,
  // place), so the user reviews/edits before it becomes a stamp.
  void _promote(BuildContext sheetCtx, CheckIn ci) {
    Navigator.pop(sheetCtx);
    context.push('/checkin?fromCheckIn=${ci.id}');
  }

  // ── Notes ─────────────────────────────────────────────────────
  // Written inline from the list footer — no modal. Time defaults to now on
  // today, noon on past days; reposition later by long-press drag.
  Future<void> _submitNote(String body) async {
    final text = body.trim();
    if (text.isEmpty) return;
    // Default to current wall-clock time on _day, but never before the last
    // check-in/stamp — notes must appear after visits in the timeline.
    final now = DateTime.now();
    var at = DateTime(_day.year, _day.month, _day.day, now.hour, now.minute, now.second);
    final isToday = _day.year == now.year && _day.month == now.month && _day.day == now.day;
    if (!isToday) {
      final nonNotes = _items.where((i) => !i.isNote);
      if (nonNotes.isNotEmpty && nonNotes.last.time.isAfter(at)) {
        at = nonNotes.last.time.add(const Duration(minutes: 1));
      }
    }
    await ref.read(timelineNoteRepositoryProvider).add(_day, text, at);
    _reload();
  }

  // Voice memo: open the recorder sheet, then upload the recording and save a
  // note whose body is the transcript. Treated as a note node (same placement
  // rules) but additionally carries a playable audio bar.
  Future<void> _addVoiceMemo() async {
    final result = await showModalBottomSheet<_VoiceMemoResult>(
      useRootNavigator: true,
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _VoiceRecorderSheet(),
    );
    if (result == null || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(const SnackBar(
        content: Text('Saving voice memo…'), duration: Duration(seconds: 1)));

    final service = VoiceMemoService();
    final audioUrl = await service.upload(result.file);
    if (audioUrl == null) {
      messenger.showSnackBar(
          const SnackBar(content: Text('Could not upload voice memo')));
      return;
    }

    final transcript = result.transcript.trim();
    final body = transcript.isEmpty ? '🎙 Voice memo' : transcript;

    final now = DateTime.now();
    var at = DateTime(_day.year, _day.month, _day.day, now.hour, now.minute, now.second);
    final isToday = _day.year == now.year && _day.month == now.month && _day.day == now.day;
    if (!isToday) {
      final nonNotes = _items.where((i) => !i.isNote);
      if (nonNotes.isNotEmpty && nonNotes.last.time.isAfter(at)) {
        at = nonNotes.last.time.add(const Duration(minutes: 1));
      }
    }
    await ref.read(timelineNoteRepositoryProvider).add(
          _day,
          body,
          at,
          audioUrl: audioUrl,
          audioDurationMs: result.durationMs,
        );
    _reload();
  }

  Future<void> _editDiary() async {
    final result = await showModalBottomSheet<String>(
      useRootNavigator: true,
      context: context,
      isScrollControlled: true,
      builder: (_) => _EditDiarySheet(initial: _diary, day: _day),
    );
    if (result == null) return;
    await ref.read(diaryRepositoryProvider).saveDiary(_day, result);
    _applyDiaryResult(result);
  }

  Future<void> _generateDiary() async {
    final bundle = _bundle;
    if (bundle == null || _isGeneratingDiary) return;
    setState(() => _isGeneratingDiary = true);

    try {
      // Build events sorted by time — skip auto check-ins (GPS noise).
      final events = <Map<String, dynamic>>[];
      for (final s in bundle.stamps) {
        events.add({
          'type': 'stamp',
          'time': _hhmm(s.visitedAt),
          'place': s.placeName,
          if (s.caption != null && s.caption!.isNotEmpty) 'caption': s.caption,
          if (s.sensoryTags.isNotEmpty) 'tags': s.sensoryTags,
          'photoUrls': s.photoUrls,
        });
      }
      for (final c in bundle.checkIns) {
        if (c.source != CheckInSource.auto) {
          // Manual check-in: include as a full event.
          events.add({
            'type': 'checkin',
            'time': _hhmm(c.visitedAt),
            'place': c.placeName,
            if (c.note != null && c.note!.isNotEmpty) 'note': c.note,
            'photoUrls': c.photoUrls,
          });
        } else {
          // Auto (GPS) check-in: skip entirely unless it has a note,
          // in which case surface the note text only (no place, no photos).
          final note = c.note?.trim() ?? '';
          if (note.isEmpty) continue;
          events.add({
            'type': 'note',
            'time': _hhmm(c.visitedAt),
            'note': note,
            'photoUrls': const <String>[],
          });
        }
      }
      for (final n in bundle.notes) {
        events.add({
          'type': 'note',
          'time': _hhmm(n.notedAt),
          'note': n.body,
          'photoUrls': const <String>[],
        });
      }
      events.sort((a, b) =>
          (a['time'] as String).compareTo(b['time'] as String));

      if (events.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Nothing to generate from yet')),
          );
        }
        return;
      }

      // Download + resize photos in memory (≤ 5 total, never stored).
      int photoCount = 0;
      for (final event in events) {
        final urls = (event.remove('photoUrls') as List).cast<String>();
        final b64s = <String>[];
        for (final url in urls) {
          if (photoCount >= 5) break;
          final b64 = await PhotoService.resizeForLlm(url);
          if (b64 != null) {
            b64s.add(b64);
            photoCount++;
          }
        }
        event['photos'] = b64s;
      }

      final diary = await ref
          .read(diaryRepositoryProvider)
          .generateDiary(_day, events);

      if (!mounted) return;

      // Pre-fill the edit sheet with the generated text; user saves or discards.
      final saved = await showModalBottomSheet<String>(
        useRootNavigator: true,
        context: context,
        isScrollControlled: true,
        builder: (_) => _EditDiarySheet(initial: diary, day: _day),
      );
      if (saved == null) return;
      await ref.read(diaryRepositoryProvider).saveDiary(_day, saved);
      _applyDiaryResult(saved);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Generation failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isGeneratingDiary = false);
    }
  }

  static String _hhmm(DateTime dt) => DateFormat('HH:mm').format(dt);



  @override
  Widget build(BuildContext context) {
    final state = ref.watch(timelineNotifierProvider);

    return Scaffold(
      backgroundColor: Z.surface0,
      body: Column(
        children: [
          // ── Header: date nav + week strip ─────────────────────────
          Container(
            color: Z.surface1,
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // Date nav row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: SizedBox(
                      height: 40,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Positioned(
                            left: 0,
                            child: Text('ZON',
                                style: GoogleFonts.poppins(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.5,
                                    color: Z.text)),
                          ),
                          // Center date display with chevron shifting buttons directly adjacent to it
                          Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              GestureDetector(
                                onTap: () => _shift(-1),
                                behavior: HitTestBehavior.opaque,
                                child: const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Icon(Icons.chevron_left, size: 22, color: Z.textMuted),
                                ),
                              ),
                              const SizedBox(width: 4),
                              GestureDetector(
                                onTap: _pickDate,
                                behavior: HitTestBehavior.opaque,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _isToday
                                          ? 'Today'
                                          : DateFormat('MMM d').format(_day),
                                      style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w700,
                                          color: Z.text),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.expand_more,
                                        size: 16, color: Z.textMuted),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 4),
                              GestureDetector(
                                onTap: _isToday ? null : () => _shift(1),
                                behavior: HitTestBehavior.opaque,
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Icon(
                                    Icons.chevron_right,
                                    size: 22,
                                    color: _isToday ? Z.textFaint : Z.textMuted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          // Right today button (always visible, disabled if already on today)
                          Positioned(
                            right: 0,
                            child: TextButton(
                              onPressed: _isToday ? null : _jumpToToday,
                              style: TextButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                foregroundColor: Z.brand,
                                disabledForegroundColor: Z.textFaint,
                              ),
                              child: const Text(
                                'Today',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Slidable Date strip
                  Container(
                    height: 44,
                    margin: const EdgeInsets.only(bottom: 4),
                    child: ListView.builder(
                      controller: _dateStripController,
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: _slidableDays.length,
                      itemBuilder: (ctx, idx) {
                        final d = _slidableDays[idx];
                        final isSelected = d.day == _day.day &&
                            d.month == _day.month &&
                            d.year == _day.year;
                        final dayLabel = DateFormat('E').format(d).substring(0, 3); // e.g. Mon, Tue
                        final dateKey = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
                        final count = _monthlyActivity[dateKey] ?? 0;
                        final hasNodes = count > 0;
                        final hasDiary = _diaryDays.contains(dateKey);
                        return SizedBox(
                          width: 64,
                          child: GestureDetector(
                            onTap: () => _load(d),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(vertical: 3),
                              decoration: BoxDecoration(
                                color: isSelected ? Z.brand : null,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    dayLabel,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      height: 0.9,
                                      color: isSelected
                                          ? Colors.white.withValues(alpha: 0.8)
                                          : hasNodes
                                              ? Z.textMuted
                                              : Z.textFaint,
                                    ),
                                  ),
                                  Text(
                                    '${d.day}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w400,
                                      height: 1.0,
                                      color: isSelected
                                          ? Colors.white
                                          : hasNodes
                                              ? Z.text
                                              : Z.textFaint,
                                    ),
                                  ),
                                  const SizedBox(height: 1),
                                  // Activity dot (indicates diary existence)
                                  SizedBox(
                                    height: 5,
                                    child: hasDiary
                                        ? Center(
                                            child: Container(
                                              width: 4,
                                              height: 4,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: isSelected ? Colors.white : const Color(_kCheckinBlue),
                                              ),
                                            ),
                                          )
                                        : null,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Scrollable body ─────────────────────────────────────────
          Expanded(
            child: state.when(
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

                return Column(
                  children: [
                    // ── Mini route map card ─────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Z.outline),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          children: [
                            SizedBox(
                              height: 188,
                              child: MapWidget(
                                key: const ValueKey('timeline-map'),
                                viewport: CameraViewportState(
                                  center: Point(
                                      coordinates: Position(
                                          126.9780, 37.5665)),
                                  zoom: 12.0,
                                ),
                                onMapCreated: (controller) {
                                  _map = controller;
                                  controller.addInteraction(
                                      TapInteraction.onMap(_onMapTap));
                                  if (_bundle != null) _redraw(_bundle!);
                                },
                              ),
                            ),
                            Container(
                              decoration: const BoxDecoration(
                                  border: Border(
                                      top: BorderSide(color: Z.outline))),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              child: Row(
                                children: [
                                  Text(
                                    DateFormat('MMM d').format(_day),
                                    style: const TextStyle(
                                        fontSize: 13, color: Z.textMuted),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '${_items.where((i) => i.isStamp).length} stamps',
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Z.brand),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 4),

                    // ── Timeline node list ──────────────────────────
                    Expanded(
                      child: CustomScrollView(
                        slivers: [
                          SliverReorderableList(
                            itemCount: _items.length,
                      onReorderItem: _onReorder,
                      itemBuilder: (ctx, i) {
                        final item = _items[i];
                        final isExpandable = !item.isStamp;
                        final isEditing = isExpandable && _expandedId == item.id;

                        Widget child = _TimelineNode(
                          item: item,
                          isFirst: i == 0,
                          isLast: i == _items.length - 1,
                          isSelected: _selectedId == item.id,
                          isExpanded: isEditing,
                          onTap: () => _onTapNode(item),
                          onLongPress: () => _onLongPressNode(item),
                          onMore: () => _moreCheckIn(item),
                          onPromote: item.kind == _NodeKind.checkIn
                              ? (item.isAuto
                                  ? () => context.push(
                                      '/checkin?lat=${item.lat}&lng=${item.lng}&time=${item.time.toIso8601String()}${item.text != null && item.text!.isNotEmpty ? '&note=${Uri.encodeComponent(item.text!)}' : ''}')
                                  : () => context.push(
                                      '/checkin?fromCheckIn=${item.id}'))
                              : null,
                          onAddPhotos: item.kind == _NodeKind.checkIn
                              ? () => _addPhotosInline(item)
                              : null,
                          onDeletePhoto: item.kind == _NodeKind.checkIn
                              ? (url) => _deletePhoto(url)
                              : null,
                          onChangeNoteTime: item.isNote
                              ? () => _changeNoteTime(item)
                              : null,
                          onDeleteItem: item.kind != _NodeKind.stamp
                              ? () => _deleteItem(item)
                              : null,
                          itemKey: _itemKeys[item.id],
                          onSaveText: (text) => _saveText(item, text),
                          trailing: item.isNote
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.merge_outlined,
                                          size: 20, color: Z.textMuted),
                                      tooltip: 'Merge into…',
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                                      constraints: const BoxConstraints(),
                                      onPressed: () => _mergeNote(item),
                                    ),
                                    ReorderableDragStartListener(
                                      index: i,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                        color: Colors.transparent,
                                        child: const Icon(Icons.drag_handle,
                                            size: 20, color: Z.textMuted),
                                      ),
                                    ),
                                  ],
                                )
                              : null,
                        );

                        if (!item.isStamp) {
                          child = Dismissible(
                            key: ValueKey('tl-${item.id}'),
                            direction: item.kind == _NodeKind.stamp
                                ? DismissDirection.none
                                : DismissDirection.endToStart,
                            background: Container(
                              color: Z.error,
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              child: const Icon(Icons.delete_outline,
                                  color: Colors.white, size: 24),
                            ),
                            confirmDismiss: (_) async {
                              await _deleteItem(item);
                              return false; // _reload handles UI update
                            },
                            child: child,
                          );
                        }

                        return KeyedSubtree(
                          key: ValueKey('tl-${item.id}'),
                          child: child,
                        );
                      },
                    ),

                    // ── Add note row ────────────────────────────────
                    SliverToBoxAdapter(
                      child: _AddNoteRow(
                        onSubmit: _submitNote,
                        onVoice: _addVoiceMemo,
                      ),
                    ),

                    // ── Divider ─────────────────────────────────────
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Divider(color: Z.outline),
                      ),
                    ),

                    // ── Diary card ──────────────────────────────────
                    SliverToBoxAdapter(
                      child: _DiaryCard(
                        diary: _diary,
                        generating: _isGeneratingDiary,
                        onGenerate: _generateDiary,
                        onEdit: _editDiary,
                      ),
                    ),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 32),
                    ),
                  ],
                ),
              ),
            ],
          );
              },
            ),
          ),
        ],
      ),
    );
  }
}



// ── Timeline node — zon-cards.jsx TimelineNode ────────────────────────────────
class _TimelineNode extends StatelessWidget {
  final _TlItem item;
  final bool isFirst;
  final bool isLast;
  final bool isSelected;
  final bool isExpanded;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onMore;
  final VoidCallback? onPromote;
  final VoidCallback? onAddPhotos;
  final void Function(String url)? onDeletePhoto;
  final VoidCallback? onChangeNoteTime;
  final VoidCallback? onDeleteItem;
  final Widget? trailing;
  final GlobalKey? itemKey;
  final Future<void> Function(String) onSaveText;

  const _TimelineNode({
    required this.item,
    required this.isFirst,
    required this.isLast,
    required this.isSelected,
    required this.isExpanded,
    required this.onTap,
    required this.onLongPress,
    required this.onMore,
    this.onPromote,
    this.onAddPhotos,
    this.onDeletePhoto,
    this.onChangeNoteTime,
    this.onDeleteItem,
    this.trailing,
    this.itemKey,
    required this.onSaveText,
  });

  static const _kindMeta = {
    'checkin': (
      color: Z.checkin,
      soft: Z.checkinSoft,
      icon: Icons.location_on,
      label: 'Check-in'
    ),
    'stamp': (
      color: Z.brand,
      soft: Z.brandSoft,
      icon: Icons.workspace_premium,
      label: 'Stamp'
    ),
    'note': (
      color: Z.note,
      soft: Z.noteSoft,
      icon: Icons.edit_note,
      label: 'Note'
    ),
    'voice': (
      color: Z.note,
      soft: Z.noteSoft,
      icon: Icons.mic,
      label: 'Voice'
    ),
    'auto': (
      color: Z.auto,
      soft: Color(0x1F9CA3AF),
      icon: Icons.radio_button_unchecked,
      label: 'Auto'
    ),
  };

  @override
  Widget build(BuildContext context) {
    final kindKey = item.isAuto
        ? 'auto'
        : item.kind == _NodeKind.stamp
            ? 'stamp'
            : item.kind == _NodeKind.note
                ? (item.isVoice ? 'voice' : 'note')
                : 'checkin';
    final meta = _kindMeta[kindKey]!;
    final isNote = item.kind == _NodeKind.note;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        color: isSelected ? Z.brandSoft : Colors.transparent,
        child: Stack(
          children: [
            if (!isFirst)
              Positioned(
                top: 0,
                height: 14,
                left: 25,
                child: Container(
                  width: 2,
                  color: Z.outline,
                ),
              ),
            if (!isLast)
              Positioned(
                top: 42,
                bottom: 0,
                left: 25,
                child: Container(
                  width: 2,
                  color: Z.outline,
                ),
              ),
            Row(
              key: itemKey,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left rail — 52px wide
                SizedBox(
                  width: 52,
                  child: Column(
                    children: [
                      const SizedBox(height: 14),
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: meta.soft,
                          shape: BoxShape.circle,
                          border: Border.all(color: meta.color, width: 2),
                        ),
                        child: Icon(meta.icon, size: 14, color: meta.color),
                      ),
                    ],
                  ),
                ),
            // Content
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.fromLTRB(0, 12, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Time + KindChip
                    Row(
                      children: [
                        Text(DateFormat('H:mm').format(item.time),
                            style: const TextStyle(
                                fontSize: 12,
                                color: Z.textMuted,
                                fontWeight: FontWeight.w500)),
                        const SizedBox(width: 8),
                        _KindChip(kindKey, meta.color, meta.soft, meta.label),
                        if (trailing != null) ...[
                          const Spacer(),
                          trailing!,
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Place name
                    if (!isNote && item.name.isNotEmpty)
                      Text(item.name,
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Z.text)),
                    // Inline editor or static note text body
                    // Inline editor or static note text body
                    if (isExpanded) ...[
                      const SizedBox(height: 6),
                      _InlineNodeEditor(
                        item: item,
                        onSave: onSaveText,
                        onChangeTime: item.isNote ? onChangeNoteTime : null,
                        onMore: onMore,
                        onPromote: onPromote,
                        onAddPhotos: onAddPhotos,
                        onDeletePhoto: onDeletePhoto,
                      ),
                    ] else ...[
                      if (item.text != null && item.text!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(item.text!,
                            style: TextStyle(
                                fontSize: 14,
                                color:
                                    isNote ? Z.note : Z.textMuted,
                                height: 1.55,
                                fontStyle: isNote
                                    ? FontStyle.italic
                                    : FontStyle.normal)),
                      ],
                      // Playable voice-memo bar
                      if (item.isVoice) ...[
                        const SizedBox(height: 8),
                        _VoiceBar(
                          url: item.audioUrl!,
                          durationMs: item.audioDurationMs,
                          color: meta.color,
                        ),
                      ],
                      // Photo thumbs (regular grid when not editing)
                      if (item.photoUrls.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: item.photoUrls
                              .take(3)
                              .map((url) => Container(
                                    width: 60,
                                    height: 60,
                                    margin:
                                        const EdgeInsets.only(right: 6),
                                    decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(8),
                                        color: Z.surface2),
                                    clipBehavior: Clip.antiAlias,
                                    child: url.isNotEmpty
                                        ? CachedNetworkImage(
                                            imageUrl: url,
                                            fit: BoxFit.cover)
                                      : null,
                                  ))
                              .toList(),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  ),
);
  }
}

// ── KindChip ──────────────────────────────────────────────────────────────────
class _KindChip extends StatelessWidget {
  final String kind;
  final Color color;
  final Color soft;
  final String label;
  const _KindChip(this.kind, this.color, this.soft, this.label);
  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
        decoration: BoxDecoration(color: soft, borderRadius: BorderRadius.circular(9999)),
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.3),
        ),
      );
}

// ── Inline Node Editor ────────────────────────────────────────────────────────
class _InlineNodeEditor extends StatefulWidget {
  final _TlItem item;
  final void Function(String text) onSave;
  final VoidCallback? onChangeTime; // note only
  final VoidCallback? onMore;
  final VoidCallback? onPromote;
  final VoidCallback? onAddPhotos;
  final void Function(String url)? onDeletePhoto;

  const _InlineNodeEditor({
    required this.item,
    required this.onSave,
    this.onChangeTime,
    this.onMore,
    this.onPromote,
    this.onAddPhotos,
    this.onDeletePhoto,
  });

  @override
  State<_InlineNodeEditor> createState() => _InlineNodeEditorState();
}

class _InlineNodeEditorState extends State<_InlineNodeEditor> {
  late final TextEditingController _ctrl =
      TextEditingController(text: widget.item.text ?? '');

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasPhotos = widget.item.photoUrls.isNotEmpty ||
        (widget.item.kind == _NodeKind.checkIn && widget.onAddPhotos != null);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _ctrl,
            autofocus: false,
            minLines: 1,
            maxLines: 4,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => widget.onSave(_ctrl.text.trim()),
            style: const TextStyle(fontSize: 14, color: Z.text),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: Z.surface1,
              hintText: widget.item.isNote ? 'Edit note…' : 'Add a note…',
              hintStyle: const TextStyle(color: Z.textMuted),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Z.outline, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Z.brand, width: 1.5),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          if (hasPhotos) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 64,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final url in widget.item.photoUrls)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Stack(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: Z.surface2,
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: CachedNetworkImage(
                              imageUrl: url,
                              fit: BoxFit.cover,
                            ),
                          ),
                          if (widget.onDeletePhoto != null)
                            Positioned(
                              top: 2,
                              right: 2,
                              child: GestureDetector(
                                onTap: () => widget.onDeletePhoto!(url),
                                child: const CircleAvatar(
                                  radius: 10,
                                  backgroundColor: Colors.black54,
                                  child: Icon(
                                    Icons.close,
                                    size: 12,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  if (widget.onAddPhotos != null)
                    GestureDetector(
                      onTap: widget.onAddPhotos,
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          border: Border.all(color: Z.outline2, width: 1.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.add_a_photo_outlined,
                          color: Z.textMuted,
                          size: 20,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              if (widget.onChangeTime != null) ...[
                const Icon(Icons.schedule_outlined, size: 16, color: Z.textMuted),
                const SizedBox(width: 4),
                Text(
                  DateFormat('h:mm a').format(widget.item.time),
                  style: const TextStyle(color: Z.textMuted, fontSize: 12, fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 4),
                TextButton(
                  onPressed: widget.onChangeTime,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: ui.Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    foregroundColor: Z.brand,
                  ),
                  child: const Text('Change time', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ],
              if (widget.item.kind == _NodeKind.checkIn) ...[
                if (!widget.item.isAuto && widget.onMore != null)
                  TextButton.icon(
                    onPressed: widget.onMore,
                    icon: const Icon(Icons.more_horiz_outlined, size: 16),
                    label: const Text('More'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: ui.Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      foregroundColor: Z.brand,
                    ),
                  ),
                if (!widget.item.isAuto && widget.onMore != null && widget.onPromote != null)
                  const SizedBox(width: 8),
                if (widget.onPromote != null)
                  GestureDetector(
                    onTap: widget.onPromote,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Z.brandSoft,
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      child: Text(
                        widget.item.isAuto ? 'Promote to check-in →' : 'Promote to stamp →',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Z.brand,
                        ),
                      ),
                    ),
                  ),
              ],
              const Spacer(),
              ElevatedButton(
                onPressed: () => widget.onSave(_ctrl.text.trim()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Z.brand,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  minimumSize: ui.Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text('Done', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Add note row ──────────────────────────────────────────────────────────────
class _AddNoteRow extends StatefulWidget {
  final Future<void> Function(String) onSubmit;
  final VoidCallback onVoice;
  const _AddNoteRow({required this.onSubmit, required this.onVoice});
  @override
  State<_AddNoteRow> createState() => _AddNoteRowState();
}

class _AddNoteRowState extends State<_AddNoteRow> {
  bool _active = false;
  final _ctrl = TextEditingController();
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: !_active
          ? Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _active = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 11),
                      decoration: BoxDecoration(
                        color: Z.surface2,
                        borderRadius: Z.r12,
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.add, size: 18, color: Z.textMuted),
                          const SizedBox(width: 8),
                          Text(
                            'Add a note',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Z.textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Voice memo — record speech, transcribe + attach a playable bar.
                GestureDetector(
                  onTap: widget.onVoice,
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Z.brandSoft,
                      shape: BoxShape.circle,
                      border: Border.all(color: Z.brand, width: 1.5),
                    ),
                    child: const Icon(Icons.mic, size: 20, color: Z.brand),
                  ),
                ),
              ],
            )
          : Container(
              decoration: BoxDecoration(
                color: Z.surface1,
                border: Border.all(color: Z.brand, width: 1.5),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                children: [
                  TextField(
                    controller: _ctrl,
                    autofocus: true,
                    maxLines: null,
                    minLines: 3,
                    style: const TextStyle(fontSize: 14, color: Z.text, height: 1.5),
                    decoration: const InputDecoration(
                      hintText: "What's on your mind?",
                      hintStyle: TextStyle(color: Z.textFaint),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: () {
                          _ctrl.clear();
                          setState(() => _active = false);
                        },
                        child: Container(
                          height: 32,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                              border: Border.all(color: Z.outline2),
                              borderRadius: BorderRadius.circular(9999)),
                          alignment: Alignment.center,
                          child: const Text('Cancel',
                              style: TextStyle(
                                  fontSize: 13, color: Z.textMuted)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () async {
                          final text = _ctrl.text.trim();
                          if (text.isEmpty) return;
                          _ctrl.clear();
                          setState(() => _active = false);
                          await widget.onSubmit(text);
                        },
                        child: Container(
                          height: 32,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                              color: Z.brand,
                              borderRadius: BorderRadius.circular(9999)),
                          alignment: Alignment.center,
                          child: const Text('Save',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}

// ── Diary card ────────────────────────────────────────────────────────────────
class _DiaryCard extends StatelessWidget {
  final String diary;
  final bool generating;
  final VoidCallback onGenerate;
  final VoidCallback onEdit;
  const _DiaryCard({
    required this.diary,
    required this.generating,
    required this.onGenerate,
    required this.onEdit,
  });
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: Z.surface1,
          border: Border.all(color: Z.outline),
          borderRadius: Z.r16,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Container(
              decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Z.outline))),
              padding: const EdgeInsets.fromLTRB(16, 14, 14, 12),
              child: Row(
                children: [
                  const Icon(Icons.menu_book, size: 20, color: Z.brand),
                  const SizedBox(width: 8),
                  Text('Diary',
                      style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Z.text)),
                  const Spacer(),
                  if (diary.isNotEmpty) ...[
                    GestureDetector(
                      onTap: onEdit,
                      child: Container(
                        height: 30,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                            border: Border.all(color: Z.outline2),
                            borderRadius: BorderRadius.circular(9999)),
                        alignment: Alignment.center,
                        child: Text('Edit',
                            style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Z.textMuted)),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  GestureDetector(
                    onTap: diary.isNotEmpty || generating ? null : onGenerate,
                    child: AnimatedOpacity(
                      opacity: generating ? 0.7 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      child: Container(
                        height: 30,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                            color: diary.isNotEmpty ? Z.surface2 : Z.brand,
                            borderRadius: BorderRadius.circular(9999)),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.auto_awesome,
                                size: 14,
                                color: diary.isNotEmpty
                                    ? Z.textMuted
                                    : Colors.white),
                            const SizedBox(width: 5),
                            Text(
                              generating
                                  ? 'Writing…'
                                  : diary.isNotEmpty
                                      ? 'Generated'
                                      : 'Generate',
                              style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: diary.isNotEmpty
                                      ? Z.textMuted
                                      : Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Body
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: generating
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [100, 88, 72, 55]
                          .map((w) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Container(
                                  height: 14,
                                  width: MediaQuery.of(context).size.width *
                                      w /
                                      100,
                                  decoration: BoxDecoration(
                                      color: Z.surface2,
                                      borderRadius:
                                          BorderRadius.circular(7)),
                                ),
                              ))
                          .toList(),
                    )
                  : diary.isNotEmpty
                      ? Text(diary,
                          style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Z.text,
                              height: 1.7,
                              fontStyle: FontStyle.italic))
                      : Text(
                          'How was your day? Tap Generate to write your diary with AI.',
                          style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Z.textMuted,
                              height: 1.6,
                              fontStyle: FontStyle.italic)),
            ),
          ],
        ),
      ),
    );
  }
}


class _CheckInEdit {
  final String place;
  final String note;
  final Set<String> removedPhotoIds;
  final List<String> newPaths;
  final bool isPublic;
  const _CheckInEdit(
      this.place, this.note, this.removedPhotoIds, this.newPaths, this.isPublic);
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
  late bool _isPublic =
      widget.checkIn.visibility == StampVisibility.public;

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
            PlaceSearchField(
              controller: _place,
              lat: widget.checkIn.lat,
              lng: widget.checkIn.lng,
              labelText: 'Place name',
              onChanged: (_) => setState(() {}),
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
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Share as a story'),
              subtitle: const Text(
                  'Public for 24h in your followers’ feed. Off = private.'),
              value: _isPublic,
              onChanged: (v) => setState(() => _isPublic = v),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _place.text.trim().isEmpty
                    ? null
                    : () => Navigator.pop(
                        context,
                        _CheckInEdit(_place.text.trim(), _note.text.trim(),
                            _removed, _newPaths, _isPublic)),
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
  final VoidCallback onMerge;
  final VoidCallback? onViewStamp;
  const _CheckInDetailSheet({
    required this.checkIn,
    required this.onPromote,
    required this.onEdit,
    required this.onDelete,
    required this.onMerge,
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
                    icon: const Icon(Icons.merge_outlined),
                    tooltip: 'Merge into…',
                    onPressed: onMerge),
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
                      crossAxisCount: 7, childAspectRatio: 1.0),
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

// ── Voice memo: playable bar ──────────────────────────────────────────────────
/// Compact audio player rendered beneath a voice-memo transcript. Tap to
/// play/pause; a thin progress track fills as it plays.
class _VoiceBar extends StatefulWidget {
  final String url;
  final int? durationMs;
  final Color color;
  const _VoiceBar({required this.url, this.durationMs, required this.color});
  @override
  State<_VoiceBar> createState() => _VoiceBarState();
}

class _VoiceBarState extends State<_VoiceBar> {
  final _player = AudioPlayer();
  StreamSubscription<Duration>? _posSub;
  StreamSubscription<PlayerState>? _stateSub;
  StreamSubscription<Duration>? _durSub;
  StreamSubscription<void>? _completeSub;
  Duration _pos = Duration.zero;
  Duration _dur = Duration.zero;
  bool _playing = false;

  @override
  void initState() {
    super.initState();
    if (widget.durationMs != null) {
      _dur = Duration(milliseconds: widget.durationMs!);
    }
    _stateSub = _player.onPlayerStateChanged.listen((s) {
      if (mounted) setState(() => _playing = s == PlayerState.playing);
    });
    _posSub = _player.onPositionChanged.listen((p) {
      if (mounted) setState(() => _pos = p);
    });
    _durSub = _player.onDurationChanged.listen((d) {
      if (mounted && d > Duration.zero) setState(() => _dur = d);
    });
    _completeSub = _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _pos = Duration.zero);
    });
  }

  @override
  void dispose() {
    _completeSub?.cancel();
    _posSub?.cancel();
    _stateSub?.cancel();
    _durSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_playing) {
      await _player.pause();
    } else {
      await _player.play(UrlSource(widget.url));
    }
  }

  String _fmt(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final total = _dur.inMilliseconds == 0 ? 1 : _dur.inMilliseconds;
    final progress = (_pos.inMilliseconds / total).clamp(0.0, 1.0);
    return GestureDetector(
      onTap: _toggle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: widget.color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: widget.color.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Icon(_playing ? Icons.pause_circle_filled : Icons.play_circle_fill,
                size: 28, color: widget.color),
            const SizedBox(width: 10),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 4,
                  backgroundColor: widget.color.withValues(alpha: 0.18),
                  valueColor: AlwaysStoppedAnimation(widget.color),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              _dur == Duration.zero ? '0:00' : _fmt(_playing ? _pos : _dur),
              style: TextStyle(
                  fontSize: 12,
                  color: widget.color,
                  fontWeight: FontWeight.w600,
                  fontFeatures: const [ui.FontFeature.tabularFigures()]),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Voice memo: recorder sheet ────────────────────────────────────────────────
/// Result handed back from [_VoiceRecorderSheet]: the local recording, its
/// transcript, and duration.
class _VoiceMemoResult {
  final File file;
  final String transcript;
  final int durationMs;
  const _VoiceMemoResult(this.file, this.transcript, this.durationMs);
}

/// Modal recorder: tap to start, live timer + amplitude pulse, stop to
/// transcribe. Pops a [_VoiceMemoResult] on success.
class _VoiceRecorderSheet extends StatefulWidget {
  const _VoiceRecorderSheet();
  @override
  State<_VoiceRecorderSheet> createState() => _VoiceRecorderSheetState();
}

enum _RecPhase { idle, recording, transcribing }

class _VoiceRecorderSheetState extends State<_VoiceRecorderSheet> {
  final _service = VoiceMemoService();
  _RecPhase _phase = _RecPhase.idle;
  Timer? _ticker;
  StreamSubscription<Amplitude>? _ampSub;
  Duration _elapsed = Duration.zero;
  double _level = 0; // 0..1 normalized amplitude
  String? _error;

  @override
  void dispose() {
    _ticker?.cancel();
    _ampSub?.cancel();
    _service.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    final ok = await _service.start();
    if (!ok) {
      setState(() => _error = 'Microphone permission denied');
      return;
    }
    _elapsed = Duration.zero;
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsed += const Duration(seconds: 1));
    });
    _ampSub = _service.amplitudeStream().listen((amp) {
      // dBFS (~-60 quiet .. 0 loud) → 0..1
      final norm = ((amp.current + 60) / 60).clamp(0.0, 1.0);
      if (mounted) setState(() => _level = norm);
    });
    setState(() => _phase = _RecPhase.recording);
  }

  Future<void> _stop() async {
    _ticker?.cancel();
    _ampSub?.cancel();
    final durationMs = _elapsed.inMilliseconds;
    setState(() => _phase = _RecPhase.transcribing);
    final file = await _service.stop();
    if (file == null) {
      if (mounted) {
        setState(() {
          _phase = _RecPhase.idle;
          _error = 'Recording too short';
        });
      }
      return;
    }
    final transcript = await _service.transcribe(file);
    if (!mounted) return;
    Navigator.pop(
      context,
      _VoiceMemoResult(file, transcript, durationMs),
    );
  }

  Future<void> _cancel() async {
    await _service.cancel();
    if (mounted) Navigator.pop(context);
  }

  String _fmt(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          24, 20, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: Z.surface1,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
                color: Z.outline, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 20),
          Text(
            _phase == _RecPhase.transcribing
                ? 'Transcribing…'
                : _phase == _RecPhase.recording
                    ? 'Recording'
                    : 'Voice memo',
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700, color: Z.text),
          ),
          const SizedBox(height: 24),
          if (_phase == _RecPhase.transcribing)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: CircularProgressIndicator(color: Z.brand),
            )
          else
            // Mic button — pulses with input level while recording.
            GestureDetector(
              onTap: _phase == _RecPhase.recording ? _stop : _start,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 88 + (_phase == _RecPhase.recording ? _level * 28 : 0),
                height: 88 + (_phase == _RecPhase.recording ? _level * 28 : 0),
                decoration: BoxDecoration(
                  color: _phase == _RecPhase.recording
                      ? Z.error.withValues(alpha: 0.12)
                      : Z.brandSoft,
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: _phase == _RecPhase.recording ? Z.error : Z.brand,
                      width: 2),
                ),
                child: Icon(
                  _phase == _RecPhase.recording ? Icons.stop : Icons.mic,
                  size: 36,
                  color: _phase == _RecPhase.recording ? Z.error : Z.brand,
                ),
              ),
            ),
          const SizedBox(height: 20),
          Text(
            _phase == _RecPhase.transcribing
                ? 'Converting your speech to text'
                : _phase == _RecPhase.recording
                    ? _fmt(_elapsed)
                    : 'Tap to start recording',
            style: TextStyle(
                fontSize: _phase == _RecPhase.recording ? 22 : 14,
                fontWeight: _phase == _RecPhase.recording
                    ? FontWeight.w700
                    : FontWeight.w400,
                color: _phase == _RecPhase.recording ? Z.text : Z.textMuted,
                fontFeatures: const [ui.FontFeature.tabularFigures()]),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!,
                style: const TextStyle(fontSize: 13, color: Z.error)),
          ],
          const SizedBox(height: 20),
          if (_phase != _RecPhase.transcribing)
            TextButton(
              onPressed: _cancel,
              child: const Text('Cancel',
                  style: TextStyle(color: Z.textMuted)),
            ),
        ],
      ),
    );
  }
}
