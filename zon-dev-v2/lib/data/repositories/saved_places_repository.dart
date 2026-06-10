import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../core/errors/app_exception.dart';
import '../../core/supabase/supabase_provider.dart';
import '../../core/auth/auth_provider.dart';
import 'base_repository.dart';

part 'saved_places_repository.g.dart';

class SavedPlace {
  final String placeId;
  final String name;
  final double lat;
  final double lng;
  final String? externalSource;
  final DateTime savedAt;
  const SavedPlace({
    required this.placeId,
    required this.name,
    required this.lat,
    required this.lng,
    this.externalSource,
    required this.savedAt,
  });
}

@riverpod
SavedPlacesRepository savedPlacesRepository(SavedPlacesRepositoryRef ref) =>
    SavedPlacesRepository(
      ref.watch(supabaseClientProvider),
      currentUserId: ref.watch(currentUserProvider)?.id,
    );

class SavedPlacesRepository with BaseRepository {
  @override
  final SupabaseClient client;
  @override
  final String? currentUserId;
  SavedPlacesRepository(this.client, {this.currentUserId});

  Future<Either<AppException, Unit>> save({
    required String placeId,
    required String name,
    required double lat,
    required double lng,
    String? externalSource,
  }) async {
    try {
      final uid = userId;
      if (uid == null) return left(const AuthError('Unauthorized'));
      await client.from('saved_places').upsert({
        'user_id': uid,
        'external_place_id': placeId,
        'place_name': name,
        'lat': lat,
        'lng': lng,
        'external_source': externalSource,
        'saved_at': DateTime.now().toUtc().toIso8601String(),
      });
      return right(unit);
    } catch (e) {
      return left(NetworkError(e.toString()));
    }
  }

  Future<Either<AppException, Unit>> unsave(String placeId) async {
    try {
      final uid = userId;
      if (uid == null) return left(const AuthError('Unauthorized'));
      await client
          .from('saved_places')
          .delete()
          .eq('user_id', uid)
          .eq('external_place_id', placeId);
      return right(unit);
    } catch (e) {
      return left(NetworkError(e.toString()));
    }
  }

  Future<bool> isSaved(String placeId) async {
    try {
      final uid = userId;
      if (uid == null) return false;
      final data = await client
          .from('saved_places')
          .select('external_place_id')
          .eq('user_id', uid)
          .eq('external_place_id', placeId)
          .maybeSingle();
      return data != null;
    } catch (_) {
      return false;
    }
  }

  Future<Either<AppException, List<SavedPlace>>> getAll() async {
    try {
      final uid = userId;
      if (uid == null) return left(const AuthError('Unauthorized'));
      final data = await client
          .from('saved_places')
          .select()
          .eq('user_id', uid)
          .order('saved_at', ascending: false);
      return right((data as List)
          .map((e) => _fromRow(e as Map<String, dynamic>))
          .toList());
    } catch (e) {
      return left(NetworkError(e.toString()));
    }
  }

  SavedPlace _fromRow(Map<String, dynamic> r) => SavedPlace(
        placeId: r['external_place_id'] as String,
        name: r['place_name'] as String,
        lat: (r['lat'] as num).toDouble(),
        lng: (r['lng'] as num).toDouble(),
        externalSource: r['external_source'] as String?,
        savedAt: DateTime.parse(r['saved_at'] as String),
      );
}
