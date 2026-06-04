import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/user_profile.dart';
import '../../core/errors/app_exception.dart';
import '../../core/supabase/supabase_provider.dart';
import '../../core/auth/auth_provider.dart';
import 'base_repository.dart';

part 'profile_repository.g.dart';

@riverpod
ProfileRepository profileRepository(ProfileRepositoryRef ref) => ProfileRepository(
      ref.watch(supabaseClientProvider),
      currentUserId: ref.watch(currentUserProvider)?.id,
    );

class ProfileRepository with BaseRepository {
  @override
  final SupabaseClient client;
  @override
  final String? currentUserId;
  ProfileRepository(this.client, {this.currentUserId});

  Future<Either<AppException, UserProfile>> getProfile(String userId) async {
    try {
      final data = await client
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
    final userId = this.userId;
    if (userId == null) return left(const AuthError('Unauthorized'));
    return getProfile(userId);
  }

  Future<Either<AppException, UserProfile>> updateProfile(
    Map<String, dynamic> updates,
  ) async {
    try {
      final userId = this.userId;
      if (userId == null) return left(const AuthError('Unauthorized'));
      final data = await client
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
      final userId = this.userId;
      if (userId == null) return left(const AuthError('Unauthorized'));
      final existing = await client
          .from('follows')
          .select()
          .eq('follower_id', userId)
          .eq('following_id', targetUserId)
          .maybeSingle();
      if (existing != null) {
        await client
            .from('follows')
            .delete()
            .eq('follower_id', userId)
            .eq('following_id', targetUserId);
        return right(false);
      } else {
        await client.from('follows').insert({
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
      final userId = this.userId;
      if (userId == null) return false;
      final existing = await client
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

  Future<List<UserProfile>> searchUsers(String query) async {
    final q = query.trim();
    if (q.isEmpty) return [];
    try {
      final data = await client
          .from('profiles')
          .select()
          .or('username.ilike.%$q%,display_name.ilike.%$q%')
          .limit(30);
      return data.map(_fromRow).toList();
    } catch (_) {
      return [];
    }
  }

  /// Profiles that follow [userId].
  Future<List<UserProfile>> getFollowers(String userId) async {
    try {
      final data = await client
          .from('follows')
          .select('profiles!follows_follower_id_fkey(*)')
          .eq('following_id', userId);
      return [
        for (final r in data)
          if (r['profiles'] != null)
            _fromRow(r['profiles'] as Map<String, dynamic>)
      ];
    } catch (_) {
      return [];
    }
  }

  /// Profiles that [userId] follows.
  Future<List<UserProfile>> getFollowing(String userId) async {
    try {
      final data = await client
          .from('follows')
          .select('profiles!follows_following_id_fkey(*)')
          .eq('follower_id', userId);
      return [
        for (final r in data)
          if (r['profiles'] != null)
            _fromRow(r['profiles'] as Map<String, dynamic>)
      ];
    } catch (_) {
      return [];
    }
  }

  Future<List<UserProfile>> getProfilesByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    try {
      final data = await client.from('profiles').select().inFilter('id', ids);
      return data.map(_fromRow).toList();
    } catch (_) {
      return [];
    }
  }

  UserProfile _fromRow(Map<String, dynamic> row) {
    return UserProfile(
      id: row['id'] as String,
      username: row['username'] as String,
      displayName: row['display_name'] as String?,
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
