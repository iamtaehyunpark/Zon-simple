import 'package:supabase_flutter/supabase_flutter.dart';

mixin BaseRepository {
  SupabaseClient get client;
  String? get currentUserId;

  // Fall back to the live auth user in case the injected id is momentarily stale.
  String? get userId => currentUserId ?? client.auth.currentUser?.id;

  // ISO-8601 date string (YYYY-MM-DD). Shared by diary and timeline-note repos.
  String isoDate(DateTime d) => d.toIso8601String().substring(0, 10);

  // IDs of users [userId] follows (accepted only). Shared by stamp and check-in repos.
  Future<List<String>> getFollowingIds(String userId) async {
    try {
      final data = await client
          .from('follows')
          .select('following_id')
          .eq('follower_id', userId)
          .eq('status', 'accepted');
      return data.map((r) => r['following_id'] as String).toList();
    } catch (_) {
      return [];
    }
  }
}
