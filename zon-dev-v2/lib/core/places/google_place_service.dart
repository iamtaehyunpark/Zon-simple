import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'place_models.dart';
import 'place_service.dart';

/// Google Places API — called directly from the client.
/// Nearby search uses the coordinate + radius for true location awareness.
/// Text search uses the coordinate as a location bias.
class GooglePlaceService implements PlaceService {
  final Dio _dio;
  final String _apiKey;

  GooglePlaceService()
      : _apiKey = dotenv.env['GOOGLE_PLACES_API_KEY'] ?? '',
        _dio = Dio(BaseOptions(
          baseUrl: 'https://maps.googleapis.com/maps/api/place/',
        ));

  @override
  PlaceProvider get provider => PlaceProvider.google;

  @override
  Future<List<PlaceResult>> nearby(double lat, double lng) async {
    if (_apiKey.isEmpty) return [];
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        'nearbysearch/json',
        queryParameters: {
          'location': '$lat,$lng',
          'radius': 20, // 20m — only the place you're physically standing at
          'language': 'ko',
          'key': _apiKey,
        },
      );
      debugPrint('[GooglePlaces] nearby status=${res.data?['status']}');
      return _parse(res.data);
    } catch (e) {
      debugPrint('[GooglePlaces] nearby error: $e');
      return [];
    }
  }

  @override
  Future<List<PlaceResult>> search(String query, double lat, double lng) async {
    if (_apiKey.isEmpty || query.trim().isEmpty) return [];
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        'textsearch/json',
        queryParameters: {
          'query': query,
          'location': '$lat,$lng',
          'radius': 2000,
          'language': 'ko',
          'key': _apiKey,
        },
      );
      debugPrint('[GooglePlaces] search status=${res.data?['status']}');
      return _parse(res.data);
    } catch (e) {
      debugPrint('[GooglePlaces] search error: $e');
      return [];
    }
  }

  List<PlaceResult> _parse(Map<String, dynamic>? data) {
    final results = data?['results'] as List? ?? [];
    return results.map((r) {
      final loc = (r['geometry'] as Map)['location'] as Map;
      return PlaceResult(
        placeId: r['place_id'] as String? ?? '',
        name: r['name'] as String? ?? '',
        address: (r['vicinity'] ?? r['formatted_address']) as String?,
        lat: (loc['lat'] as num).toDouble(),
        lng: (loc['lng'] as num).toDouble(),
        categories: List<String>.from(r['types'] ?? []),
        externalSource: 'google_places',
      );
    }).toList();
  }
}
