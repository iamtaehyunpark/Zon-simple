import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/check_in.dart';
import '../models/enums.dart';
import '../../core/errors/app_exception.dart';
import '../../core/supabase/supabase_provider.dart';
import '../../core/auth/auth_provider.dart';
import 'base_repository.dart';

part 'check_in_repository.g.dart';

@riverpod
CheckInRepository checkInRepository(CheckInRepositoryRef ref) =>
    CheckInRepository(
      ref.watch(supabaseClientProvider),
      currentUserId: ref.watch(currentUserProvider)?.id,
    );

/// One author's recent public check-ins, grouped for the feed "stories" rail.
class CheckInStory {
  final String userId;
  final String username;
  final String? avatarUrl;
  final List<CheckIn> checkIns; // newest first
  const CheckInStory({
    required this.userId,
    required this.username,
    required this.avatarUrl,
    required this.checkIns,
  });
}

class CheckInRepository with BaseRepository {
  @override
  final SupabaseClient client;
  @override
  final String? currentUserId;
  CheckInRepository(this.client, {this.currentUserId});

  /// Create a check-in. [photoUrls] are already-uploaded storage URLs to attach.
  /// [visitedAt] defaults to now (use the photo's taken time for photo imports).
  Future<Either<AppException, CheckIn>> createCheckIn(
    CheckInDraft draft, {
    List<String> photoUrls = const [],
    DateTime? visitedAt,
  }) async {
    try {
      final userId = this.userId;
      if (userId == null) return left(const AuthError('Unauthorized'));
      final row = await client
          .from('check_ins')
          .insert({
            'user_id': userId,
            'place_name': draft.placeName,
            'normalized_place_name': draft.placeName.toLowerCase().trim(),
            'lat': draft.lat,
            'lng': draft.lng,
            'external_place_id': draft.externalPlaceId,
            'external_source': draft.externalSource,
            'note': draft.note,
            'source': draft.source.name,
            'visibility': draft.visibility.name,
            'tagged_user_ids': draft.taggedUserIds,
            'visited_at': (visitedAt ?? DateTime.now()).toIso8601String(),
          })
          .select()
          .single();
      final checkIn = _fromRow(row);
      if (photoUrls.isNotEmpty) {
        await client.from('photos').insert([
          for (final url in photoUrls)
            {'user_id': userId, 'check_in_id': checkIn.id, 'storage_url': url},
        ]);
      }
      return right(checkIn.copyWith(
        photoUrls: photoUrls,
        photoCount: photoUrls.length,
      ));
    } catch (e) {
      return left(NetworkError(e.toString()));
    }
  }

  Future<Either<AppException, List<CheckIn>>> getForDay(DateTime date) async {
    try {
      final userId = this.userId;
      if (userId == null) return left(const AuthError('Unauthorized'));
      final data = await client.rpc('check_ins_for_local_day', params: {
        'p_date': isoDate(date),
      });
      return right((data as List)
          .map((r) => _fromRow(r as Map<String, dynamic>))
          .toList());
    } catch (e) {
      return left(NetworkError(e.toString()));
    }
  }

  Future<Either<AppException, List<CheckIn>>> getMyCheckInsForRange({
    required DateTime from,
    required DateTime to,
  }) async {
    try {
      final userId = this.userId;
      if (userId == null) return left(const AuthError('Unauthorized'));
      final data = await client
          .from('check_ins')
          .select()
          .eq('user_id', userId)
          .gte('visited_at', from.toIso8601String())
          .lt('visited_at', to.toIso8601String())
          .order('visited_at', ascending: false);
      return right((data as List)
          .map((r) => _fromRow(r as Map<String, dynamic>))
          .toList());
    } catch (e) {
      return left(NetworkError(e.toString()));
    }
  }


  Future<Either<AppException, List<CheckIn>>> getMyCheckIns({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final userId = this.userId;
      if (userId == null) return left(const AuthError('Unauthorized'));
      final data = await client
          .from('check_ins')
          .select()
          .eq('user_id', userId)
          .order('visited_at', ascending: false)
          .range(offset, offset + limit - 1);
      return right((data as List).map((r) => _fromRow(r as Map<String, dynamic>)).toList());
    } catch (e) {
      return left(NetworkError(e.toString()));
    }
  }

  /// Last-24h public check-ins from people the viewer follows (map layer).
  /// Separate from getStories() which groups by author for the feed rail.
  Future<Either<AppException, List<CheckIn>>> getFollowingPublicCheckIns() async {
    try {
      final userId = this.userId;
      if (userId == null) return left(const AuthError('Unauthorized'));
      final ids = await getFollowingIds(userId);
      if (ids.isEmpty) return right([]);
      final since = DateTime.now().subtract(const Duration(hours: 24));
      final data = await client
          .from('check_ins')
          .select()
          .inFilter('user_id', ids)
          .eq('visibility', 'public')
          .gte('visited_at', since.toIso8601String())
          .order('visited_at', ascending: false);
      return right((data as List)
          .map((r) => _fromRow(r as Map<String, dynamic>))
          .toList());
    } catch (e) {
      return left(NetworkError(e.toString()));
    }
  }

  /// Recent (last 24h) public check-ins from people you follow + yourself,
  /// grouped per author for the feed "stories" rail. Your own story sorts first;
  /// others by most-recent activity.
  Future<List<CheckInStory>> getStories() async {
    final userId = this.userId;
    if (userId == null) return [];
    try {
      final followingIds = await getFollowingIds(userId);
      final ids = {userId, ...followingIds}.toList();
      final since = DateTime.now().subtract(const Duration(hours: 24));
      final rows = await client
          .from('check_ins')
          .select('*, profiles!check_ins_user_id_fkey(username, avatar_url)')
          .inFilter('user_id', ids)
          .eq('visibility', 'public')
          .gte('visited_at', since.toIso8601String())
          .order('visited_at', ascending: false);

      // Attach photo URLs so the story viewer is self-contained.
      final checkIns = [for (final r in rows) _fromRow(r)];
      final photos = await photoUrlsByCheckIn([for (final c in checkIns) c.id]);

      final byUser = <String, CheckInStory>{};
      final order = <String>[];
      for (final r in rows) {
        final ci = _fromRow(r)
            .copyWith(photoUrls: photos[r['id'] as String] ?? const []);
        final prof = r['profiles'] as Map<String, dynamic>?;
        final existing = byUser[ci.userId];
        if (existing == null) {
          order.add(ci.userId);
          byUser[ci.userId] = CheckInStory(
            userId: ci.userId,
            username: prof?['username'] as String? ?? 'someone',
            avatarUrl: prof?['avatar_url'] as String?,
            checkIns: [ci],
          );
        } else {
          existing.checkIns.add(ci);
        }
      }
      final stories = [for (final id in order) byUser[id]!];
      stories.sort((a, b) {
        if (a.userId == userId) return -1;
        if (b.userId == userId) return 1;
        return 0; // already in most-recent order from the query
      });
      return stories;
    } catch (e) {
      debugPrint('getStories: $e');
      return [];
    }
  }

  Future<Either<AppException, CheckIn>> getCheckIn(String id) async {
    try {
      final row =
          await client.from('check_ins').select().eq('id', id).single();
      final checkIn = _fromRow(row);
      final photos = await client
          .from('photos')
          .select('storage_url')
          .eq('check_in_id', id);
      final stamp = await client
          .from('stamps')
          .select('id')
          .eq('check_in_id', id)
          .maybeSingle();
      return right(checkIn.copyWith(
        photoUrls: photos.map((p) => p['storage_url'] as String).toList(),
        stampId: stamp?['id'] as String?,
      ));
    } catch (e) {
      return left(NetworkError(e.toString()));
    }
  }

  Future<Either<AppException, Unit>> updateCheckIn(
      String id, Map<String, dynamic> updates) async {
    try {
      await client.from('check_ins').update(
          {...updates, 'updated_at': DateTime.now().toIso8601String()}).eq(
          'id', id);
      return right(unit);
    } catch (e) {
      return left(NetworkError(e.toString()));
    }
  }

  Future<Either<AppException, Unit>> deleteCheckIn(String id) async {
    try {
      await client.from('check_ins').delete().eq('id', id);
      return right(unit);
    } catch (e) {
      return left(NetworkError(e.toString()));
    }
  }

  /// Absorb [intoId] into [keepId]: re-point photos, append note, delete [intoId].
  /// The caller decides which is "keep" (typically the earlier / primary one).
  Future<Either<AppException, Unit>> mergeCheckIns(
      String keepId, String intoId) async {
    try {
      // 1. Move photos
      await client
          .from('photos')
          .update({'check_in_id': keepId})
          .eq('check_in_id', intoId);

      // 2. Append note
      final rows = await client
          .from('check_ins')
          .select('id, note')
          .inFilter('id', [keepId, intoId]);
      final noteFor = {for (final r in rows) r['id'] as String: r['note'] as String?};
      final intoNote = noteFor[intoId]?.trim() ?? '';
      if (intoNote.isNotEmpty) {
        final keepNote = noteFor[keepId]?.trim() ?? '';
        final merged = [keepNote, intoNote]
            .where((n) => n.isNotEmpty)
            .join('\n');
        await client
            .from('check_ins')
            .update({'note': merged, 'updated_at': DateTime.now().toIso8601String()})
            .eq('id', keepId);
      }

      // 3. Delete absorbed check-in
      await client.from('check_ins').delete().eq('id', intoId);
      return right(unit);
    } catch (e) {
      return left(NetworkError(e.toString()));
    }
  }

  /// Promote a check-in into a stamp (1 check-in → at most 1 stamp).
  /// Copies place + photos over and links `stamps.check_in_id`. Returns the
  /// stamp id (the existing one if already promoted).
  Future<Either<AppException, String>> promoteToStamp(
    String checkInId, {
    required StampVisibility visibility,
    String? caption,
    List<String> sensoryTags = const [],
    List<String> taggedUserIds = const [],
  }) async {
    try {
      final userId = this.userId;
      if (userId == null) return left(const AuthError('Unauthorized'));

      final existing = await client
          .from('stamps')
          .select('id')
          .eq('check_in_id', checkInId)
          .maybeSingle();
      if (existing != null) return right(existing['id'] as String);

      final ci =
          await client.from('check_ins').select().eq('id', checkInId).single();
      final photos = await client
          .from('photos')
          .select('id, storage_url')
          .eq('check_in_id', checkInId);
      final coverUrl =
          photos.isNotEmpty ? photos.first['storage_url'] as String : null;

      final stamp = await client
          .from('stamps')
          .insert({
            'user_id': userId,
            'check_in_id': checkInId,
            'place_name': ci['place_name'],
            'normalized_place_name': ci['normalized_place_name'],
            'lat': ci['lat'],
            'lng': ci['lng'],
            'external_place_id': ci['external_place_id'],
            'external_source': ci['external_source'],
            'visibility': visibility.name,
            'caption': caption,
            'sensory_tags': sensoryTags,
            'tagged_user_ids': taggedUserIds,
            'cover_photo_url': coverUrl,
            'visited_at': ci['visited_at'],
          })
          .select('id')
          .single();
      final stampId = stamp['id'] as String;

      // Re-point the check-in's photos to the new stamp (they belong to both).
      if (photos.isNotEmpty) {
        await client
            .from('photos')
            .update({'stamp_id': stampId})
            .eq('check_in_id', checkInId);
      }
      return right(stampId);
    } catch (e) {
      return left(NetworkError(e.toString()));
    }
  }

  /// Photo URLs grouped by check-in id (for list rendering).
  Future<Map<String, List<String>>> photoUrlsByCheckIn(
      List<String> ids) async {
    if (ids.isEmpty) return {};
    try {
      final rows = await client
          .from('photos')
          .select('check_in_id, storage_url')
          .inFilter('check_in_id', ids)
          .order('created_at', ascending: true);
      final map = <String, List<String>>{};
      for (final r in rows) {
        final cid = r['check_in_id'] as String?;
        if (cid != null) (map[cid] ??= []).add(r['storage_url'] as String);
      }
      return map;
    } catch (_) {
      return {};
    }
  }

  /// A check-in's photos with ids (for the editor's remove action).
  Future<List<({String id, String url})>> getCheckInPhotos(
      String checkInId) async {
    try {
      final rows = await client
          .from('photos')
          .select('id, storage_url')
          .eq('check_in_id', checkInId)
          .order('created_at', ascending: true);
      return [
        for (final r in rows)
          (id: r['id'] as String, url: r['storage_url'] as String)
      ];
    } catch (_) {
      return [];
    }
  }

  Future<void> addCheckInPhotos(String checkInId, List<String> urls) async {
    final uid = userId;
    if (uid == null || urls.isEmpty) return;
    await client.from('photos').insert([
      for (final u in urls)
        {'user_id': uid, 'check_in_id': checkInId, 'storage_url': u},
    ]);
  }

  Future<void> deletePhoto(String photoId) async {
    await client.from('photos').delete().eq('id', photoId);
  }

  Future<void> deletePhotoByUrl(String url) async {
    await client.from('photos').delete().eq('storage_url', url);
  }

  /// Day-of-month → visit count for [month] (for the calendar badges).
  /// A stamp is an advanced check-in, so visits = check-ins + stamps; promoted
  /// check-ins are already counted, so we only add stamps that have no check-in.
  Future<Map<int, int>> monthlyVisitCounts(DateTime month) async {
    final uid = userId;
    if (uid == null) return {};
    try {
      final rows = await client.rpc('monthly_visit_counts', params: {
        'p_year': month.year,
        'p_month': month.month,
      });
      final map = <int, int>{};
      for (final r in (rows as List)) {
        map[r['day'] as int] = (r['cnt'] as num).toInt();
      }
      return map;
    } catch (_) {
      return {};
    }
  }

  CheckIn _fromRow(Map<String, dynamic> row) {
    return CheckIn(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      placeName: row['place_name'] as String,
      normalizedPlaceName: row['normalized_place_name'] as String?,
      lat: (row['lat'] as num).toDouble(),
      lng: (row['lng'] as num).toDouble(),
      externalPlaceId: row['external_place_id'] as String?,
      externalSource: row['external_source'] as String?,
      note: row['note'] as String?,
      source: _sourceFromString(row['source'] as String?),
      visibility: row['visibility'] == 'public'
          ? StampVisibility.public
          : StampVisibility.private,
      taggedUserIds: (row['tagged_user_ids'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      photoCount: row['photo_count'] as int? ?? 0,
      visitedAt: DateTime.parse(row['visited_at'] as String),
      createdAt: row['created_at'] != null
          ? DateTime.parse(row['created_at'] as String)
          : null,
      updatedAt: row['updated_at'] != null
          ? DateTime.parse(row['updated_at'] as String)
          : null,
    );
  }

  CheckInSource _sourceFromString(String? s) => switch (s) {
        'photo' => CheckInSource.photo,
        'auto' => CheckInSource.auto,
        _ => CheckInSource.manual,
      };
}
