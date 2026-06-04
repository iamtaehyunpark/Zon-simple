import 'package:supabase_flutter/supabase_flutter.dart';

mixin BaseRepository {
  SupabaseClient get client;
  String? get currentUserId;

  // Fall back to the live auth user in case the injected id is momentarily stale.
  String? get userId => currentUserId ?? client.auth.currentUser?.id;
}
