import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/profile_repository.dart';
import 'providers/profile_provider.dart';
import 'request_list_screen.dart';

/// Pending follow requests for a private account — approve or deny each.
class FollowRequestsScreen extends ConsumerWidget {
  const FollowRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RequestListScreen(
      title: 'Follow requests',
      requests: ref.watch(followRequestsProvider),
      emptyIcon: Icons.person_add_alt_outlined,
      emptyMessage: 'No follow requests',
      emptySubtitle: 'When someone asks to follow you, they show up here.',
      onAct: (id, confirm) async {
        final repo = ref.read(profileRepositoryProvider);
        confirm ? await repo.approveFollow(id) : await repo.denyFollow(id);
        ref.invalidate(followRequestsProvider);
      },
    );
  }
}
