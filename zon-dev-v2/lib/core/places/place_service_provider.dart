import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'place_service.dart';
import 'kakao_place_service.dart';

part 'place_service_provider.g.dart';

/// Returns the PlaceService for a given coordinate.
///
/// Kakao Local API only — it provides true coordinate-grounded nearby + text
/// search. No fallback to Naver/Google by design (Kakao is Korea-focused; this
/// app is too). `lat`/`lng` are accepted for a future region split.
@riverpod
PlaceService placeServiceFor(PlaceServiceForRef ref, double lat, double lng) {
  return KakaoPlaceService(
    restApiKey: dotenv.env['KAKAO_REST_API_KEY'] ?? '',
  );
}

/// Convenience: resolve provider name for display / analytics.
@riverpod
String placeProviderName(PlaceProviderNameRef ref, double lat, double lng) =>
    'kakao';
