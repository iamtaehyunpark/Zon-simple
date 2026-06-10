import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/profile_repository.dart';
import 'providers/profile_provider.dart';
import 'request_list_screen.dart';

/// Pending friend requests — accept or deny each.
class FriendRequestsScreen extends ConsumerWidget {
  const FriendRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RequestListScreen(
      title: 'Friend requests',
      requests: ref.watch(friendRequestsProvider),
      emptyIcon: Icons.people_outline,
      emptyMessage: 'No friend requests',
      emptySubtitle: 'When someone sends you a friend request, it shows up here.',
      onAct: (id, confirm) async {
        final repo = ref.read(profileRepositoryProvider);
        confirm
            ? await repo.acceptFriendRequest(id)
            : await repo.denyFriendRequest(id);
        ref.invalidate(friendRequestsProvider);
        ref.invalidate(friendStateProvider(id));
      },
    );
  }
}
