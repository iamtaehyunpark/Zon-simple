import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../supabase/supabase_provider.dart';
import 'place_models.dart';
import 'place_service.dart';
import 'naver_place_service.dart';
import 'google_place_service.dart';

part 'place_service_provider.g.dart';

/// Returns the correct PlaceService for a given coordinate.
/// Korea → Naver. Everywhere else → Google (via edge function).
///
/// This is the single decision point. To add a new region (e.g. Japan → Kakao,
/// EU → Foursquare), add an `else if` here and create the implementation.
@riverpod
PlaceService placeServiceFor(PlaceServiceForRef ref, double lat, double lng) {
  if (isKorea(lat, lng)) {
    final clientId = dotenv.env['NAVER_CLIENT_ID'] ?? '';
    final clientSecret = dotenv.env['NAVER_CLIENT_SECRET'] ?? '';
    if (clientId.isNotEmpty && clientSecret.isNotEmpty) {
      return NaverPlaceService(
        clientId: clientId,
        clientSecret: clientSecret,
      );
    }
  }
  // Global fallback
  return GooglePlaceService(ref.watch(supabaseClientProvider));
}

/// Convenience: resolve provider name for display / analytics.
@riverpod
String placeProviderName(PlaceProviderNameRef ref, double lat, double lng) {
  return isKorea(lat, lng) ? 'naver' : 'google_places';
}
