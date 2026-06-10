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
        )) {
    if (_apiKey.isEmpty) {
      debugPrint('[GooglePlaceService] GOOGLE_PLACES_API_KEY missing from .env — place search disabled');
    }
  }


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

  @override
  Future<PlaceResult?> getDetail(
      String placeId, String name, double lat, double lng) async {
    if (_apiKey.isEmpty) return null;
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        'details/json',
        queryParameters: {
          'place_id': placeId,
          'fields':
              'name,formatted_phone_number,website,opening_hours,geometry,formatted_address',
          'language': 'ko',
          'key': _apiKey,
        },
      );
      final r = res.data?['result'] as Map<String, dynamic>?;
      if (r == null) return null;
      final loc = (r['geometry'] as Map?)
          ?.cast<String, dynamic>()['location'] as Map?;
      final openNow =
          (r['opening_hours'] as Map?)?['open_now'] as bool?;
      return PlaceResult(
        placeId: placeId,
        name: r['name'] as String? ?? name,
        address: r['formatted_address'] as String?,
        lat: loc != null ? (loc['lat'] as num).toDouble() : lat,
        lng: loc != null ? (loc['lng'] as num).toDouble() : lng,
        categories: const [],
        externalSource: 'google_places',
        phone: r['formatted_phone_number'] as String?,
        website: r['website'] as String?,
        isOpenNow: openNow,
      );
    } catch (e) {
      debugPrint('[GooglePlaces] getDetail error: $e');
      return null;
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
