import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'place_models.dart';
import 'place_service.dart';
import 'kakao_place_service.dart';
import 'google_place_service.dart';

part 'place_service_provider.g.dart';

/// Korea → Kakao (true coordinate-grounded nearby + text search).
/// Everywhere else → Google Places.
@riverpod
PlaceService placeServiceFor(PlaceServiceForRef ref, double lat, double lng) {
  if (isKorea(lat, lng)) {
    return KakaoPlaceService(restApiKey: dotenv.env['KAKAO_REST_API_KEY'] ?? '');
  }
  return GooglePlaceService();
}


