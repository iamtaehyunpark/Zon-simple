import 'package:dio/dio.dart';
import 'geocoding_service.dart';

/// Mapbox Reverse Geocoding — global fallback outside Korea.
/// Free tier: 100,000 requests/month.
class MapboxGeocodingService implements GeocodingService {
  final String _accessToken;
  final Dio _dio;

  MapboxGeocodingService({required String accessToken, Dio? dio})
      : _accessToken = accessToken,
        _dio = dio ??
            Dio(BaseOptions(
              baseUrl: 'https://api.mapbox.com/geocoding/v5/',
            ));

  @override
  Future<String?> reverseGeocode(double lat, double lng) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'mapbox.places/$lng,$lat.json',
        queryParameters: {
          'types': 'poi,address,neighborhood,locality',
          'limit': 1,
          'access_token': _accessToken,
        },
      );

      if (response.statusCode != 200 || response.data == null) return null;
      final features = response.data!['features'] as List? ?? [];
      if (features.isEmpty) return null;
      return features.first['place_name'] as String?;
    } catch (_) {
      return null;
    }
  }
}
