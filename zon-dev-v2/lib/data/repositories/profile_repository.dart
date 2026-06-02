import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/user_profile.dart';
import '../../core/errors/app_exception.dart';
import '../../core/supabase/supabase_provider.dart';

part 'profile_repository.g.dart';

@riverpod
ProfileRepository profileRepository(ProfileRepositoryRef ref) =>
    ProfileRepository(ref.watch(supabaseClientProvider));

class ProfileRepository {
  final SupabaseClient _client;
  ProfileRepository(this._client);

  Future<Either<AppException, UserProfile>> getProfile(String userId) async {
    try {
      final data = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      return right(_fromRow(data));
    } catch (e) {
      return left(NetworkError(e.toString()));
    }
  }

  Future<Either<AppException, UserProfile>> getMyProfile() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return left(const AuthError('Unauthorized'));
    return getProfile(userId);
  }

  Future<Either<AppException, UserProfile>> updateProfile(
    Map<String, dynamic> updates,
  ) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return left(const AuthError('Unauthorized'));
      final data = await _client
          .from('profiles')
          .update({...updates, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', userId)
          .select()
          .single();
      return right(_fromRow(data));
    } catch (e) {
      return left(NetworkError(e.toString()));
    }
  }

  Future<Either<AppException, bool>> follow(String targetUserId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return left(const AuthError('Unauthorized'));
      final existing = await _client
          .from('follows')
          .select()
          .eq('follower_id', userId)
          .eq('following_id', targetUserId)
          .maybeSingle();
      if (existing != null) {
        await _client
            .from('follows')
            .delete()
            .eq('follower_id', userId)
            .eq('following_id', targetUserId);
        return right(false);
      } else {
        await _client.from('follows').insert({
          'follower_id': userId,
          'following_id': targetUserId,
        });
        return right(true);
      }
    } catch (e) {
      return left(NetworkError(e.toString()));
    }
  }

  Future<bool> isFollowing(String targetUserId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return false;
      final existing = await _client
          .from('follows')
          .select()
          .eq('follower_id', userId)
          .eq('following_id', targetUserId)
          .maybeSingle();
      return existing != null;
    } catch (_) {
      return false;
    }
  }

  UserProfile _fromRow(Map<String, dynamic> row) {
    return UserProfile(
      id: row['id'] as String,
      username: row['username'] as String,
      avatarUrl: row['avatar_url'] as String?,
      bio: row['bio'] as String?,
      stampCount: row['stamp_count'] as int? ?? 0,
      followerCount: row['follower_count'] as int? ?? 0,
      followingCount: row['following_count'] as int? ?? 0,
      createdAt: row['created_at'] != null
          ? DateTime.parse(row['created_at'] as String)
          : null,
    );
  }
}
