import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../../shared/widgets/app_states.dart';
import 'providers/profile_provider.dart';

/// Pending follow requests for a private account — approve or deny each.
class FollowRequestsScreen extends ConsumerWidget {
  const FollowRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requests = ref.watch(followRequestsProvider);

    Future<void> act(String requesterId, bool approve) async {
      final repo = ref.read(profileRepositoryProvider);
      approve
          ? await repo.approveFollow(requesterId)
          : await repo.denyFollow(requesterId);
      ref.invalidate(followRequestsProvider);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Follow requests')),
      body: requests.when(
        loading: () => const LoadingView(),
        error: (e, _) => const EmptyView(
          icon: Icons.error_outline,
          message: "Couldn't load requests",
        ),
        data: (users) {
          if (users.isEmpty) {
            return const EmptyView(
              icon: Icons.person_add_alt_outlined,
              message: 'No follow requests',
              subtitle: 'When someone asks to follow you, they show up here.',
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
                  child:
                      u.avatarUrl == null ? const Icon(Icons.person) : null,
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
