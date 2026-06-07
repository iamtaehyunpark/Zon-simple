import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/stamp.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../../shared/widgets/app_states.dart';
import '../../../shared/utils/format.dart';
import 'providers/profile_provider.dart';
import '../../../core/auth/auth_provider.dart';

// ── Social action buttons (Add Friend + Follow) ───────────────────────────

class _SocialButtons extends ConsumerWidget {
  final String targetId;
  const _SocialButtons({required this.targetId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fs = ref.watch(friendStateProvider(targetId)).valueOrNull ??
        FriendState.none;
    final fw = ref.watch(followStateProvider(targetId)).valueOrNull ??
        FollowState.none;
    final notifier =
        ref.read(profileNotifierProvider(targetId).notifier);

    return Row(
      children: [
        Expanded(child: _friendButton(context, ref, fs, fw, notifier)),
        const SizedBox(width: 8),
        Expanded(child: _followButton(context, ref, fw, notifier, targetId)),
      ],
    );
  }

  Widget _friendButton(
    BuildContext context,
    WidgetRef ref,
    FriendState fs,
    FollowState fw,
    ProfileNotifier notifier,
  ) {
    switch (fs) {
      case FriendState.none:
        return FilledButton.icon(
          icon: const Icon(Icons.person_add_outlined, size: 18),
          label: const Text('Add Friend'),
          onPressed: () => notifier.sendFriendRequest(),
        );
      case FriendState.requestedByMe:
        return OutlinedButton.icon(
          icon: const Icon(Icons.hourglass_empty, size: 18),
          label: const Text('Requested'),
          onPressed: () => notifier.cancelFriendRequest(),
        );
      case FriendState.requestedByThem:
        return FilledButton.icon(
          icon: const Icon(Icons.people_alt_outlined, size: 18),
          label: const Text('Respond'),
          onPressed: () => _showRespondMenu(context, ref),
        );
      case FriendState.friends:
        return PopupMenuButton<_FriendAction>(
          onSelected: (a) {
            if (a == _FriendAction.unfriend) notifier.unfriend();
          },
          itemBuilder: (_) => [
            const PopupMenuItem(
              value: _FriendAction.unfriend,
              child: Text('Unfriend'),
            ),
          ],
          child: OutlinedButton.icon(
            icon: const Icon(Icons.people_alt, size: 18),
            label: const Text('Friends'),
            onPressed: null, // handled by PopupMenuButton
          ),
        );
    }
  }

  void _showRespondMenu(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.check_circle_outline),
              title: const Text('Confirm'),
              onTap: () async {
                Navigator.pop(ctx);
                await ref
                    .read(profileRepositoryProvider)
                    .acceptFriendRequest(targetId);
                ref.invalidate(friendStateProvider(targetId));
                ref.invalidate(friendRequestsProvider);
              },
            ),
            ListTile(
              leading: const Icon(Icons.cancel_outlined),
              title: const Text('Delete'),
              onTap: () async {
                Navigator.pop(ctx);
                await ref
                    .read(profileRepositoryProvider)
                    .denyFriendRequest(targetId);
                ref.invalidate(friendStateProvider(targetId));
                ref.invalidate(friendRequestsProvider);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _followButton(
    BuildContext context,
    WidgetRef ref,
    FollowState fw,
    ProfileNotifier notifier,
    String targetId,
  ) {
    final label = switch (fw) {
      FollowState.following => 'Following',
      FollowState.requested => 'Requested',
      FollowState.none => 'Follow',
    };
    return OutlinedButton(
      onPressed: () => notifier.toggleFollow(targetId),
      child: Text(label),
    );
  }
}

enum _FriendAction { unfriend }

class ProfileScreen extends ConsumerWidget {
  final String? userId;
  const ProfileScreen({super.key, this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final targetId = userId ?? currentUser?.id;

    if (targetId == null) {
      return const Scaffold(body: LoadingView());
    }

    final isOwnProfile = targetId == currentUser?.id;
    final profileState = ref.watch(profileNotifierProvider(targetId));
    final stampsState = ref.watch(
        profileStampsNotifierProvider(targetId, publicOnly: !isOwnProfile));

    return Scaffold(
      body: profileState.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(message: errorMessage(e)),
        data: (profile) {
          if (profile == null) {
            return const EmptyView(
              icon: Icons.person_off_outlined,
              message: 'Profile not found',
            );
          }
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        CircleAvatar(
                          radius: 40,
                          backgroundImage: profile.avatarUrl != null
                              ? CachedNetworkImageProvider(profile.avatarUrl!)
                              : null,
                          child: profile.avatarUrl == null
                              ? const Icon(Icons.person, size: 40)
                              : null,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          profile.displayName?.isNotEmpty == true
                              ? profile.displayName!
                              : profile.username,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '@${profile.username}',
                          style: const TextStyle(
                              color: Colors.black54, fontSize: 13),
                        ),
                        if (profile.bio != null && profile.bio!.isNotEmpty)
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 32),
                            child: Text(
                              profile.bio!,
                              style: const TextStyle(color: Colors.grey),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                actions: isOwnProfile
                    ? [
                        IconButton(
                          icon: const Icon(Icons.bookmark_border),
                          tooltip: 'Saved',
                          onPressed: () => context.push('/saved'),
                        ),
                        IconButton(
                          icon: const Icon(Icons.pin_drop_outlined),
                          tooltip: 'My check-ins',
                          onPressed: () => context.push('/check-ins'),
                        ),
                        IconButton(
                          icon: const Icon(Icons.settings),
                          onPressed: () => context.push('/settings'),
                        ),
                      ]
                    : null,
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _StatItem(label: 'Stamps', value: profile.stampCount),
                      _StatItem(
                          label: 'Friends',
                          value: profile.friendCount,
                          onTap: () =>
                              context.push('/profile/$targetId/friends')),
                      _StatItem(
                          label: 'Followers',
                          value: profile.followerCount,
                          onTap: () =>
                              context.push('/profile/$targetId/followers')),
                      _StatItem(
                          label: 'Following',
                          value: profile.followingCount,
                          onTap: () =>
                              context.push('/profile/$targetId/following')),
                    ],
                  ),
                ),
              ),
              if (!isOwnProfile)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _SocialButtons(targetId: targetId),
                  ),
                ),
              // A private account hides its stamps until you're an accepted follower or friend.
              if (!isOwnProfile &&
                  profile.isPrivate &&
                  (ref.watch(followStateProvider(targetId)).valueOrNull ??
                          FollowState.none) !=
                      FollowState.following &&
                  (ref.watch(friendStateProvider(targetId)).valueOrNull ??
                          FriendState.none) !=
                      FriendState.friends)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(48),
                    child: Column(
                      children: [
                        Icon(Icons.lock_outline, size: 48, color: Colors.grey),
                        SizedBox(height: 12),
                        Text('This account is private',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        SizedBox(height: 4),
                        Text('Follow to see their stamps',
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                )
              else
                stampsState.when(
                loading: () => const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: LoadingView(),
                  ),
                ),
                error: (e, _) => SliverToBoxAdapter(
                  child: ErrorView(message: errorMessage(e)),
                ),
                data: (stamps) {
                  if (stamps.isEmpty) {
                    return SliverToBoxAdapter(
                      child: EmptyView(
                        icon: Icons.auto_awesome_outlined,
                        message: isOwnProfile
                            ? 'No stamps yet'
                            : 'No public stamps yet',
                        action: isOwnProfile
                            ? FilledButton.icon(
                                onPressed: () =>
                                    context.push('/checkin?mode=stamp'),
                                icon: const Icon(Icons.add),
                                label: const Text('Create a stamp'),
                              )
                            : null,
                      ),
                    );
                  }
                  return SliverPadding(
                    padding: const EdgeInsets.all(2),
                    sliver: SliverGrid(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) {
                          if (i == stamps.length - 3) {
                            ref
                                .read(profileStampsNotifierProvider(targetId,
                                        publicOnly: !isOwnProfile)
                                    .notifier)
                                .loadMore(targetId, publicOnly: !isOwnProfile);
                          }
                          return _StampGridItem(stamp: stamps[i]);
                        },
                        childCount: stamps.length,
                      ),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 2,
                        mainAxisSpacing: 2,
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final int value;
  final VoidCallback? onTap;
  const _StatItem({required this.label, required this.value, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          children: [
            Text(
              compactCount(value),
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            Text(label,
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _StampGridItem extends StatelessWidget {
  final Stamp stamp;
  const _StampGridItem({required this.stamp});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/stamp/${stamp.id}'),
      child: stamp.coverPhotoUrl != null
          ? CachedNetworkImage(
              imageUrl: stamp.coverPhotoUrl!,
              fit: BoxFit.cover,
            )
          : Container(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.place),
                  const SizedBox(height: 4),
                  Text(
                    stamp.placeName,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 10),
                  ),
                ],
              ),
            ),
    );
  }
}
