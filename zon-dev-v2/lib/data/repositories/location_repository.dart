import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/raw_location_event.dart';
import '../models/enums.dart';
import '../../core/errors/app_exception.dart';
import '../../core/supabase/supabase_provider.dart';
import '../../core/auth/auth_provider.dart';
import 'base_repository.dart';

part 'location_repository.g.dart';

@riverpod
LocationRepository locationRepository(LocationRepositoryRef ref) => LocationRepository(
      ref.watch(supabaseClientProvider),
      currentUserId: ref.watch(currentUserProvider)?.id,
    );

class LocationRepository with BaseRepository {
  @override
  final SupabaseClient client;
  @override
  final String? currentUserId;
  LocationRepository(this.client, {this.currentUserId});

  Future<Either<AppException, int>> batchIngest(
    List<RawLocationEvent> events,
  ) async {
    try {
      final userId = this.userId;
      if (userId == null) return left(const AuthError('Unauthorized'));
      if (isDevMode) return right(events.length);

      final session = client.auth.currentSession;
      if (session == null) return left(const AuthError('Unauthorized'));

      final response = await client.functions.invoke(
        'ingest-location',
        body: events
            .map((e) => {
                  'lat': e.lat,
                  'lng': e.lng,
                  'accuracy_m': e.accuracyM,
                  'source': e.source.dbValue,
                  'captured_at': e.capturedAt.toIso8601String(),
                })
            .toList(),
        headers: {'Authorization': 'Bearer ${session.accessToken}'},
      );

      final inserted = (response.data as Map?)?['inserted'] as int? ?? 0;
      return right(inserted);
    } catch (e) {
      return left(NetworkError(e.toString()));
    }
  }

  Future<Either<AppException, List<RawLocationEvent>>> getRouteForDay(
    DateTime date,
  ) async {
    try {
      final userId = this.userId;
      if (userId == null) return left(const AuthError('Unauthorized'));
      final data = await client.rpc('route_events_for_day', params: {
        'p_user_id': userId,
        'p_date': date.toIso8601String().substring(0, 10),
      });
      return right(
        (data as List).map((r) => _fromRow(r)).toList(),
      );
    } catch (e) {
      return left(NetworkError(e.toString()));
    }
  }

  RawLocationEvent _fromRow(Map<String, dynamic> row) {
    return RawLocationEvent(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      lat: (row['lat'] as num).toDouble(),
      lng: (row['lng'] as num).toDouble(),
      accuracyM: (row['accuracy_m'] as num?)?.toDouble(),
      source: LocationSource.fromString(row['source'] as String),
      capturedAt: DateTime.parse(row['captured_at'] as String),
      stampId: row['stamp_id'] as String?,
      photoId: row['photo_id'] as String?,
      geocodedName: row['geocoded_name'] as String?,
    );
  }
}
