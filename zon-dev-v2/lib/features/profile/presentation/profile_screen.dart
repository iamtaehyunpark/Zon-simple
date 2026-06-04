import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/stamp.dart';
import '../../../shared/widgets/app_states.dart';
import '../../../shared/utils/format.dart';
import 'providers/profile_provider.dart';
import '../../../core/auth/auth_provider.dart';

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
                      _StatItem(
                          label: 'Stamps', value: profile.stampCount),
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
                    child: Consumer(builder: (ctx, ref, _) {
                      final followingAsync = ref.watch(
                          isFollowingProvider(targetId));
                      final isFollowing =
                          followingAsync.valueOrNull ?? false;
                      return FilledButton(
                        onPressed: () => ref
                            .read(profileNotifierProvider(targetId).notifier)
                            .toggleFollow(targetId),
                        child: Text(isFollowing ? 'Unfollow' : 'Follow'),
                      );
                    }),
                  ),
                ),
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
