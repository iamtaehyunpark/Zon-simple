import 'dart:math' as math;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../app.dart';
import '../../../core/places/place_models.dart';
import '../../../core/places/place_service_provider.dart';
import '../../../data/models/stamp.dart';
import '../../../data/repositories/stamp_repository.dart';
import '../../../data/repositories/saved_places_repository.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_states.dart';
import '../../../shared/widgets/full_screen_image_viewer.dart';

class PlaceDetailScreen extends ConsumerStatefulWidget {
  final String placeId;
  const PlaceDetailScreen({super.key, required this.placeId});

  @override
  ConsumerState<PlaceDetailScreen> createState() => _PlaceDetailScreenState();
}

class _PlaceDetailScreenState extends ConsumerState<PlaceDetailScreen> {
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

  @override
  void initState() {
    super.initState();
    _load();
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

      // Fetch place detail non-blocking after first render
      if (firstLat != 0 && firstLng != 0) {
        _fetchPlaceDetail(firstName, firstLat, firstLng);
      }
    } catch (e) {
      if (mounted) setState(() {
        _error = e.toString();
        _loading = false;
      });
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

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: LoadingView());
    if (_error != null) {
      return Scaffold(body: ErrorView(message: _error!, onRetry: _load));
    }

    final photos = _allPhotos;
    final cover = _allStamps.isNotEmpty ? _allStamps.first.coverPhotoUrl : null;
    final detail = _placeDetail;
    final address = detail?.address;
    final phone = detail?.phone;
    final website = detail?.website;
    final isOpenNow = detail?.isOpenNow;
    final categories = detail?.categories ?? [];
    final categoryLabel = categories.isNotEmpty
        ? categories.last.split(' > ').last
        : _externalSource != null
            ? _externalSource!.replaceAll('_', ' ')
            : null;

    return Scaffold(
      backgroundColor: Z.surface0,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(cover, isOpenNow),
          SliverToBoxAdapter(child: _buildHeader(categoryLabel, isOpenNow)),
          if (address != null || phone != null || website != null)
            SliverToBoxAdapter(child: _buildInfoCard(address, phone, website)),
          SliverToBoxAdapter(child: _buildCheckinButton()),
          if (_friendVisitors.isNotEmpty)
            SliverToBoxAdapter(child: _buildFriendsSection()),
          if (_vibes.isNotEmpty)
            SliverToBoxAdapter(child: _buildVibesSection()),
          if (photos.isNotEmpty) ...[
            SliverToBoxAdapter(
                child: _sectionHeader('Photos', '${photos.length}')),
            SliverToBoxAdapter(child: _buildPhotoGrid(photos)),
          ],
          SliverToBoxAdapter(child: _buildStampsHeader()),
          if (_displayedStamps.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: EmptyView(
                  icon: Icons.auto_awesome_outlined,
                  message: _showFriendsOnly
                      ? 'No friend stamps here yet'
                      : 'No public stamps yet',
                  subtitle: 'Check in here to be the first!',
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => _buildStampTile(_displayedStamps[i]),
                childCount: _displayedStamps.length,
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildAppBar(String? cover, bool? isOpenNow) {
    return SliverAppBar(
      expandedHeight: cover != null ? 260 : 120,
      pinned: true,
      stretch: true,
      backgroundColor: Z.surface1,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: EdgeInsets.zero,
        background: cover != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(imageUrl: cover, fit: BoxFit.cover),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Color(0x88000000)],
                      ),
                    ),
                  ),
                ],
              )
            : null,
      ),
      actions: [
        IconButton(
          tooltip: _isSaved ? 'Unsave' : 'Save place',
          onPressed: _toggleSave,
          icon: _savingToggle
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : Icon(
                  _isSaved ? Icons.bookmark : Icons.bookmark_border,
                  color: Colors.white,
                ),
        ),
      ],
    );
  }

  Widget _buildHeader(String? categoryLabel, bool? isOpenNow) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  _placeName,
                  style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Z.text),
                ),
              ),
              if (isOpenNow != null) ...[
                const SizedBox(width: 8),
                Container(
                  margin: const EdgeInsets.only(top: 5),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isOpenNow
                        ? const Color(0xFF22C55E)
                        : const Color(0xFFEF4444),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isOpenNow ? 'Open' : 'Closed',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ],
          ),
          if (categoryLabel != null) ...[
            const SizedBox(height: 4),
            Text(categoryLabel,
                style:
                    const TextStyle(fontSize: 13, color: Z.textMuted)),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _StatChip(
                  icon: Icons.auto_awesome,
                  label: '${_allStamps.length} stamps'),
              _StatChip(
                  icon: Icons.people_outline,
                  label: '$_uniqueVisitors visitors'),
              if (_lastVisit != null)
                _StatChip(
                    icon: Icons.schedule,
                    label: _relativeDate(_lastVisit!)),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String? address, String? phone, String? website) {
    final rows = <Widget>[];
    if (address != null) {
      rows.add(_InfoRow(Icons.place_outlined, address, isFirst: true));
    }
    if (phone != null) {
      rows.add(_InfoRow(
        Icons.phone_outlined,
        phone,
        isFirst: rows.isEmpty,
        onTap: () => _launch(
            'tel:${phone.replaceAll(RegExp(r'[^\d+]'), '')}'),
      ));
    }
    if (website != null) {
      rows.add(_InfoRow(
        Icons.language,
        website
            .replaceAll(RegExp(r'^https?://'), '')
            .split('/')
            .first,
        isFirst: rows.isEmpty,
        onTap: () => _launch(
            website.startsWith('http') ? website : 'https://$website'),
      ));
    }
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      decoration: BoxDecoration(
        color: Z.surface1,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Z.outline),
      ),
      child: Column(children: rows),
    );
  }

  Widget _buildCheckinButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: () {
            final buf = StringBuffer('/checkin?mode=checkin');
            if (_lat != 0) buf.write('&lat=$_lat&lng=$_lng');
            context.push(buf.toString());
          },
          icon: const Icon(Icons.pin_drop_outlined, size: 18),
          label: const Text('Check in here'),
          style: FilledButton.styleFrom(
            backgroundColor: kBrandPurple,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    );
  }

  Widget _buildFriendsSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _sectionLabel('Friends here'),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 84,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(right: 16),
              itemCount: _friendVisitors.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (_, i) {
                final s = _friendVisitors[i];
                return GestureDetector(
                  onTap: () => context.push('/stamp/${s.id}'),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor:
                            kBrandPurple.withValues(alpha: 0.12),
                        backgroundImage: s.avatarUrl != null
                            ? CachedNetworkImageProvider(s.avatarUrl!)
                                as ImageProvider
                            : null,
                        child: s.avatarUrl == null
                            ? Text(
                                (s.username ?? '?')
                                    .substring(0, 1)
                                    .toUpperCase(),
                                style: const TextStyle(
                                    color: kBrandPurple,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 18),
                              )
                            : null,
                      ),
                      const SizedBox(height: 5),
                      SizedBox(
                        width: 60,
                        child: Text(
                          '@${s.username ?? '?'}',
                          style: const TextStyle(
                              fontSize: 11, color: Z.textMuted),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVibesSection() {
    final maxCount = _vibes.first.count;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('Vibes'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _vibes.map((v) {
              final intensity = v.count / maxCount;
              return Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: kBrandPurple
                      .withValues(alpha: 0.07 + 0.18 * intensity),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: kBrandPurple
                          .withValues(alpha: 0.15 + 0.3 * intensity)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      v.tag,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: kBrandPurple),
                    ),
                    if (v.count > 1) ...[
                      const SizedBox(width: 4),
                      Text(
                        '${v.count}',
                        style: TextStyle(
                            fontSize: 11,
                            color: kBrandPurple.withValues(alpha: 0.6)),
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoGrid(List<String> photos) {
    final clipped = photos.take(12).toList();
    if (clipped.length == 1) {
      return GestureDetector(
        onTap: () => FullScreenImageViewer.show(context, photos),
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          height: 200,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
          child: CachedNetworkImage(
              imageUrl: clipped.first, fit: BoxFit.cover),
        ),
      );
    }
    final gridCount = math.min(clipped.length - 1, 6);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            GestureDetector(
              onTap: () =>
                  FullScreenImageViewer.show(context, photos, index: 0),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: CachedNetworkImage(
                    imageUrl: clipped.first, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 2),
            SizedBox(
              height: 96,
              child: Row(
                children: List.generate(gridCount, (i) {
                  final idx = i + 1;
                  final isOverflow = i == 5 && photos.length > 7;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => FullScreenImageViewer.show(context, photos,
                          index: idx),
                      child: Container(
                        margin: EdgeInsets.only(left: i == 0 ? 0 : 2),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CachedNetworkImage(
                                imageUrl: clipped[idx], fit: BoxFit.cover),
                            if (isOverflow)
                              Container(
                                color: const Color(0x99000000),
                                child: Center(
                                  child: Text(
                                    '+${photos.length - 7}',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStampsHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(
        children: [
          _sectionLabel('Stamps'),
          const Spacer(),
          if (_friendStamps.isNotEmpty)
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('Everyone')),
                ButtonSegment(value: true, label: Text('Friends')),
              ],
              selected: {_showFriendsOnly},
              onSelectionChanged: (s) =>
                  setState(() => _showFriendsOnly = s.first),
              style: SegmentedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                textStyle: const TextStyle(fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStampTile(Stamp s) {
    return InkWell(
      onTap: () => context.push('/stamp/${s.id}'),
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // Avatar / thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 52,
                height: 52,
                child: s.coverPhotoUrl != null
                    ? CachedNetworkImage(
                        imageUrl: s.coverPhotoUrl!, fit: BoxFit.cover)
                    : s.avatarUrl != null
                        ? CachedNetworkImage(
                            imageUrl: s.avatarUrl!, fit: BoxFit.cover)
                        : Container(
                            color: kBrandPurple.withValues(alpha: 0.12),
                            child: Center(
                              child: Text(
                                (s.username ?? '?')
                                    .substring(0, 1)
                                    .toUpperCase(),
                                style: const TextStyle(
                                    color: kBrandPurple,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 20),
                              ),
                            ),
                          ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('@${s.username ?? 'user'}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: Z.text)),
                      const Spacer(),
                      Text(
                        DateFormat('MMM d, y').format(s.visitedAt),
                        style: const TextStyle(
                            fontSize: 11, color: Z.textFaint),
                      ),
                    ],
                  ),
                  if (s.caption != null && s.caption!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      s.caption!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 13, color: Z.textMuted),
                    ),
                  ],
                  if (s.sensoryTags.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      s.sensoryTags.take(3).join(' · '),
                      style: const TextStyle(
                          fontSize: 11, color: Z.textFaint),
                    ),
                  ],
                ],
              ),
            ),
            if (s.likeCount > 0) ...[
              const SizedBox(width: 8),
              Column(
                children: [
                  const Icon(Icons.favorite,
                      size: 14, color: Z.textFaint),
                  const SizedBox(height: 2),
                  Text('${s.likeCount}',
                      style: const TextStyle(
                          fontSize: 11, color: Z.textFaint)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, String count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(
        children: [
          _sectionLabel(title),
          const SizedBox(width: 6),
          Text(count,
              style: const TextStyle(
                  fontSize: 13,
                  color: Z.textMuted,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style: const TextStyle(
            fontSize: 16, fontWeight: FontWeight.w700, color: Z.text),
      );

  String _relativeDate(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(dt);
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback? onTap;
  final bool isFirst;
  const _InfoRow(this.icon, this.text,
      {this.onTap, this.isFirst = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (!isFirst)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14),
            child: Divider(height: 1, color: Z.outline),
          ),
        InkWell(
          onTap: onTap,
          borderRadius: isFirst
              ? const BorderRadius.vertical(top: Radius.circular(12))
              : BorderRadius.zero,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(icon,
                    size: 18,
                    color:
                        onTap != null ? kBrandPurple : Z.textMuted),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(
                        fontSize: 14,
                        color:
                            onTap != null ? kBrandPurple : Z.textMuted),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (onTap != null)
                  const Icon(Icons.open_in_new,
                      size: 15, color: Z.textFaint),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: kBrandPurple.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: kBrandPurple),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: kBrandPurple)),
        ],
      ),
    );
  }
}
