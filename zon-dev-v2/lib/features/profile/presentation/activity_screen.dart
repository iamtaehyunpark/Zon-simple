import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../data/repositories/notification_repository.dart';
import '../../../shared/widgets/app_states.dart';
import 'providers/profile_provider.dart';

class ActivityScreen extends ConsumerStatefulWidget {
  const ActivityScreen({super.key});

  @override
  ConsumerState<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends ConsumerState<ActivityScreen> {
  List<AppNotification> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = ref.read(notificationRepositoryProvider);
    final items = await repo.getNotifications();
    await repo.markAllRead();
    if (mounted) {
      setState(() {
        _items = items;
        _loading = false;
      });
    }
  }

  String _text(AppNotification n) {
    final who = n.actorUsername != null ? '@${n.actorUsername}' : 'Someone';
    return switch (n.type) {
      'like' => '$who liked your stamp',
      'comment' => '$who commented on your stamp',
      'follow' => '$who started following you',
      'follow_accepted' => '$who accepted your follow request',
      'friend_request' => '$who sent you a friend request',
      'friend_accepted' => '$who accepted your friend request',
      'tag' => '$who tagged you in a stamp',
      'mention' => '$who mentioned you',
      _ => '$who did something',
    };
  }

  IconData _icon(String type) => switch (type) {
        'like' => Icons.favorite,
        'comment' => Icons.comment,
        'follow' => Icons.person_add,
        'follow_accepted' => Icons.how_to_reg,
        'friend_request' => Icons.person_add_alt_1,
        'friend_accepted' => Icons.people_alt,
        'tag' => Icons.local_offer,
        'mention' => Icons.alternate_email,
        _ => Icons.notifications,
      };

  void _onTap(AppNotification n) {
    if (n.stampId != null) {
      context.push('/stamp/${n.stampId}');
    } else if (n.actorId != null) {
      context.push('/profile/${n.actorId}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final followReqs = ref.watch(followRequestsProvider).valueOrNull ?? const [];
    final friendReqs = ref.watch(friendRequestsProvider).valueOrNull ?? const [];
    final hasFollowReqs = followReqs.isNotEmpty;
    final hasFriendReqs = friendReqs.isNotEmpty;
    final extraRows = (hasFriendReqs ? 1 : 0) + (hasFollowReqs ? 1 : 0);

    return Scaffold(
      appBar: AppBar(title: const Text('Activity')),
      body: _loading
          ? const LoadingView()
          : (extraRows == 0 && _items.isEmpty)
              ? const EmptyView(
                  icon: Icons.notifications_none,
                  message: 'No activity yet',
                  subtitle: 'Likes, comments, follows and mentions land here.',
                )
              : ListView.builder(
                  itemCount: _items.length + extraRows,
                  itemBuilder: (ctx, i) {
                    // Row 0: friend requests (if any)
                    if (hasFriendReqs && i == 0) {
                      final first = friendReqs.first;
                      return Column(
                        children: [
                          ListTile(
                            leading: CircleAvatar(
                              backgroundImage: first.avatarUrl != null
                                  ? CachedNetworkImageProvider(first.avatarUrl!)
                                  : null,
                              child: first.avatarUrl == null
                                  ? const Icon(Icons.people_alt_outlined)
                                  : null,
                            ),
                            title: const Text('Friend requests',
                                style: TextStyle(fontWeight: FontWeight.w600)),
                            subtitle:
                                Text('${friendReqs.length} pending'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () async {
                              await context.push('/friend-requests');
                              ref.invalidate(friendRequestsProvider);
                            },
                          ),
                          const Divider(height: 1),
                        ],
                      );
                    }
                    // Row 1 (or 0 if no friend reqs): follow requests (if any)
                    final followRow = hasFriendReqs ? 1 : 0;
                    if (hasFollowReqs && i == followRow) {
                      final first = followReqs.first;
                      return Column(
                        children: [
                          ListTile(
                            leading: CircleAvatar(
                              backgroundImage: first.avatarUrl != null
                                  ? CachedNetworkImageProvider(first.avatarUrl!)
                                  : null,
                              child: first.avatarUrl == null
                                  ? const Icon(Icons.person_add_alt)
                                  : null,
                            ),
                            title: const Text('Follow requests',
                                style: TextStyle(fontWeight: FontWeight.w600)),
                            subtitle:
                                Text('${followReqs.length} pending approval'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () async {
                              await context.push('/follow-requests');
                              ref.invalidate(followRequestsProvider);
                            },
                          ),
                          const Divider(height: 1),
                        ],
                      );
                    }
                    final n = _items[i - extraRows];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: n.actorAvatar != null
                            ? CachedNetworkImageProvider(n.actorAvatar!)
                            : null,
                        child: n.actorAvatar == null
                            ? Icon(_icon(n.type), size: 18)
                            : null,
                      ),
                      title: Text(_text(n)),
                      subtitle:
                          Text(DateFormat('MMM d, h:mm a').format(n.sentAt)),
                      onTap: () => _onTap(n),
                    );
                  },
                ),
    );
  }
}
