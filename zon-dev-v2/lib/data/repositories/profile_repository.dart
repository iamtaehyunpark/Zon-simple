import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/user_profile.dart';
import '../../core/errors/app_exception.dart';
import '../../core/supabase/supabase_provider.dart';
import '../../core/auth/auth_provider.dart';
import 'base_repository.dart';

part 'profile_repository.g.dart';

/// The viewer's relationship to another account.
/// none = not following · requested = pending approval (private acct) · following = accepted.
enum FollowState { none, requested, following }

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

  /// Toggle follow. Re-following a private account creates a pending request
  /// (server-enforced); following a public account is immediate. Calling again
  /// while a row exists removes it (unfollow / cancel request) → [FollowState.none].
  Future<Either<AppException, FollowState>> follow(String targetUserId) async {
    try {
      final userId = this.userId;
      if (userId == null) return left(const AuthError('Unauthorized'));
      final existing = await client
          .from('follows')
          .select('status')
          .eq('follower_id', userId)
          .eq('following_id', targetUserId)
          .maybeSingle();
      if (existing != null) {
        await client
            .from('follows')
            .delete()
            .eq('follower_id', userId)
            .eq('following_id', targetUserId);
        return right(FollowState.none);
      }
      // The DB trigger sets the real status from the target's privacy; mirror it
      // here for the returned state.
      final target = await client
          .from('profiles')
          .select('is_private')
          .eq('id', targetUserId)
          .single();
      await client.from('follows').insert({
        'follower_id': userId,
        'following_id': targetUserId,
      });
      return right((target['is_private'] as bool? ?? false)
          ? FollowState.requested
          : FollowState.following);
    } catch (e) {
      return left(NetworkError(e.toString()));
    }
  }

  Future<FollowState> followState(String targetUserId) async {
    try {
      final userId = this.userId;
      if (userId == null) return FollowState.none;
      final row = await client
          .from('follows')
          .select('status')
          .eq('follower_id', userId)
          .eq('following_id', targetUserId)
          .maybeSingle();
      if (row == null) return FollowState.none;
      return row['status'] == 'accepted'
          ? FollowState.following
          : FollowState.requested;
    } catch (_) {
      return FollowState.none;
    }
  }

  /// Incoming pending follow requests (people awaiting my approval).
  Future<List<UserProfile>> getFollowRequests() async {
    final userId = this.userId;
    if (userId == null) return [];
    try {
      final data = await client
          .from('follows')
          .select('profiles!follows_follower_id_fkey(*)')
          .eq('following_id', userId)
          .eq('status', 'pending');
      return [
        for (final r in data)
          if (r['profiles'] != null)
            _fromRow(r['profiles'] as Map<String, dynamic>)
      ];
    } catch (_) {
      return [];
    }
  }

  Future<void> approveFollow(String requesterId) async {
    final userId = this.userId;
    if (userId == null) return;
    await client
        .from('follows')
        .update({'status': 'accepted'})
        .eq('follower_id', requesterId)
        .eq('following_id', userId);
  }

  Future<void> denyFollow(String requesterId) async {
    final userId = this.userId;
    if (userId == null) return;
    await client
        .from('follows')
        .delete()
        .eq('follower_id', requesterId)
        .eq('following_id', userId);
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
          .eq('following_id', userId)
          .eq('status', 'accepted');
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
          .eq('follower_id', userId)
          .eq('status', 'accepted');
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
      isPrivate: row['is_private'] as bool? ?? false,
      createdAt: row['created_at'] != null
          ? DateTime.parse(row['created_at'] as String)
          : null,
    );
  }
}
