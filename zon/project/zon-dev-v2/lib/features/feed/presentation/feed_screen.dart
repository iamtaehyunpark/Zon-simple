import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/notifications/notification_service.dart';
import '../../../data/models/stamp.dart';
import '../../../data/repositories/notification_repository.dart';
import '../../../data/repositories/check_in_repository.dart';
import '../../profile/presentation/providers/profile_provider.dart';
import '../../../shared/widgets/app_states.dart';
import '../../../shared/utils/format.dart';
import '../../photo_import/presentation/providers/photo_suggestion_provider.dart';
import 'providers/feed_provider.dart';

class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedState = ref.watch(feedNotifierProvider);
    final followReqCount =
        (ref.watch(followRequestsProvider).valueOrNull ?? const []).length;
    final friendReqCount =
        (ref.watch(friendRequestsProvider).valueOrNull ?? const []).length;
    final unread =
        (ref.watch(unreadNotificationCountProvider).valueOrNull ?? 0) +
            followReqCount +
            friendReqCount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ZON', style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search people',
            onPressed: () => context.push('/search'),
          ),
          IconButton(
            tooltip: 'Activity',
            icon: Badge(
              isLabelVisible: unread > 0,
              label: Text('$unread'),
              child: const Icon(Icons.notifications_outlined),
            ),
            onPressed: () async {
              await context.push('/activity');
              ref.invalidate(unreadNotificationCountProvider);
              ref.invalidate(followRequestsProvider);
              ref.invalidate(friendRequestsProvider);
            },
          ),
        ],
      ),
      body: Column(
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
            onRefresh: () =>
                ref.read(feedNotifierProvider.notifier).refresh(),
            child: ListView.builder(
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
      ),
    );
  }
}

class StampCard extends ConsumerWidget {
  final Stamp stamp;
  const StampCard({super.key, required this.stamp});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/stamp/${stamp.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (stamp.coverPhotoUrl != null)
              CachedNetworkImage(
                imageUrl: stamp.coverPhotoUrl!,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  height: 200,
                  color: Colors.grey[200],
                ),
                errorWidget: (_, __, ___) => Container(
                  height: 200,
                  color: Colors.grey[200],
                  child: const Icon(Icons.image_not_supported),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundImage: stamp.avatarUrl != null
                            ? NetworkImage(stamp.avatarUrl!)
                            : null,
                        child: stamp.avatarUrl == null
                            ? const Icon(Icons.person, size: 16)
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                if (stamp.username != null)
                                  Text(
                                    stamp.username!,
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                              ],
                            ),
                            Text(
                              stamp.placeName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              DateFormat('MMM d, y').format(stamp.visitedAt),
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (stamp.caption != null && stamp.caption!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      stamp.caption!,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (stamp.sensoryTags.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      children: stamp.sensoryTags
                          .take(3)
                          .map((t) => Chip(
                                label: Text(t, style: const TextStyle(fontSize: 11)),
                                padding: EdgeInsets.zero,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ))
                          .toList(),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _ActionBtn(
                        icon: stamp.isLiked
                            ? Icons.favorite
                            : Icons.favorite_border,
                        count: stamp.likeCount,
                        color: stamp.isLiked ? Colors.red : null,
                        onTap: () => ref
                            .read(feedNotifierProvider.notifier)
                            .toggleLike(stamp.id),
                      ),
                      const SizedBox(width: 16),
                      _ActionBtn(
                        icon: Icons.comment_outlined,
                        count: stamp.commentCount,
                        onTap: () => context.push('/stamp/${stamp.id}'),
                      ),
                      const Spacer(),
                      InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => ref
                            .read(feedNotifierProvider.notifier)
                            .toggleSave(stamp.id),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            stamp.isSaved
                                ? Icons.bookmark
                                : Icons.bookmark_border,
                            size: 20,
                            color: stamp.isSaved
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey[600],
                          ),
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
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final int count;
  final Color? color;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.count,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 4),
            Text(compactCount(count), style: const TextStyle(fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

/// Horizontal "stories" rail of recent public check-ins from people you follow
/// (and your own). Hidden when there are none. Tap an avatar to view that
/// author's recent public check-ins. (Concept like IG stories; styling TBD.)
class _StoriesRail extends ConsumerWidget {
  const _StoriesRail();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stories = ref.watch(feedStoriesProvider).valueOrNull ?? const [];
    if (stories.isEmpty) return const SizedBox.shrink();
    return Container(
      height: 96,
      decoration: BoxDecoration(
        border: Border(
            bottom: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        itemCount: stories.length,
        itemBuilder: (ctx, i) {
          final s = stories[i];
          return GestureDetector(
            onTap: () => showDialog<void>(
              context: context,
              builder: (_) => _StoryView(story: s),
            ),
            child: SizedBox(
              width: 72,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFF1D9E75), Color(0xFF2196F3)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 28,
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      child: CircleAvatar(
                        radius: 26,
                        backgroundImage: s.avatarUrl != null
                            ? CachedNetworkImageProvider(s.avatarUrl!)
                            : null,
                        child: s.avatarUrl == null
                            ? const Icon(Icons.person)
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '@${s.username}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Basic viewer for one author's recent public check-ins (tap right/left to
/// page). Concept-level only — visual design will be refined separately.
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
          if (next < 0) return;
          if (next >= items.length) {
            Navigator.pop(context);
            return;
          }
          setState(() => _i = next);
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (photo != null)
              CachedNetworkImage(imageUrl: photo, fit: BoxFit.cover)
            else
              const ColoredBox(color: Colors.black),
            // Progress segments.
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 8,
              right: 8,
              child: Row(
                children: [
                  for (int k = 0; k < items.length; k++)
                    Expanded(
                      child: Container(
                        height: 3,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        color: k <= _i ? Colors.white : Colors.white38,
                      ),
                    ),
                ],
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 20,
              left: 12,
              right: 12,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundImage: widget.story.avatarUrl != null
                        ? CachedNetworkImageProvider(widget.story.avatarUrl!)
                        : null,
                    child: widget.story.avatarUrl == null
                        ? const Icon(Icons.person, size: 16)
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Text('@${widget.story.username}',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: MediaQuery.of(context).padding.bottom + 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.pin_drop, color: Colors.white, size: 18),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(c.placeName,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(DateFormat('MMM d, h:mm a').format(c.visitedAt),
                      style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  if (c.note != null && c.note!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(c.note!,
                        style: const TextStyle(color: Colors.white)),
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

/// Dismissible banner that surfaces today's geotagged photos as check-in
/// suggestions, and fires a one-shot local notification when they appear.
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
          body: '${photos.length} photo${photos.length == 1 ? '' : 's'} '
              'from today — add as check-ins?',
          payload: '/photo-suggestions',
        );
      });
    }

    if (_dismissed || photos.isEmpty) return const SizedBox.shrink();

    return Material(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 4, 8),
        child: Row(
          children: [
            const Icon(Icons.photo_camera_outlined, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${photos.length} new place${photos.length == 1 ? '' : 's'} '
                "from today's photos",
                style: const TextStyle(fontSize: 13),
              ),
            ),
            TextButton(
              onPressed: () => context.push('/photo-suggestions'),
              child: const Text('Review'),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: () => setState(() => _dismissed = true),
            ),
          ],
        ),
      ),
    );
  }
}
