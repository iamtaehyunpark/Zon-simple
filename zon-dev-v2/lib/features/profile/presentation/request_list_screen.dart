import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/user_profile.dart';
import '../../../shared/widgets/app_states.dart';
import '../../../shared/widgets/user_tile.dart';

/// Shared scaffold for the follow- and friend-request screens: a list of
/// requesters, each with Confirm/Delete actions. [onAct] receives the user id
/// and `true` for confirm / `false` for delete.
class RequestListScreen extends StatelessWidget {
  final String title;
  final AsyncValue<List<UserProfile>> requests;
  final IconData emptyIcon;
  final String emptyMessage;
  final String emptySubtitle;
  final Future<void> Function(String userId, bool confirm) onAct;

  const RequestListScreen({
    super.key,
    required this.title,
    required this.requests,
    required this.emptyIcon,
    required this.emptyMessage,
    required this.emptySubtitle,
    required this.onAct,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: requests.when(
        loading: () => const LoadingView(),
        error: (e, _) => const EmptyView(
          icon: Icons.error_outline,
          message: "Couldn't load requests",
        ),
        data: (users) {
          if (users.isEmpty) {
            return EmptyView(
              icon: emptyIcon,
              message: emptyMessage,
              subtitle: emptySubtitle,
            );
          }
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (ctx, i) {
              final u = users[i];
              return UserTile(
                user: u,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FilledButton(
                      onPressed: () => onAct(u.id, true),
                      child: const Text('Confirm'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () => onAct(u.id, false),
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
