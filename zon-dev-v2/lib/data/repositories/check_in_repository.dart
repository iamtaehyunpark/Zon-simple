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

class CheckInRepository with BaseRepository {
  @override
  final SupabaseClient client;
  @override
  final String? currentUserId;
  CheckInRepository(this.client, {this.currentUserId});

  /// Create a check-in. [photoUrls] are already-uploaded storage URLs to attach.
  Future<Either<AppException, CheckIn>> createCheckIn(
    CheckInDraft draft, {
    List<String> photoUrls = const [],
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
            'tagged_user_ids': draft.taggedUserIds,
            'visited_at': DateTime.now().toIso8601String(),
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
      final data = await client.rpc('check_ins_for_day', params: {
        'p_user_id': userId,
        'p_date': date.toIso8601String().substring(0, 10),
      });
      return right((data as List).map((r) => _fromRow(r)).toList());
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
      return right(data.map(_fromRow).toList());
    } catch (e) {
      return left(NetworkError(e.toString()));
    }
  }

  /// Followed users' shared check-ins for [date] (gated by location sharing).
  Future<Either<AppException, List<CheckIn>>> getSharedCheckInsForDay(
      DateTime date) async {
    try {
      final userId = this.userId;
      if (userId == null) return left(const AuthError('Unauthorized'));
      final data = await client.rpc('shared_check_ins_for_day', params: {
        'p_date': date.toIso8601String().substring(0, 10),
      });
      return right((data as List).map((r) => _fromRow(r)).toList());
    } catch (e) {
      return left(NetworkError(e.toString()));
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

  Future<Either<AppException, Unit>> deleteCheckIn(String id) async {
    try {
      await client.from('check_ins').delete().eq('id', id);
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
