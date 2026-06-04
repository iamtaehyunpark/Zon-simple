import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../data/repositories/notification_repository.dart';

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
      'tag' => '$who tagged you in a stamp',
      'mention' => '$who mentioned you',
      _ => '$who did something',
    };
  }

  IconData _icon(String type) => switch (type) {
        'like' => Icons.favorite,
        'comment' => Icons.comment,
        'follow' => Icons.person_add,
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
    return Scaffold(
      appBar: AppBar(title: const Text('Activity')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.notifications_none,
                          size: 48, color: Colors.grey),
                      SizedBox(height: 12),
                      Text('No activity yet'),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _items.length,
                  itemBuilder: (ctx, i) {
                    final n = _items[i];
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
                      subtitle: Text(DateFormat('MMM d, h:mm a').format(n.sentAt)),
                      onTap: () => _onTap(n),
                    );
                  },
                ),
    );
  }
}
