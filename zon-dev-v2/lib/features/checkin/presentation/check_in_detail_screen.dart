import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../data/models/check_in.dart';
import '../../../data/models/enums.dart';
import '../../../data/repositories/check_in_repository.dart';
import '../../../shared/widgets/app_states.dart';
import '../../../shared/widgets/photo_thumb_row.dart';

final checkInDetailProvider =
    FutureProvider.autoDispose.family<CheckIn?, String>((ref, id) async {
  final result = await ref.watch(checkInRepositoryProvider).getCheckIn(id);
  return result.fold((_) => null, (c) => c);
});

class CheckInDetailScreen extends ConsumerWidget {
  final String checkInId;
  const CheckInDetailScreen({super.key, required this.checkInId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(checkInDetailProvider(checkInId));
    return Scaffold(
      body: async.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(message: errorMessage(e)),
        data: (checkIn) {
          if (checkIn == null) {
            return const EmptyView(
              icon: Icons.location_off_outlined,
              message: 'Check-in not found',
            );
          }
          return _CheckInDetailBody(checkIn: checkIn);
        },
      ),
    );
  }
}

class _CheckInDetailBody extends ConsumerWidget {
  final CheckIn checkIn;
  const _CheckInDetailBody({required this.checkIn});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myId = ref.watch(currentUserProvider)?.id;
    final isOwner = checkIn.userId == myId;
    final hasPhotos = checkIn.photoUrls.isNotEmpty;
    final cover = hasPhotos ? checkIn.photoUrls.first : null;

    return CustomScrollView(
      slivers: [
        // Hero photo or compact bar
        SliverAppBar(
          expandedHeight: cover != null ? 280 : 80,
          pinned: true,
          flexibleSpace: cover != null
              ? FlexibleSpaceBar(
                  background: CachedNetworkImage(
                    imageUrl: cover,
                    fit: BoxFit.cover,
                  ),
                )
              : const FlexibleSpaceBar(),
          actions: isOwner
              ? [
                  PopupMenuButton<_Action>(
                    onSelected: (a) async {
                      if (a == _Action.edit) {
                        // Navigate to timeline for inline edit
                        context.go('/timeline');
                      } else if (a == _Action.delete) {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Delete check-in?'),
                            content: const Text('This cannot be undone.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Cancel'),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                        if (ok == true && context.mounted) {
                          await ref
                              .read(checkInRepositoryProvider)
                              .deleteCheckIn(checkIn.id);
                          if (context.mounted) context.pop();
                        }
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                          value: _Action.edit, child: Text('Edit in timeline')),
                      PopupMenuItem(
                          value: _Action.delete, child: Text('Delete')),
                    ],
                  ),
                ]
              : null,
        ),

        // Info section
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Place name
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: checkIn.externalPlaceId != null
                      ? () => context.push(
                          '/place/${Uri.encodeComponent(checkIn.externalPlaceId!)}')
                      : null,
                  child: Text(
                    checkIn.placeName,
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        decoration: checkIn.externalPlaceId != null
                            ? TextDecoration.underline
                            : null,
                        decorationColor: Colors.black26,
                        decorationThickness: 1),
                  ),
                ),
                const SizedBox(height: 6),

                // Date / time
                Text(
                  DateFormat('EEEE, MMMM d, y · h:mm a')
                      .format(checkIn.visitedAt),
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 10),

                // Badges row
                Row(
                  children: [
                    _VisibilityBadge(checkIn.visibility),
                    const SizedBox(width: 8),
                    _SourceBadge(checkIn.source),
                  ],
                ),

                // Note
                if (checkIn.note != null && checkIn.note!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(checkIn.note!,
                      style: const TextStyle(fontSize: 15, height: 1.5)),
                ],

                // Additional photos (skip index 0 — already shown as hero)
                if (checkIn.photoUrls.length > 1) ...[
                  const SizedBox(height: 16),
                  PhotoThumbRow(
                      urls: checkIn.photoUrls.skip(1).toList(), size: 100),
                ] else if (hasPhotos && cover == null) ...[
                  const SizedBox(height: 16),
                  PhotoThumbRow(urls: checkIn.photoUrls, size: 100),
                ],

                const SizedBox(height: 24),

                // CTA
                if (isOwner) ...[
                  if (checkIn.stampId == null)
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        icon: const Icon(Icons.auto_awesome),
                        label: const Text('Make a stamp'),
                        onPressed: () => context
                            .push('/checkin?fromCheckIn=${checkIn.id}'),
                      ),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.collections_bookmark_outlined),
                        label: const Text('View stamp'),
                        onPressed: () =>
                            context.push('/stamp/${checkIn.stampId}'),
                      ),
                    ),
                ],

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

enum _Action { edit, delete }

class _VisibilityBadge extends StatelessWidget {
  final StampVisibility visibility;
  const _VisibilityBadge(this.visibility);

  @override
  Widget build(BuildContext context) {
    final isPublic = visibility == StampVisibility.public;
    return _Badge(
      icon: isPublic ? Icons.public : Icons.lock,
      label: isPublic ? 'Story' : 'Private',
      color: isPublic ? Colors.blue : Colors.grey,
    );
  }
}

class _SourceBadge extends StatelessWidget {
  final CheckInSource source;
  const _SourceBadge(this.source);

  @override
  Widget build(BuildContext context) {
    return switch (source) {
      CheckInSource.auto => const _Badge(
          icon: Icons.location_searching,
          label: 'Auto',
          color: Colors.grey),
      CheckInSource.photo => const _Badge(
          icon: Icons.photo_camera_outlined,
          label: 'Photo',
          color: Colors.grey),
      CheckInSource.manual =>
        const _Badge(icon: Icons.touch_app, label: 'Manual', color: Colors.grey),
    };
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _Badge({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(fontSize: 12, color: color)),
        ],
      ),
    );
  }
}
