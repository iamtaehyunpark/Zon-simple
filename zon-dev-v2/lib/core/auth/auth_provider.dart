import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase/supabase_provider.dart';

part 'auth_provider.g.dart';

@riverpod
Stream<AuthState> authStateStream(AuthStateStreamRef ref) =>
    ref.watch(supabaseClientProvider).auth.onAuthStateChange;

@riverpod
User? currentUser(CurrentUserRef ref) {
  // Re-evaluate on every auth-state change so currentUser tracks login/logout —
  // and so repositories that read currentUserId rebuild right after OAuth sign-in.
  ref.watch(authStateStreamProvider);
  return ref.watch(supabaseClientProvider).auth.currentUser;
}
