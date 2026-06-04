import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/notifications/notification_service.dart';
import '../../../data/models/stamp.dart';
import '../../photo_import/presentation/providers/photo_suggestion_provider.dart';
import 'providers/feed_provider.dart';

class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedState = ref.watch(feedNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ZON', style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.push('/search'),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.push('/activity'),
          ),
        ],
      ),
      body: Column(
        children: [
          const _PhotoSuggestionBanner(),
          Expanded(
            child: feedState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 8),
              Text(e.toString()),
              TextButton(
                onPressed: () =>
                    ref.read(feedNotifierProvider.notifier).refresh(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (stamps) {
          if (stamps.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.explore_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No stamps yet', style: TextStyle(fontSize: 18)),
                  SizedBox(height: 8),
                  Text(
                    'Follow people or create your first stamp!',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
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
            Text('$count', style: const TextStyle(fontSize: 13)),
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
