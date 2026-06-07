import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../data/repositories/notification_repository.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../../shared/widgets/app_states.dart';
import 'providers/profile_provider.dart';

/// Activity screen — matches zon-screens-sub.jsx ActivityScreen
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
    if (mounted) setState(() { _items = items; _loading = false; });
  }

  String _text(AppNotification n) {
    final who = n.actorUsername != null ? '@${n.actorUsername}' : 'Someone';
    return switch (n.type) {
      'like'           => '$who liked your stamp',
      'comment'        => '$who commented on your stamp',
      'follow'         => '$who started following you',
      'follow_accepted'=> '$who accepted your follow request',
      'friend_request' => '$who sent you a friend request',
      'friend_accepted'=> '$who accepted your friend request',
      'tag'            => '$who tagged you in a stamp',
      'mention'        => '$who mentioned you',
      _                => '$who did something',
    };
  }

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

    return Scaffold(
      backgroundColor: Z.surface0,
      body: Column(
        children: [
          // Header
          Container(
            color: Z.surface1,
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(6, 4, 16, 12),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: const SizedBox(
                            width: 40, height: 40,
                            child: Icon(Icons.arrow_back,
                                size: 24, color: Z.text),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text('Activity',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Z.text)),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Z.outline),
                ],
              ),
            ),
          ),

          Expanded(
            child: _loading
                ? const LoadingView()
                : (friendReqs.isEmpty &&
                        followReqs.isEmpty &&
                        _items.isEmpty)
                    ? const EmptyView(
                        icon: Icons.notifications_none,
                        message: 'No activity yet',
                        subtitle:
                            'Likes, comments and follows land here.')
                    : ListView(
                        children: [
                          // Friend requests section
                          if (friendReqs.isNotEmpty) ...[
                            const Padding(
                              padding: EdgeInsets.fromLTRB(16, 14, 16, 6),
                              child: Text('FRIEND REQUESTS',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Z.textMuted,
                                      letterSpacing: 0.6)),
                            ),
                            for (final r in friendReqs)
                              _NotifRow(
                                initials: r.username.isNotEmpty
                                    ? r.username[0].toUpperCase()
                                    : '?',
                                avatarUrl: r.avatarUrl,
                                text:
                                    '@${r.username} sent you a friend request',
                                time: '',
                                isRequest: true,
                                onAccept: () async {
                                  await ref
                                      .read(profileRepositoryProvider)
                                      .acceptFriendRequest(r.id);
                                  ref.invalidate(friendRequestsProvider);
                                },
                                onDecline: () async {
                                  await ref
                                      .read(profileRepositoryProvider)
                                      .denyFriendRequest(r.id);
                                  ref.invalidate(friendRequestsProvider);
                                },
                              ),
                            const Divider(
                                height: 6, color: Z.surface0),
                          ],

                          // Follow requests
                          if (followReqs.isNotEmpty) ...[
                            const Padding(
                              padding:
                                  EdgeInsets.fromLTRB(16, 14, 16, 6),
                              child: Text('FOLLOW REQUESTS',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Z.textMuted,
                                      letterSpacing: 0.6)),
                            ),
                            for (final r in followReqs)
                              _NotifRow(
                                initials: r.username.isNotEmpty
                                    ? r.username[0].toUpperCase()
                                    : '?',
                                avatarUrl: r.avatarUrl,
                                text:
                                    '@${r.username} wants to follow you',
                                time: '',
                                isRequest: true,
                                onAccept: () async {
                                  await ref
                                      .read(profileRepositoryProvider)
                                      .approveFollow(r.id);
                                  ref.invalidate(followRequestsProvider);
                                },
                                onDecline: () async {
                                  await ref
                                      .read(profileRepositoryProvider)
                                      .denyFollow(r.id);
                                  ref.invalidate(followRequestsProvider);
                                },
                              ),
                            const Divider(height: 6, color: Z.surface0),
                          ],

                          // Notifications
                          if (_items.isNotEmpty) ...[
                            const Padding(
                              padding:
                                  EdgeInsets.fromLTRB(16, 14, 16, 6),
                              child: Text('TODAY',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Z.textMuted,
                                      letterSpacing: 0.6)),
                            ),
                            for (final n in _items)
                              _NotifRow(
                                initials: n.actorUsername
                                        ?.isNotEmpty ==
                                    true
                                    ? n.actorUsername![0].toUpperCase()
                                    : '?',
                                avatarUrl: n.actorAvatar,
                                text: _text(n),
                                time: DateFormat('MMM d, h:mm a')
                                    .format(n.sentAt),
                                onTap: () => _onTap(n),
                              ),
                          ],
                        ],
                      ),
          ),
        ],
      ),
    );
  }
}

// ── NotificationRow — zon-cards.jsx NotificationRow ──────────────────────────
class _NotifRow extends StatelessWidget {
  final String initials;
  final String? avatarUrl;
  final String text;
  final String time;
  final bool isRequest;
  final VoidCallback? onTap;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;

  const _NotifRow({
    required this.initials,
    this.avatarUrl,
    required this.text,
    required this.time,
    this.isRequest = false,
    this.onTap,
    this.onAccept,
    this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: const BoxDecoration(
            color: Z.surface1,
            border: Border(bottom: BorderSide(color: Z.outline))),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: Z.surface2),
              clipBehavior: Clip.antiAlias,
              child: avatarUrl != null
                  ? CachedNetworkImage(
                      imageUrl: avatarUrl!, fit: BoxFit.cover)
                  : Center(
                      child: Text(initials,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Z.textMuted)),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      style: const TextStyle(
                          fontSize: 14, color: Z.text, height: 1.5),
                      children: [
                        TextSpan(
                          text: '${text.split(' ').first} ',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700),
                        ),
                        TextSpan(
                            text: text
                                .substring(text.indexOf(' ') + 1)),
                      ],
                    ),
                  ),
                  if (time.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(time,
                          style: const TextStyle(
                              fontSize: 12, color: Z.textMuted)),
                    ),
                  if (isRequest) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: onAccept,
                            child: Container(
                              height: 34,
                              decoration: BoxDecoration(
                                  color: Z.brand,
                                  borderRadius:
                                      BorderRadius.circular(9999)),
                              alignment: Alignment.center,
                              child: const Text('Accept',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: GestureDetector(
                            onTap: onDecline,
                            child: Container(
                              height: 34,
                              decoration: BoxDecoration(
                                border:
                                    Border.all(color: Z.outline2),
                                borderRadius:
                                    BorderRadius.circular(9999),
                              ),
                              alignment: Alignment.center,
                              child: const Text('Decline',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Z.textMuted)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
