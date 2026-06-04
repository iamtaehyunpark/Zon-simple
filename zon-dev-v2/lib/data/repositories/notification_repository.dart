import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../core/supabase/supabase_provider.dart';
import '../../core/auth/auth_provider.dart';
import 'base_repository.dart';

part 'notification_repository.g.dart';

class AppNotification {
  final String id;
  final String type; // like | comment | follow | tag | mention
  final String? actorId;
  final String? actorUsername;
  final String? actorAvatar;
  final String? stampId;
  final DateTime sentAt;
  final bool tapped;

  const AppNotification({
    required this.id,
    required this.type,
    required this.sentAt,
    required this.tapped,
    this.actorId,
    this.actorUsername,
    this.actorAvatar,
    this.stampId,
  });
}

@riverpod
NotificationRepository notificationRepository(NotificationRepositoryRef ref) =>
    NotificationRepository(
      ref.watch(supabaseClientProvider),
      currentUserId: ref.watch(currentUserProvider)?.id,
    );

class NotificationRepository with BaseRepository {
  @override
  final SupabaseClient client;
  @override
  final String? currentUserId;
  NotificationRepository(this.client, {this.currentUserId});

  Future<List<AppNotification>> getNotifications({int limit = 50}) async {
    final userId = this.userId;
    if (userId == null) return [];
    try {
      final rows = await client
          .from('notification_log')
          .select()
          .eq('user_id', userId)
          .order('sent_at', ascending: false)
          .limit(limit);

      // Resolve actor profiles in one round-trip.
      final actorIds = <String>{
        for (final r in rows)
          if ((r['payload'] as Map?)?['actor_id'] != null)
            (r['payload'] as Map)['actor_id'] as String
      };
      final profiles = actorIds.isEmpty
          ? const <Map<String, dynamic>>[]
          : await client
              .from('profiles')
              .select('id, username, avatar_url')
              .inFilter('id', actorIds.toList());
      final byId = {for (final p in profiles) p['id'] as String: p};

      return [
        for (final r in rows)
          _fromRow(r, byId[(r['payload'] as Map?)?['actor_id']]),
      ];
    } catch (_) {
      return [];
    }
  }

  Future<int> unreadCount() async {
    final userId = this.userId;
    if (userId == null) return 0;
    try {
      final rows = await client
          .from('notification_log')
          .select('id')
          .eq('user_id', userId)
          .eq('tapped', false);
      return rows.length;
    } catch (_) {
      return 0;
    }
  }

  Future<void> markAllRead() async {
    final userId = this.userId;
    if (userId == null) return;
    try {
      await client
          .from('notification_log')
          .update({'tapped': true})
          .eq('user_id', userId)
          .eq('tapped', false);
    } catch (_) {/* best-effort */}
  }

  AppNotification _fromRow(
      Map<String, dynamic> r, Map<String, dynamic>? actor) {
    final payload = (r['payload'] as Map?) ?? const {};
    return AppNotification(
      id: r['id'] as String,
      type: r['type'] as String,
      actorId: payload['actor_id'] as String?,
      actorUsername: actor?['username'] as String?,
      actorAvatar: actor?['avatar_url'] as String?,
      stampId: payload['stamp_id'] as String?,
      sentAt: DateTime.parse(r['sent_at'] as String),
      tapped: r['tapped'] as bool? ?? false,
    );
  }
}
