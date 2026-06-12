import 'dart:math' as math;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Size;
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/places/place_models.dart';
import '../../../core/places/place_service_provider.dart';
import '../../../data/models/stamp.dart';
import '../../../data/repositories/stamp_repository.dart';
import '../../../data/repositories/saved_places_repository.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_states.dart';
import '../../../shared/widgets/mini_map.dart';
import '../../../shared/widgets/full_screen_image_viewer.dart';
import '../../feed/presentation/feed_screen.dart' show StampCard;

/// Place detail — v3: a Naver Map-style collapsible sheet over a full-bleed
/// map. Three snap states: collapsed (name strip), default (actions visible)
/// and full (whole page). The place pin floats above the sheet edge.
class PlaceDetailScreen extends ConsumerStatefulWidget {
  final String placeId;
  const PlaceDetailScreen({super.key, required this.placeId});

  @override
  ConsumerState<PlaceDetailScreen> createState() => _PlaceDetailScreenState();
}

class _PlaceDetailScreenState extends ConsumerState<PlaceDetailScreen> {
  // Snap fractions ≈ collapsed 110 / default 330 / full 778 of an 844 screen.
  static const List<double> _snap = [0.13, 0.39, 0.92];

  List<Stamp> _allStamps = [];
  List<Stamp> _friendStamps = [];
  PlaceResult? _placeDetail;
  bool _isSaved = false;
  bool _savingToggle = false;
  bool _loading = true;
  String? _error;
  bool _showFriendsOnly = false;

  // Derived after load
  List<({String tag, int count})> _vibes = [];
  List<Stamp> _friendVisitors = [];
  int _uniqueVisitors = 0;
  DateTime? _lastVisit;
  String _placeName = '';
  double _lat = 0;
  double _lng = 0;
  String? _externalSource;

  // Sheet state
  double _sheetExtent = 0.39;
  String _tab = 'overview';
  final DraggableScrollableController _sheetCtrl =
      DraggableScrollableController();

  // Map + coordinate-anchored pin position (screen px of the place).
  MapboxMap? _map;
  final ValueNotifier<Offset?> _pinPos = ValueNotifier(null);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _sheetCtrl.dispose();
    _pinPos.dispose();
    super.dispose();
  }

  Future<void> _updatePinPos() async {
    final map = _map;
    if (map == null || _lat == 0) return;
    try {
      final sc = await map.pixelForCoordinate(
        Point(coordinates: Position(_lng, _lat)),
      );
      if (mounted) _pinPos.value = Offset(sc.x, sc.y);
    } catch (_) {/* camera not ready */}
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final stampRepo = ref.read(stampRepositoryProvider);
      final savedRepo = ref.read(savedPlacesRepositoryProvider);

      final (allRes, friendRes, saved) = await (
        stampRepo.getStampsForPlace(widget.placeId),
        stampRepo.getFriendStampsForPlace(widget.placeId),
        savedRepo.isSaved(widget.placeId),
      ).wait;

      if (!mounted) return;

      final all = allRes.getOrElse((_) => []);
      final friends = friendRes.getOrElse((_) => []);

      final vibes = _computeVibes(all);
      final friendVisitors = _computeFriendVisitors(friends);
      final uniqueVisitors = {for (final s in all) s.userId}.length;
      final lastVisit = all.isEmpty
          ? null
          : all
              .reduce((a, b) => a.visitedAt.isAfter(b.visitedAt) ? a : b)
              .visitedAt;

      final firstName = all.isNotEmpty ? all.first.placeName : widget.placeId;
      final firstLat = all.isNotEmpty ? all.first.lat : 0.0;
      final firstLng = all.isNotEmpty ? all.first.lng : 0.0;
      final firstSource = all.isNotEmpty ? all.first.externalSource : null;

      setState(() {
        _allStamps = all;
        _friendStamps = friends;
        _vibes = vibes;
        _friendVisitors = friendVisitors;
        _uniqueVisitors = uniqueVisitors;
        _lastVisit = lastVisit;
        _isSaved = saved;
        _placeName = firstName;
        _lat = firstLat;
        _lng = firstLng;
        _externalSource = firstSource;
        _loading = false;
      });

      if (firstLat != 0 && firstLng != 0) {
        _fetchPlaceDetail(firstName, firstLat, firstLng);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _fetchPlaceDetail(String name, double lat, double lng) async {
    try {
      final svc = ref.read(placeServiceForProvider(lat, lng));
      final detail = await svc.getDetail(widget.placeId, name, lat, lng);
      if (mounted && detail != null) setState(() => _placeDetail = detail);
    } catch (e) {
      debugPrint('[PlaceDetail] detail fetch failed: $e');
    }
  }

  Future<void> _toggleSave() async {
    if (_savingToggle) return;
    setState(() => _savingToggle = true);
    final repo = ref.read(savedPlacesRepositoryProvider);
    if (_isSaved) {
      await repo.unsave(widget.placeId);
    } else {
      await repo.save(
        placeId: widget.placeId,
        name: _placeName,
        lat: _lat,
        lng: _lng,
        externalSource: _externalSource,
      );
    }
    if (mounted) {
      setState(() {
        _isSaved = !_isSaved;
        _savingToggle = false;
      });
    }
  }

  List<({String tag, int count})> _computeVibes(List<Stamp> stamps) {
    final counts = <String, int>{};
    for (final s in stamps) {
      for (final t in s.sensoryTags) {
        counts[t] = (counts[t] ?? 0) + 1;
      }
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(8).map((e) => (tag: e.key, count: e.value)).toList();
  }

  List<Stamp> _computeFriendVisitors(List<Stamp> friendStamps) {
    final seen = <String>{};
    final result = <Stamp>[];
    for (final s in friendStamps) {
      if (seen.add(s.userId)) result.add(s);
    }
    return result;
  }

  List<Stamp> get _displayedStamps =>
      _showFriendsOnly ? _friendStamps : _allStamps;

  List<String> get _allPhotos =>
      [for (final s in _allStamps) ...s.photoUrls].toList();

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _cycleSheet() {
    final e = _sheetExtent;
    final target = e < _snap[0] + 0.06
        ? _snap[1]
        : e < _snap[1] + 0.06
            ? _snap[2]
            : _snap[1];
    _sheetCtrl.animateTo(target,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic);
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: LoadingView());
    if (_error != null) {
      return Scaffold(body: ErrorView(message: _error!, onRetry: _load));
    }

    final detail = _placeDetail;
    final address = detail?.address;
    final phone = detail?.phone;
    final website = detail?.website;
    final isOpenNow = detail?.isOpenNow;
    final categories = detail?.categories ?? [];
    final categoryLabel = categories.isNotEmpty
        ? categories.last.split(' > ').last
        : _externalSource?.replaceAll('_', ' ');

    final topPad = MediaQuery.of(context).padding.top;
    final isCollapsed = _sheetExtent < 0.25;
    final isFull = _sheetExtent > 0.8;

    return Scaffold(
      backgroundColor: Z.surface0,
      body: Stack(
        children: [
          // Full-bleed, interactive map background.
          Positioned.fill(
            child: _lat != 0
                ? MiniMap(
                    lat: _lat,
                    lng: _lng,
                    zoom: 16.0,
                    interactive: true,
                    onMapReady: (m) {
                      _map = m;
                      _updatePinPos();
                      WidgetsBinding.instance
                          .addPostFrameCallback((_) => _updatePinPos());
                    },
                    onCameraChanged: (_) => _updatePinPos(),
                  )
                : const ColoredBox(color: Z.surface2),
          ),

          // Place pin — anchored to the place coordinate (pans/zooms with the
          // map). Hidden once the sheet is (nearly) full.
          if (_lat != 0 && !isFull)
            ValueListenableBuilder<Offset?>(
              valueListenable: _pinPos,
              builder: (ctx, pos, _) {
                if (pos == null) return const SizedBox.shrink();
                return Positioned(
                  left: pos.dx - 21,
                  top: pos.dy - 50,
                  child: IgnorePointer(child: _teardropPin()),
                );
              },
            ),

          // Floating map controls (hidden when full)
          if (!isFull)
            Positioned(
              top: topPad + 6,
              left: 12,
              right: 12,
              child: Row(
                children: [
                  _RoundBtn(
                      icon: Icons.arrow_back,
                      onTap: () => context.pop()),
                  const Spacer(),
                  _RoundBtn(
                    icon: _isSaved ? Icons.bookmark : Icons.bookmark_border,
                    color: _isSaved ? Z.brand : Z.text,
                    loading: _savingToggle,
                    onTap: _toggleSave,
                  ),
                  const SizedBox(width: 8),
                  _RoundBtn(icon: Icons.close, onTap: () => context.pop()),
                ],
              ),
            ),

          // Collapsible sheet
          NotificationListener<DraggableScrollableNotification>(
            onNotification: (n) {
              if (n.extent != _sheetExtent) {
                setState(() => _sheetExtent = n.extent);
              }
              return false;
            },
            child: DraggableScrollableSheet(
              controller: _sheetCtrl,
              initialChildSize: 0.39,
              minChildSize: 0.13,
              maxChildSize: 0.92,
              snap: true,
              snapSizes: _snap,
              builder: (ctx, scrollCtrl) => Container(
                decoration: BoxDecoration(
                  color: Z.surface1,
                  borderRadius: isFull
                      ? null
                      : const BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: const [
                    BoxShadow(
                        color: Color(0x1A000000),
                        blurRadius: 24,
                        offset: Offset(0, -4)),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: _sheetBody(scrollCtrl, isCollapsed, isFull,
                    address, phone, website, categoryLabel, isOpenNow),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sheetBody(
    ScrollController scrollCtrl,
    bool isCollapsed,
    bool isFull,
    String? address,
    String? phone,
    String? website,
    String? categoryLabel,
    bool? isOpenNow,
  ) {
    final photos = _allPhotos;
    return ListView(
      controller: scrollCtrl,
      padding: EdgeInsets.zero,
      children: [
        // Full-state top bar (the sheet sits just below the status bar at
        // 0.92, so no extra safe-area padding is needed here).
        if (isFull)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                _BarBtn(
                    icon: Icons.keyboard_arrow_down,
                    onTap: () => _sheetCtrl.animateTo(_snap[1],
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic)),
                const Spacer(),
                _BarBtn(
                    icon: _isSaved ? Icons.bookmark : Icons.bookmark_border,
                    color: _isSaved ? Z.brand : Z.text,
                    onTap: _toggleSave),
                _BarBtn(icon: Icons.close, onTap: () => context.pop()),
              ],
            ),
          ),

        // Drag handle (drag to resize, tap to cycle)
        GestureDetector(
          onTap: _cycleSheet,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 10, 0, 6),
            child: Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                    color: Z.outline2, borderRadius: BorderRadius.circular(2)),
              ),
            ),
          ),
        ),

        // Identity
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 2, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _placeName,
                maxLines: isCollapsed ? 1 : 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                    color: Z.text,
                    height: 1.2),
              ),
              if (!isCollapsed) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (categoryLabel != null) ...[
                      Flexible(
                        child: Text(categoryLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 13, color: Z.textMuted)),
                      ),
                      const Text(' · ',
                          style: TextStyle(fontSize: 13, color: Z.textMuted)),
                    ],
                    Text('${_allStamps.length} stamps',
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Z.brand)),
                    if (isOpenNow != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isOpenNow ? Z.success : Z.error,
                          borderRadius: Z.rFull,
                        ),
                        child: Text(isOpenNow ? 'Open' : 'Closed',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 14),
                // Action row
                Row(
                  children: [
                    _PillBtn(
                      label: 'Go',
                      icon: Icons.near_me,
                      onTap: _lat != 0
                          ? () => _launch(
                              'https://www.google.com/maps/dir/?api=1&destination=$_lat,$_lng')
                          : null,
                    ),
                    const SizedBox(width: 8),
                    _PillBtn(
                      label: 'Check in',
                      icon: Icons.location_on,
                      filled: true,
                      onTap: () {
                        final buf = StringBuffer('/checkin?mode=checkin');
                        if (_lat != 0) buf.write('&lat=$_lat&lng=$_lng');
                        context.push(buf.toString());
                      },
                    ),
                    const SizedBox(width: 8),
                    _PillBtn(
                      icon: Icons.ios_share,
                      onTap: website != null
                          ? () => _launch(website.startsWith('http')
                              ? website
                              : 'https://$website')
                          : null,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),

        if (!isCollapsed) ...[
          const SizedBox(height: 14),
          const Divider(height: 0.5, color: Z.outline),
          // Tabs
          _tabBar(),
          const Divider(height: 0.5, color: Z.outline),
          if (_tab == 'overview')
            ..._overview(address, phone, website, photos)
          else if (_tab == 'stamps')
            ..._stampsTab()
          else
            _photosTab(photos),
        ],
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _tabBar() {
    Widget tab(String id, String label) {
      final active = _tab == id;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _tab = id),
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                    color: active ? Z.text : Colors.transparent, width: 2),
              ),
            ),
            alignment: Alignment.center,
            child: Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                    color: active ? Z.text : Z.textMuted)),
          ),
        ),
      );
    }

    return Row(children: [
      tab('overview', 'Overview'),
      tab('stamps', 'Stamps'),
      tab('photos', 'Photos'),
    ]);
  }

  // ── Overview tab ───────────────────────────────────────────
  List<Widget> _overview(
      String? address, String? phone, String? website, List<String> photos) {
    return [
      // Info rows
      if (address != null || phone != null || website != null)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
          child: Column(
            children: [
              if (address != null) _infoRow(Icons.location_on, address),
              if (phone != null)
                _infoRow(Icons.call, phone,
                    onTap: () => _launch(
                        'tel:${phone.replaceAll(RegExp(r'[^\d+]'), '')}')),
              if (website != null)
                _infoRow(
                  Icons.language,
                  website.replaceAll(RegExp(r'^https?://'), '').split('/').first,
                  onTap: () => _launch(
                      website.startsWith('http') ? website : 'https://$website'),
                ),
            ],
          ),
        ),
      const Divider(height: 0.5, color: Z.outline, indent: 16, endIndent: 16),

      // ZON Activity
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ZON Activity',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Z.text)),
            const SizedBox(height: 14),
            IntrinsicHeight(
              child: Row(
                children: [
                  _activityStat('${_allStamps.length}', 'stamps'),
                  _statDivider(),
                  _activityStat('$_uniqueVisitors', 'visitors'),
                  _statDivider(),
                  _activityStat(
                      _lastVisit != null ? _relativeDate(_lastVisit!) : '—',
                      'last visit'),
                ],
              ),
            ),
            if (_friendVisitors.isNotEmpty) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  SizedBox(
                    width: 26.0 + (_friendVisitors.length - 1).clamp(0, 4) * 18,
                    height: 26,
                    child: Stack(
                      children: [
                        for (int i = 0;
                            i < _friendVisitors.take(5).length;
                            i++)
                          Positioned(
                            left: i * 18.0,
                            child: _miniAvatar(_friendVisitors[i]),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_friendVisitors.length} friend${_friendVisitors.length > 1 ? 's' : ''} been here',
                    style: const TextStyle(fontSize: 12, color: Z.textMuted),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
      const Divider(height: 0.5, color: Z.outline, indent: 16, endIndent: 16),

      // Vibes
      if (_vibes.isNotEmpty) ...[
        _sectionHeader('Vibes', null),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final v in _vibes)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Z.brandSoft,
                    borderRadius: Z.rFull,
                  ),
                  child: Text(
                    v.count > 1 ? '${v.tag} ${v.count}' : v.tag,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Z.brand),
                  ),
                ),
            ],
          ),
        ),
      ],

      // Photos (below ZON Activity)
      if (photos.isNotEmpty) ...[
        _sectionHeader('Photos', '${photos.length}'),
        _photoGrid(photos.take(6).toList(), photos),
      ],

      // Recent stamps
      if (_allStamps.isNotEmpty) ...[
        _sectionHeader('Recent Stamps', null),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Column(
            children: [
              for (final s in _allStamps.take(3)) StampCard(stamp: s),
            ],
          ),
        ),
      ],
    ];
  }

  // ── Stamps tab ─────────────────────────────────────────────
  List<Widget> _stampsTab() {
    final stamps = _displayedStamps;
    return [
      if (_friendStamps.isNotEmpty)
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
          child: Row(
            children: [
              _toggleChip('Everyone', !_showFriendsOnly,
                  () => setState(() => _showFriendsOnly = false)),
              const SizedBox(width: 8),
              _toggleChip('Friends', _showFriendsOnly,
                  () => setState(() => _showFriendsOnly = true)),
            ],
          ),
        ),
      if (stamps.isEmpty)
        const Padding(
          padding: EdgeInsets.all(28),
          child: EmptyView(
            icon: Icons.auto_awesome_outlined,
            message: 'No stamps yet',
            subtitle: 'Check in here to be the first!',
          ),
        )
      else
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
          child: Column(
            children: [for (final s in stamps) StampCard(stamp: s)],
          ),
        ),
    ];
  }

  // ── Photos tab ─────────────────────────────────────────────
  Widget _photosTab(List<String> photos) {
    if (photos.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(28),
        child: EmptyView(
            icon: Icons.photo_outlined, message: 'No photos yet'),
      );
    }
    return _photoGrid(photos, photos);
  }

  // ── Small pieces ───────────────────────────────────────────
  Widget _teardropPin() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Transform.rotate(
          angle: -math.pi / 4,
          child: Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: Z.brand,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(21),
                topRight: Radius.circular(21),
                bottomRight: Radius.circular(21),
                bottomLeft: Radius.zero,
              ),
              boxShadow: [
                BoxShadow(
                    color: Color(0x738B6EC4),
                    blurRadius: 14,
                    offset: Offset(0, 4)),
              ],
            ),
            child: Transform.rotate(
              angle: math.pi / 4,
              child: const Icon(Icons.storefront, color: Colors.white, size: 20),
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.only(top: 2),
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: Z.brand.withValues(alpha: 0.35),
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }

  Widget _infoRow(IconData icon, String text, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 17, color: onTap != null ? Z.brand : Z.textMuted),
            const SizedBox(width: 10),
            Expanded(
              child: Text(text,
                  style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: onTap != null ? Z.brand : Z.text)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _activityStat(String value, String label) => Expanded(
        child: Column(
          children: [
            Text(value,
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Z.text)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(fontSize: 10, color: Z.textMuted)),
          ],
        ),
      );

  Widget _statDivider() => const VerticalDivider(
      width: 1, thickness: 0.5, color: Z.outline, indent: 4, endIndent: 4);

  Widget _miniAvatar(Stamp s) => Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Z.surface2,
          border: Border.all(color: Z.surface1, width: 1.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: s.avatarUrl != null
            ? CachedNetworkImage(imageUrl: s.avatarUrl!, fit: BoxFit.cover)
            : Center(
                child: Text(
                  (s.username ?? '?').substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Z.textMuted),
                ),
              ),
      );

  Widget _sectionHeader(String title, String? trailing) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
        child: Row(
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Z.text)),
            if (trailing != null) ...[
              const SizedBox(width: 6),
              Text(trailing,
                  style: const TextStyle(fontSize: 12, color: Z.textMuted)),
            ],
          ],
        ),
      );

  Widget _photoGrid(List<String> shown, List<String> all) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1),
      child: GridView.count(
        crossAxisCount: 3,
        mainAxisSpacing: 1,
        crossAxisSpacing: 1,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          for (int i = 0; i < shown.length; i++)
            GestureDetector(
              onTap: () => FullScreenImageViewer.show(context, all, index: i),
              child: CachedNetworkImage(
                imageUrl: shown[i],
                fit: BoxFit.cover,
                placeholder: (_, __) => const ColoredBox(color: Z.surface2),
                errorWidget: (_, __, ___) =>
                    const ColoredBox(color: Z.surface2),
              ),
            ),
        ],
      ),
    );
  }

  Widget _toggleChip(String label, bool active, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: active ? Z.brand : Z.surface2,
            borderRadius: Z.rFull,
          ),
          child: Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                  color: active ? Colors.white : Z.textMuted)),
        ),
      );

  String _relativeDate(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(dt);
  }
}

// ── Round floating map control ────────────────────────────────────────────────
class _RoundBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool loading;
  final VoidCallback onTap;
  const _RoundBtn({
    required this.icon,
    required this.onTap,
    this.color = Z.text,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.96),
            shape: BoxShape.circle,
            boxShadow: const [
              BoxShadow(
                  color: Color(0x24000000),
                  blurRadius: 8,
                  offset: Offset(0, 2)),
            ],
          ),
          alignment: Alignment.center,
          child: loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Z.brand))
              : Icon(icon, size: 21, color: color),
        ),
      );
}

// ── Borderless control inside the full-state sheet bar ────────────────────────
class _BarBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _BarBtn(
      {required this.icon, required this.onTap, this.color = Z.text});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
            width: 44, height: 44, child: Icon(icon, size: 22, color: color)),
      );
}

// ── Action pill (Go / Check in / share) ───────────────────────────────────────
class _PillBtn extends StatelessWidget {
  final String? label;
  final IconData icon;
  final bool filled;
  final VoidCallback? onTap;
  const _PillBtn({
    required this.icon,
    this.label,
    this.filled = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final iconOnly = label == null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 38,
        width: iconOnly ? 38 : null,
        padding: iconOnly
            ? null
            : const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: filled ? Z.brand : Colors.transparent,
          border: filled ? null : Border.all(color: Z.outline2),
          borderRadius: Z.rFull,
        ),
        alignment: Alignment.center,
        child: iconOnly
            ? Icon(icon, size: 18, color: Z.textMuted)
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon,
                      size: 14,
                      color: filled ? Colors.white : Z.textMuted),
                  const SizedBox(width: 5),
                  Text(label!,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              filled ? FontWeight.w600 : FontWeight.w500,
                          color: filled ? Colors.white : Z.text)),
                ],
              ),
      ),
    );
  }
}
