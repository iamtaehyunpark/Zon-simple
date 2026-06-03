import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/auth/auth_provider.dart';

mixin BaseRepository {
  SupabaseClient get client;
  String? get currentUserId;

  bool get isDevMode => currentUserId == kDevMockUserId;
  // Fall back to the live auth user: currentUserProvider isn't reactive to
  // OAuth login, so currentUserId can be stale/null right after sign-in.
  String? get userId => currentUserId ?? client.auth.currentUser?.id;
}
