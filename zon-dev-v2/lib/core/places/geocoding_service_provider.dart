import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'geocoding_service.dart';
import 'naver_geocoding_service.dart';
import 'mapbox_geocoding_service.dart';
import 'place_models.dart';

part 'geocoding_service_provider.g.dart';

/// Returns the correct GeocodingService for a coordinate.
/// Korea → Naver Maps Platform (NCP). Everywhere else → Mapbox.
@riverpod
GeocodingService geocodingServiceFor(
    GeocodingServiceForRef ref, double lat, double lng) {
  if (isKorea(lat, lng)) {
    final clientId = dotenv.env['NAVER_MAP_CLIENT_ID'] ?? '';
    final clientSecret = dotenv.env['NAVER_MAP_CLIENT_SECRET'] ?? '';
    if (clientId.isNotEmpty && clientSecret.isNotEmpty) {
      return NaverGeocodingService(
        clientId: clientId,
        clientSecret: clientSecret,
      );
    }
  }
  return MapboxGeocodingService(
    accessToken: dotenv.env['MAPBOX_TOKEN'] ?? '',
  );
}

/// Convenience provider: reverse geocode a coordinate to a place name.
@riverpod
Future<String?> reverseGeocode(
    ReverseGeocodeRef ref, double lat, double lng) async {
  final service = ref.watch(geocodingServiceForProvider(lat, lng));
  return service.reverseGeocode(lat, lng);
}
