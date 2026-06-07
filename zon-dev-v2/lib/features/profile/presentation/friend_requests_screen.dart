import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../../shared/widgets/app_states.dart';
import 'providers/profile_provider.dart';

/// Pending friend requests — accept or deny each.
class FriendRequestsScreen extends ConsumerWidget {
  const FriendRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requests = ref.watch(friendRequestsProvider);

    Future<void> act(String requesterId, bool accept) async {
      final repo = ref.read(profileRepositoryProvider);
      accept
          ? await repo.acceptFriendRequest(requesterId)
          : await repo.denyFriendRequest(requesterId);
      ref.invalidate(friendRequestsProvider);
      ref.invalidate(friendStateProvider(requesterId));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Friend requests')),
      body: requests.when(
        loading: () => const LoadingView(),
        error: (e, _) => const EmptyView(
          icon: Icons.error_outline,
          message: "Couldn't load requests",
        ),
        data: (users) {
          if (users.isEmpty) {
            return const EmptyView(
              icon: Icons.people_outline,
              message: 'No friend requests',
              subtitle: 'When someone sends you a friend request, it shows up here.',
            );
          }
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (ctx, i) {
              final u = users[i];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: u.avatarUrl != null
                      ? CachedNetworkImageProvider(u.avatarUrl!)
                      : null,
                  child: u.avatarUrl == null ? const Icon(Icons.person) : null,
                ),
                title: Text(u.displayName?.isNotEmpty == true
                    ? u.displayName!
                    : u.username),
                subtitle: Text('@${u.username}'),
                onTap: () => context.push('/profile/${u.id}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FilledButton(
                      onPressed: () => act(u.id, true),
                      child: const Text('Confirm'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () => act(u.id, false),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
