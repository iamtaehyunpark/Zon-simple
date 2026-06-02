import 'package:supabase_flutter/supabase_flutter.dart';
import 'place_models.dart';
import 'place_service.dart';

/// Google Places — routed through the `match-place` edge function so the
/// API key is never exposed on the client.
class GooglePlaceService implements PlaceService {
  final SupabaseClient _client;
  GooglePlaceService(this._client);

  @override
  PlaceProvider get provider => PlaceProvider.google;

  @override
  Future<List<PlaceResult>> nearby(double lat, double lng) =>
      _invoke(lat: lat, lng: lng);

  @override
  Future<List<PlaceResult>> search(
          String query, double lat, double lng) =>
      _invoke(lat: lat, lng: lng, query: query);

  Future<List<PlaceResult>> _invoke({
    required double lat,
    required double lng,
    String? query,
  }) async {
    try {
      final session = _client.auth.currentSession;
      if (session == null) return [];
      final response = await _client.functions.invoke(
        'match-place',
        body: {
          'lat': lat,
          'lng': lng,
          'provider': 'google',
          if (query != null && query.isNotEmpty) 'query': query,
        },
        headers: {'Authorization': 'Bearer ${session.accessToken}'},
      );
      final data = response.data;
      final results = (data is Map ? data['results'] as List? : null) ?? [];
      return results
          .map((r) => PlaceResult(
                placeId: r['place_id'] as String,
                name: r['name'] as String,
                address: r['address'] as String?,
                lat: (r['lat'] as num).toDouble(),
                lng: (r['lng'] as num).toDouble(),
                categories: List<String>.from(r['types'] ?? []),
                externalSource: 'google_places',
              ))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
