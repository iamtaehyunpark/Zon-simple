import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase/supabase_provider.dart';

part 'auth_provider.g.dart';

const kDevMockUserId = '00000000-0000-0000-0000-000000000001';

@riverpod
class DevLoggedIn extends _$DevLoggedIn {
  @override
  bool build() {
    try {
      final box = Hive.box('dev_settings');
      return box.get('is_logged_in', defaultValue: false) as bool;
    } catch (e) {
      debugPrint('Hive dev_settings box error: $e');
      return false;
    }
  }

  void login() {
    try {
      final box = Hive.box('dev_settings');
      box.put('is_logged_in', true);
    } catch (e) {
      debugPrint('Hive put error: $e');
    }
    state = true;
  }

  void logout() {
    try {
      final box = Hive.box('dev_settings');
      box.put('is_logged_in', false);
    } catch (e) {
      debugPrint('Hive put error: $e');
    }
    state = false;
  }
}

@riverpod
Stream<AuthState> authStateStream(AuthStateStreamRef ref) {
  final isDevLoggedIn = ref.watch(devLoggedInProvider);
  
  if (isDevLoggedIn) {
    return Stream.value(
      AuthState(
        AuthChangeEvent.signedIn,
        Session(
          accessToken: 'mock-access-token',
          tokenType: 'bearer',
          user: const User(
            id: '00000000-0000-0000-0000-000000000001',
            appMetadata: {},
            userMetadata: {
              'full_name': 'Dev User',
            },
            aud: 'authenticated',
            createdAt: '',
          ),
        ),
      ),
    );
  }

  try {
    return ref.watch(supabaseClientProvider).auth.onAuthStateChange;
  } catch (_) {
    return const Stream.empty();
  }
}

@riverpod
User? currentUser(CurrentUserRef ref) {
  final isDevLoggedIn = ref.watch(devLoggedInProvider);
  
  if (isDevLoggedIn) {
    return const User(
      id: '00000000-0000-0000-0000-000000000001',
      appMetadata: {},
      userMetadata: {
        'full_name': 'Dev User',
        'avatar_url': 'https://placeholder.co/150',
      },
      aud: 'authenticated',
      createdAt: '',
    );
  }

  try {
    return ref.watch(supabaseClientProvider).auth.currentUser;
  } catch (_) {
    return null;
  }
}

