// ignore_for_file: avoid_print, depend_on_referenced_packages
import 'package:supabase/supabase.dart';
import 'dart:io';

// Mock simple storage to satisfy Gotrue if needed
class MockGotrueAsyncStorage extends GotrueAsyncStorage {
  final Map<String, String> _storage = {};
  @override
  Future<String?> getItem({required String key}) async => _storage[key];
  @override
  Future<void> removeItem({required String key}) async => _storage.remove(key);
  @override
  Future<void> setItem({required String key, required String value}) async {
    _storage[key] = value;
  }
}

void main() async {
  // Load .env manually
  final file = File('.env');
  final lines = file.readAsLinesSync();
  final env = <String, String>{};
  for (final line in lines) {
    if (line.isEmpty || line.startsWith('#')) continue;
    final parts = line.split('=');
    if (parts.length >= 2) {
      env[parts[0].trim()] = parts.sublist(1).join('=').trim();
    }
  }

  final supabaseUrl = env['SUPABASE_URL']!;
  final supabaseAnonKey = env['SUPABASE_ANON_KEY']!;

  print('Supabase URL: $supabaseUrl');

  final client = SupabaseClient(
    supabaseUrl,
    supabaseAnonKey,
    authOptions: AuthClientOptions(
      pkceAsyncStorage: MockGotrueAsyncStorage(),
      authFlowType: AuthFlowType.implicit,
    ),
  );

  // Use gmail.com
  const email = 'test_friend_debug@gmail.com';
  const password = 'TestPassword123!';

  print('Signing up test user: $email');
  final authRes = await client.auth.signUp(email: email, password: password);
  final user = authRes.user;
  if (user == null) {
    print('Sign up failed');
    return;
  }
  print('Signed up successfully. User ID: ${user.id}');

  // Create profile
  try {
    print('Creating profile...');
    await client.from('profiles').insert({
      'id': user.id,
      'username': 'testuser_debug',
      'display_name': 'Test User',
    });
    print('Profile created successfully.');
  } catch (e) {
    print('Profile creation error: $e');
  }

  // Find another user
  final profiles =
      await client.from('profiles').select('id, username').neq('id', user.id).limit(1);
  if ((profiles as List).isEmpty) {
    print('No other profiles found in DB');
    return;
  }
  final targetId = profiles[0]['id'] as String;
  final targetName = profiles[0]['username'] as String;
  print('Target user: $targetName ($targetId)');

  final uid = user.id;
  final a = uid.compareTo(targetId) < 0 ? uid : targetId;
  final b = uid.compareTo(targetId) < 0 ? targetId : uid;

  // Try insert
  try {
    print('Inserting friendship request...');
    final insertRes = await client.from('friendships').insert({
      'user_a': a,
      'user_b': b,
      'requested_by': uid,
      'status': 'pending',
    }).select();
    print('Insert success: $insertRes');
  } catch (e) {
    print('ERROR INSERTING FRIENDSHIP: $e');
  }

  // Try delete
  try {
    print('Deleting friendship request (unsend)...');
    final deleteRes = await client
        .from('friendships')
        .delete()
        .eq('user_a', a)
        .eq('user_b', b)
        .select();
    print('Delete success: $deleteRes');
  } catch (e) {
    print('ERROR DELETING FRIENDSHIP: $e');
  }

  // Clean up
  try {
    await client.from('profiles').delete().eq('id', user.id);
    print('Profile cleaned up.');
  } catch (_) {}
}
