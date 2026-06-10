import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../core/location/providers/gps_provider.dart';
import '../../../core/notifications/notification_service.dart';
import '../../../data/models/stamp.dart';
import '../../../data/repositories/notification_repository.dart';
import '../../../data/repositories/check_in_repository.dart';
import '../../../data/repositories/stamp_repository.dart' show stampRepositoryProvider, PlaceStat;
import '../../profile/presentation/providers/profile_provider.dart';
import '../../../shared/widgets/app_states.dart';
import '../../../shared/utils/format.dart';
import '../../photo_import/presentation/providers/photo_suggestion_provider.dart';
import 'providers/feed_provider.dart';

// ── Feed Screen ───────────────────────────────────────────────────────────────
class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final followReqCount =
        (ref.watch(followRequestsProvider).valueOrNull ?? const []).length;
    final friendReqCount =
        (ref.watch(friendRequestsProvider).valueOrNull ?? const []).length;
    final unread =
        (ref.watch(unreadNotificationCountProvider).valueOrNull ?? 0) +
            followReqCount +
            friendReqCount;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Z.surface0,
        body: Column(
          children: [
            // Header block: status bar + app bar + tab bar
            Container(
              color: Z.surface1,
              child: Column(
                children: [
                  // AppBar row
                  SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 6, 0),
                      child: SizedBox(
                        height: 48,
                        child: Row(
                          children: [
                            const Text('ZON',
                                style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.5,
                                    color: Z.text)),
                            const Spacer(),
                            _IconBtn(
                              icon: Icons.search,
                              onTap: () => context.push('/search'),
                            ),
                            _IconBtn(
                              icon: Icons.notifications,
                              badge: unread > 0,
                              onTap: () async {
                                await context.push('/activity');
                                if (!context.mounted) return;
                                ref.invalidate(unreadNotificationCountProvider);
                                ref.invalidate(followRequestsProvider);
                                ref.invalidate(friendRequestsProvider);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Tab row — Following / Nearby / Trending
                  const TabBar(
                    labelStyle: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700),
                    unselectedLabelStyle:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
                    labelColor: Z.brand,
                    unselectedLabelColor: Z.textMuted,
                    indicatorColor: Z.brand,
                    indicatorWeight: 2.5,
                    tabs: [
                      Tab(text: 'Following'),
                      Tab(text: 'Nearby'),
                      Tab(text: 'Trending'),
                    ],
                  ),
                ],
              ),
            ),

            // Tab views
            const Expanded(
              child: TabBarView(
                children: [
                  _FollowingTab(),
                  _NearbyTab(),
                  _TrendingTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Following tab ─────────────────────────────────────────────────────────────
class _FollowingTab extends ConsumerWidget {
  const _FollowingTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedState = ref.watch(feedNotifierProvider);
    return Column(
      children: [
        const _PhotoSuggestionBanner(),
        const _StoriesRail(),
        Expanded(
          child: feedState.when(
            loading: () => const LoadingView(),
            error: (e, _) => ErrorView(
              message: errorMessage(e),
              onRetry: () => ref.read(feedNotifierProvider.notifier).refresh(),
            ),
            data: (stamps) {
              if (stamps.isEmpty) {
                return EmptyView(
                  icon: Icons.explore_outlined,
                  message: 'No stamps yet',
                  subtitle: 'Follow people or create your first stamp!',
                  action: FilledButton.icon(
                    onPressed: () => context.push('/checkin?mode=stamp'),
                    icon: const Icon(Icons.add),
                    label: const Text('Create a stamp'),
                  ),
                );
              }
              return RefreshIndicator(
                color: Z.brand,
                onRefresh: () =>
                    ref.read(feedNotifierProvider.notifier).refresh(),
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
                  itemCount: stamps.length,
                  itemBuilder: (ctx, i) {
                    if (i == stamps.length - 3) {
                      ref.read(feedNotifierProvider.notifier).loadMore();
                    }
                    return StampCard(stamp: stamps[i]);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Nearby tab ────────────────────────────────────────────────────────────────
class _NearbyTab extends ConsumerStatefulWidget {
  const _NearbyTab();

  @override
  ConsumerState<_NearbyTab> createState() => _NearbyTabState();
}

class _NearbyTabState extends ConsumerState<_NearbyTab>
    with AutomaticKeepAliveClientMixin {
  List<Stamp>? _stamps;
  bool _loading = false;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    final pos = ref.read(gpsNotifierProvider).valueOrNull;
    if (pos != null) _loadNearby(pos.latitude, pos.longitude);
  }

  Future<void> _loadNearby(double lat, double lng) async {
    setState(() { _loading = true; _error = null; });
    final result = await ref
        .read(stampRepositoryProvider)
        .nearbyStamps(lat, lng, radiusM: 5000);
    if (!mounted) return;
    setState(() {
      _loading = false;
      result.fold((e) => _error = e.toString(), (s) => _stamps = s);
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    ref.listen(gpsNotifierProvider, (prev, next) {
      final pos = next.valueOrNull;
      if (pos != null && prev?.valueOrNull == null && _stamps == null && !_loading) {
        _loadNearby(pos.latitude, pos.longitude);
      }
    });

    if (_loading) return const LoadingView();
    if (_error != null) {
      return ErrorView(
        message: _error!,
        onRetry: () {
          final pos = ref.read(gpsNotifierProvider).valueOrNull;
          if (pos != null) _loadNearby(pos.latitude, pos.longitude);
        },
      );
    }
    if (_stamps == null) {
      return const EmptyView(
          icon: Icons.location_searching, message: 'Locating you…');
    }
    if (_stamps!.isEmpty) {
      return const EmptyView(
          icon: Icons.explore_outlined,
          message: 'No stamps nearby yet',
          subtitle: 'Be the first to stamp this area!');
    }
    return RefreshIndicator(
      color: Z.brand,
      onRefresh: () {
        final pos = ref.read(gpsNotifierProvider).valueOrNull;
        if (pos != null) return _loadNearby(pos.latitude, pos.longitude);
        return Future.value();
      },
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
        itemCount: _stamps!.length,
        itemBuilder: (ctx, i) => StampCard(stamp: _stamps![i]),
      ),
    );
  }
}

// ── Trending tab ──────────────────────────────────────────────────────────────
class _TrendingTab extends ConsumerStatefulWidget {
  const _TrendingTab();

  @override
  ConsumerState<_TrendingTab> createState() => _TrendingTabState();
}

class _TrendingTabState extends ConsumerState<_TrendingTab>
    with AutomaticKeepAliveClientMixin {
  List<PlaceStat>? _places;
  bool _loading = false;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    final result = await ref.read(stampRepositoryProvider).getTrendingPlaces();
    if (!mounted) return;
    result.fold(
      (e) => setState(() { _error = e.toString(); _loading = false; }),
      (places) => setState(() { _places = places; _loading = false; }),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_loading) return const LoadingView();
    if (_error != null) return ErrorView(message: _error!, onRetry: _load);
    final places = _places;
    if (places == null || places.isEmpty) {
      return const EmptyView(
          icon: Icons.trending_up_outlined,
          message: 'No trending places yet',
          subtitle: 'Trending spots appear when people stamp them.');
    }
    return RefreshIndicator(
      color: Z.brand,
      onRefresh: _load,
      child: ListView.builder(
        itemCount: places.length,
        itemBuilder: (ctx, i) {
          final p = places[i];
          return Container(
            decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Z.outline))),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: Z.brandSoft,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text('${i + 1}',
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Z.brand)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.name,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Z.text)),
                      const SizedBox(height: 2),
                      Text('${p.stampCount} stamps · ${p.visitorCount} visitors',
                          style: const TextStyle(
                              fontSize: 12, color: Z.textMuted)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, size: 20, color: Z.textFaint),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── StampCard — photo-first design from zon-cards.jsx ─────────────────────────
class StampCard extends ConsumerWidget {
  final Stamp stamp;
  const StampCard({super.key, required this.stamp});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => context.push('/stamp/${stamp.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Z.surface1,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Z.outline),
          boxShadow: const [
            BoxShadow(
                color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 1)),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo with gradient scrim overlay
            SizedBox(
              height: 222,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  stamp.coverPhotoUrl != null
                      ? CachedNetworkImage(
                          imageUrl: stamp.coverPhotoUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) =>
                              const ColoredBox(color: Z.surface2),
                          errorWidget: (_, __, ___) =>
                              const ColoredBox(color: Z.surface2),
                        )
                      : const ColoredBox(color: Z.surface2),
                  // Gradient scrim
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: [0.45, 1.0],
                        colors: [Colors.transparent, Color(0x9E14100C)],
                      ),
                    ),
                  ),
                  // Place + user overlay
                  Positioned(
                    bottom: 10,
                    left: 13,
                    right: 13,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.location_on,
                                      size: 14, color: Colors.white),
                                  const SizedBox(width: 5),
                                  Flexible(
                                    child: Text(stamp.placeName,
                                        style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis),
                                  ),
                                ],
                              ),
                              if (stamp.username != null)
                                Text('@${stamp.username}',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xC7FFFFFF))),
                            ],
                          ),
                        ),
                        Text(
                          _timeAgo(stamp.visitedAt),
                          style: const TextStyle(
                              fontSize: 11, color: Color(0xA6FFFFFF)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Card body
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (stamp.caption != null && stamp.caption!.isNotEmpty) ...[
                    Text(
                      '"${stamp.caption}"',
                      style: const TextStyle(
                          fontSize: 14,
                          color: Z.text,
                          height: 1.58,
                          fontStyle: FontStyle.italic),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                  ],
                  if (stamp.sensoryTags.isNotEmpty) ...[
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: stamp.sensoryTags
                          .take(3)
                          .map((tag) => _TagPill(tag))
                          .toList(),
                    ),
                    const SizedBox(height: 11),
                  ],
                  // Action row
                  Row(
                    children: [
                      _ActionBtn(
                        icon: stamp.isLiked ? Icons.favorite : Icons.favorite_border,
                        count: stamp.likeCount,
                        color: stamp.isLiked ? Z.error : Z.textMuted,
                        onTap: () => ref
                            .read(feedNotifierProvider.notifier)
                            .toggleLike(stamp.id),
                      ),
                      const SizedBox(width: 16),
                      _ActionBtn(
                        icon: Icons.chat_bubble_outline,
                        count: stamp.commentCount,
                        color: Z.textMuted,
                        onTap: () => context.push('/stamp/${stamp.id}'),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => ref
                            .read(feedNotifierProvider.notifier)
                            .toggleSave(stamp.id),
                        child: Icon(
                          stamp.isSaved
                              ? Icons.bookmark
                              : Icons.bookmark_border,
                          size: 21,
                          color: stamp.isSaved ? Z.brand : Z.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return DateFormat('MMM d').format(dt);
  }
}

// ── Tag pill
class _TagPill extends StatelessWidget {
  final String tag;
  const _TagPill(this.tag);
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        decoration: BoxDecoration(
            color: Z.brandSoft, borderRadius: BorderRadius.circular(9999)),
        child: Text('#$tag',
            style: const TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600, color: Z.brand)),
      );
}

// ── Action button (like / comment)
class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final int count;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn(
      {required this.icon,
      required this.count,
      required this.color,
      required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Row(
          children: [
            Icon(icon, size: 21, color: color),
            const SizedBox(width: 5),
            Text(compactCount(count),
                style: const TextStyle(fontSize: 13, color: Z.textMuted)),
          ],
        ),
      );
}

// ── Icon button helper
class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool badge;
  const _IconBtn({required this.icon, required this.onTap, this.badge = false});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(icon, size: 24, color: Z.text),
              if (badge)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Z.error,
                      shape: BoxShape.circle,
                      border: Border.all(color: Z.surface1, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
}

// ── Stories rail — zon-cards.jsx StoriesRail ──────────────────────────────────
class _StoriesRail extends ConsumerWidget {
  const _StoriesRail();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stories = ref.watch(feedStoriesProvider).valueOrNull ?? const [];
    if (stories.isEmpty) return const SizedBox.shrink();
    return Container(
      decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Z.outline))),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(4, 10, 4, 12),
        child: Row(
          children: stories.map((s) {
            return GestureDetector(
              onTap: () => showDialog<void>(
                  context: context,
                  builder: (_) => _StoryView(story: s)),
              child: SizedBox(
                width: 76,
                child: Column(
                  children: [
                    // Avatar with gradient ring
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          width: 58,
                          height: 58,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [Z.brand, Z.story],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          padding: const EdgeInsets.all(2.5),
                          child: Container(
                            decoration: const BoxDecoration(
                                shape: BoxShape.circle, color: Z.surface1),
                            padding: const EdgeInsets.all(2),
                            child: s.avatarUrl != null
                                ? ClipOval(
                                    child: CachedNetworkImage(
                                        imageUrl: s.avatarUrl!,
                                        fit: BoxFit.cover))
                                : CircleAvatar(
                                    backgroundColor: Z.surface2,
                                    child: Text(
                                        s.username.isNotEmpty
                                            ? s.username[0].toUpperCase()
                                            : '?',
                                        style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                            color: Z.textMuted))),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '@${s.username}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: Z.text),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ── Story viewer — zon-screens-modal.jsx StoryViewer ─────────────────────────
class _StoryView extends StatefulWidget {
  final CheckInStory story;
  const _StoryView({required this.story});
  @override
  State<_StoryView> createState() => _StoryViewState();
}

class _StoryViewState extends State<_StoryView> {
  int _i = 0;
  @override
  Widget build(BuildContext context) {
    final items = widget.story.checkIns;
    final c = items[_i];
    final photo = c.photoUrls.isNotEmpty ? c.photoUrls.first : null;
    return Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: GestureDetector(
        onTapUp: (d) {
          final mid = MediaQuery.of(context).size.width / 2;
          final next = d.globalPosition.dx > mid ? _i + 1 : _i - 1;
          if (next < 0 || next >= items.length) {
            Navigator.pop(context);
            return;
          }
          setState(() => _i = next);
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            photo != null
                ? CachedNetworkImage(imageUrl: photo, fit: BoxFit.cover)
                : const ColoredBox(color: Colors.black87),
            // Progress bars
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 10,
              right: 10,
              child: Row(
                children: [
                  for (int k = 0; k < items.length; k++)
                    Expanded(
                      child: Container(
                        height: 3,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: k <= _i ? Colors.white : Colors.white38,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // User row
            Positioned(
              top: MediaQuery.of(context).padding.top + 20,
              left: 12,
              right: 12,
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                          colors: [Z.brand, Z.story]),
                    ),
                    padding: const EdgeInsets.all(2),
                    child: widget.story.avatarUrl != null
                        ? ClipOval(
                            child: CachedNetworkImage(
                                imageUrl: widget.story.avatarUrl!,
                                fit: BoxFit.cover))
                        : const CircleAvatar(backgroundColor: Z.surface2),
                  ),
                  const SizedBox(width: 8),
                  Text('@${widget.story.username}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Place + time
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 40,
              left: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          color: Colors.white, size: 16),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(c.placeName,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(DateFormat('MMM d · h:mm a').format(c.visitedAt),
                      style: const TextStyle(
                          color: Color(0xBFFFFFFF), fontSize: 13)),
                  if (c.note != null && c.note!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(c.note!,
                        style: const TextStyle(color: Colors.white, fontSize: 14)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Photo suggestion banner ───────────────────────────────────────────────────
class _PhotoSuggestionBanner extends ConsumerStatefulWidget {
  const _PhotoSuggestionBanner();
  @override
  ConsumerState<_PhotoSuggestionBanner> createState() =>
      _PhotoSuggestionBannerState();
}

class _PhotoSuggestionBannerState
    extends ConsumerState<_PhotoSuggestionBanner> {
  bool _dismissed = false;
  bool _notified = false;

  @override
  Widget build(BuildContext context) {
    final photos =
        ref.watch(todayPhotoSuggestionsProvider).valueOrNull ?? const [];
    if (photos.isNotEmpty && !_notified) {
      _notified = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        NotificationService().sendLocalNotification(
          title: 'New places today',
          body:
              '${photos.length} photo${photos.length == 1 ? '' : 's'} from today — add as check-ins?',
          payload: '/photo-suggestions',
        );
      });
    }
    if (_dismissed || photos.isEmpty) return const SizedBox.shrink();
    return Material(
      color: Z.brandSoft2,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 4, 8),
        child: Row(
          children: [
            const Icon(Icons.photo_camera_outlined, size: 20, color: Z.brand),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${photos.length} new place${photos.length == 1 ? '' : 's'} from today\'s photos',
                style: const TextStyle(fontSize: 13, color: Z.text),
              ),
            ),
            TextButton(
              onPressed: () => context.push('/photo-suggestions'),
              child: const Text('Review',
                  style: TextStyle(color: Z.brand, fontWeight: FontWeight.w600)),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 18, color: Z.textMuted),
              onPressed: () => setState(() => _dismissed = true),
            ),
          ],
        ),
      ),
    );
  }
}
