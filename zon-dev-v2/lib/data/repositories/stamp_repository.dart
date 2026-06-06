import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/stamp.dart';
import '../models/enums.dart';
import '../../core/errors/app_exception.dart';
import '../../core/supabase/supabase_provider.dart';
import '../../core/auth/auth_provider.dart';
import 'base_repository.dart';

part 'stamp_repository.g.dart';

@riverpod
StampRepository stampRepository(StampRepositoryRef ref) => StampRepository(
      ref.watch(supabaseClientProvider),
      currentUserId: ref.watch(currentUserProvider)?.id,
    );

class StampRepository with BaseRepository {
  @override
  final SupabaseClient client;
  @override
  final String? currentUserId;
  StampRepository(this.client, {this.currentUserId});

  Future<Either<AppException, List<Stamp>>> getMyStampsForDay(
      DateTime day) async {
    try {
      final userId = this.userId;
      if (userId == null) return left(const AuthError('Unauthorized'));
      final data = await client.rpc('stamps_for_local_day', params: {
        'p_date': day.toIso8601String().substring(0, 10),
      });
      return right((data as List)
          .map((r) => _fromRow(r as Map<String, dynamic>))
          .toList());
    } catch (e) {
      return left(NetworkError(e.toString()));
    }
  }

  /// Public stamps from people the user follows within [from, to) (map layer).
  Future<Either<AppException, List<Stamp>>> getFollowingStamps({
    required DateTime from,
    required DateTime to,
  }) async {
    try {
      final userId = this.userId;
      if (userId == null) return left(const AuthError('Unauthorized'));
      final followingIds = await getFollowingIds(userId);
      if (followingIds.isEmpty) return right([]);
      final data = await client
          .from('v_feed_stamps')
          .select()
          .inFilter('user_id', followingIds)
          .gte('visited_at', from.toIso8601String())
          .lt('visited_at', to.toIso8601String())
          .order('visited_at', ascending: false);
      return right(data.map(_fromRow).toList());
    } catch (e) {
      return left(NetworkError(e.toString()));
    }
  }

  Future<Either<AppException, List<Stamp>>> getFeedStamps({
    int limit = 30,
    int offset = 0,
  }) async {
    try {
      final userId = this.userId;
      if (userId == null) return left(const AuthError('Unauthorized'));
      final followingIds = await getFollowingIds(userId);
      final query = followingIds.isEmpty
          ? client.from('v_feed_stamps').select()
          : client
              .from('v_feed_stamps')
              .select()
              .or('user_id.eq.$userId,user_id.in.(${followingIds.join(',')})');
      final data = await query
          // Feed is newest-posted first (when the stamp was generated), not
          // by the visit time it records.
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
      final stamps = data.map(_fromRow).toList();
      return right(await _withEngagement(stamps));
    } catch (e) {
      return left(NetworkError(e.toString()));
    }
  }

Future<Either<AppException, List<Stamp>>> getUserStamps(
    String userId, {
    bool publicOnly = true,
    int limit = 30,
    int offset = 0,
  }) async {
    try {
      var query = client
          .from('stamps')
          .select()
          .eq('user_id', userId);
      if (publicOnly) query = query.eq('visibility', 'public');
      final data = await query
          .order('visited_at', ascending: false)
          .range(offset, offset + limit - 1);
      return right(data.map(_fromRow).toList());
    } catch (e) {
      return left(NetworkError(e.toString()));
    }
  }

  Future<Either<AppException, Stamp>> getStamp(String id) async {
    try {
      final data = await client
          .from('stamps')
          .select()
          .eq('id', id)
          .single();
      var stamp = _fromRow(data);
      // Resolve the current user's like/save state for this stamp.
      final uid = userId;
      if (uid != null) {
        final (like, save) = await (
          client
              .from('stamp_likes')
              .select('stamp_id')
              .eq('stamp_id', id)
              .eq('user_id', uid)
              .maybeSingle(),
          client
              .from('stamp_saves')
              .select('stamp_id')
              .eq('stamp_id', id)
              .eq('user_id', uid)
              .maybeSingle(),
        ).wait;
        stamp = stamp.copyWith(isLiked: like != null, isSaved: save != null);
      }
      return right(stamp);
    } catch (e) {
      return left(NetworkError(e.toString()));
    }
  }

  Future<Either<AppException, Stamp>> updateStamp(
    String id,
    Map<String, dynamic> updates,
  ) async {
    try {
      final data = await client
          .from('stamps')
          .update({...updates, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', id)
          .select()
          .single();
      return right(_fromRow(data));
    } catch (e) {
      return left(NetworkError(e.toString()));
    }
  }

  Future<Either<AppException, Unit>> deleteStamp(String id) async {
    try {
      await client.from('stamps').delete().eq('id', id);
      return right(unit);
    } catch (e) {
      return left(NetworkError(e.toString()));
    }
  }

  /// Photos attached to a stamp, oldest first (id + url for edit/remove).
  Future<List<({String id, String url})>> getStampPhotos(String stampId) async {
    try {
      final data = await client
          .from('photos')
          .select('id, storage_url')
          .eq('stamp_id', stampId)
          .order('created_at', ascending: true);
      return [
        for (final r in data)
          (id: r['id'] as String, url: r['storage_url'] as String)
      ];
    } catch (_) {
      return [];
    }
  }

  /// Photo URLs grouped by stamp id (for list rendering).
  Future<Map<String, List<String>>> photoUrlsByStamp(List<String> ids) async {
    if (ids.isEmpty) return {};
    try {
      final rows = await client
          .from('photos')
          .select('stamp_id, storage_url')
          .inFilter('stamp_id', ids)
          .order('created_at', ascending: true);
      final map = <String, List<String>>{};
      for (final r in rows) {
        final sid = r['stamp_id'] as String?;
        if (sid != null) (map[sid] ??= []).add(r['storage_url'] as String);
      }
      return map;
    } catch (_) {
      return {};
    }
  }

  Future<void> addStampPhotos(String stampId, List<String> urls) async {
    final userId = this.userId;
    if (userId == null || urls.isEmpty) return;
    await client.from('photos').insert([
      for (final u in urls)
        {'user_id': userId, 'stamp_id': stampId, 'storage_url': u},
    ]);
  }

  Future<void> deletePhoto(String photoId) async {
    await client.from('photos').delete().eq('id', photoId);
  }

  Future<Either<AppException, Unit>> toggleLike(String stampId) =>
      _toggleMembership('stamp_likes', stampId);

  Future<Either<AppException, Unit>> toggleSave(String stampId) =>
      _toggleMembership('stamp_saves', stampId);

  Future<Either<AppException, Unit>> _toggleMembership(
    String table,
    String stampId,
  ) async {
    try {
      final userId = this.userId;
      if (userId == null) return left(const AuthError('Unauthorized'));
      final deleted = await client
          .from(table)
          .delete()
          .eq('stamp_id', stampId)
          .eq('user_id', userId)
          .select();
      if (deleted.isEmpty) {
        await client
            .from(table)
            .insert({'stamp_id': stampId, 'user_id': userId});
      }
      return right(unit);
    } catch (e) {
      return left(NetworkError(e.toString()));
    }
  }

  /// Stamps the current user has saved (bookmarks).
  Future<Either<AppException, List<Stamp>>> getSavedStamps({
    int limit = 30,
    int offset = 0,
  }) async {
    try {
      final userId = this.userId;
      if (userId == null) return left(const AuthError('Unauthorized'));
      final saves = await client
          .from('stamp_saves')
          .select('stamp_id, created_at')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
      final ids = saves.map((r) => r['stamp_id'] as String).toList();
      if (ids.isEmpty) return right([]);
      final data = await client.from('stamps').select().inFilter('id', ids);
      // Preserve save order, mark as saved.
      final byId = {for (final r in data) r['id'] as String: _fromRow(r)};
      final ordered = [
        for (final id in ids)
          if (byId[id] != null) byId[id]!.copyWith(isSaved: true)
      ];
      return right(ordered);
    } catch (e) {
      return left(NetworkError(e.toString()));
    }
  }

  Future<Either<AppException, List<Stamp>>> nearbyStamps(
    double lat,
    double lng, {
    double radiusM = 100,
  }) async {
    try {
      final userId = this.userId;
      if (userId == null) return left(const AuthError('Unauthorized'));
      final data = await client.rpc('stamps_within_radius', params: {
        'p_user_id': userId,
        'user_lat': lat,
        'user_lng': lng,
        'radius_m': radiusM,
      });
      return right((data as List).map((r) => _fromRow(r)).toList());
    } catch (e) {
      return left(NetworkError(e.toString()));
    }
  }

  /// Merge isLiked/isSaved state for the current user into a list of stamps.
  Future<List<Stamp>> _withEngagement(List<Stamp> stamps) async {
    final userId = this.userId;
    if (userId == null || stamps.isEmpty) return stamps;
    final ids = stamps.map((s) => s.id).toList();

    final likes = await client
        .from('stamp_likes')
        .select('stamp_id')
        .eq('user_id', userId)
        .inFilter('stamp_id', ids);
    final saves = await client
        .from('stamp_saves')
        .select('stamp_id')
        .eq('user_id', userId)
        .inFilter('stamp_id', ids);

    final likedIds = {for (final r in likes) r['stamp_id'] as String};
    final savedIds = {for (final r in saves) r['stamp_id'] as String};

    return stamps
        .map((s) => s.copyWith(
              isLiked: likedIds.contains(s.id),
              isSaved: savedIds.contains(s.id),
            ))
        .toList();
  }

  Stamp _fromRow(Map<String, dynamic> row) {
    return Stamp(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      placeName: row['place_name'] as String,
      normalizedPlaceName: row['normalized_place_name'] as String?,
      lat: (row['lat'] as num).toDouble(),
      lng: (row['lng'] as num).toDouble(),
      externalPlaceId: row['external_place_id'] as String?,
      externalSource: row['external_source'] as String?,
      checkInId: row['check_in_id'] as String?,
      visibility: (row['visibility'] as String) == 'public'
          ? StampVisibility.public
          : StampVisibility.private,
      coverPhotoUrl: row['cover_photo_url'] as String?,
      caption: row['caption'] as String?,
      sensoryTags: List<String>.from(row['sensory_tags'] ?? []),
      taggedUserIds: (row['tagged_user_ids'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      visitedAt: DateTime.parse(row['visited_at'] as String),
      likeCount: row['like_count'] as int? ?? 0,
      commentCount: row['comment_count'] as int? ?? 0,
      photoCount: row['photo_count'] as int? ?? 0,
      // Present when fetching from v_feed_stamps view
      username: row['username'] as String?,
      avatarUrl: row['avatar_url'] as String?,
      createdAt: row['created_at'] != null
          ? DateTime.parse(row['created_at'] as String)
          : null,
      updatedAt: row['updated_at'] != null
          ? DateTime.parse(row['updated_at'] as String)
          : null,
    );
  }
}
