import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase/supabase_provider.dart';

part 'auth_provider.g.dart';

@riverpod
Stream<AuthState> authStateStream(AuthStateStreamRef ref) =>
    ref.watch(supabaseClientProvider).auth.onAuthStateChange;

@riverpod
User? currentUser(CurrentUserRef ref) =>
    ref.watch(supabaseClientProvider).auth.currentUser;
