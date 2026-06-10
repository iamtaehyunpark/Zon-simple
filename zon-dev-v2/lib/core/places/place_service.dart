import 'place_models.dart';

abstract class PlaceService {
  /// Nearby places ranked by distance (no query text).
  Future<List<PlaceResult>> nearby(double lat, double lng);

  /// Text search within a location context.
  Future<List<PlaceResult>> search(String query, double lat, double lng);

  /// Fetch richer detail for a known place ID (phone, website, hours).
  /// Returns null if the provider doesn't support detail lookup or the call fails.
  Future<PlaceResult?> getDetail(
          String placeId, String name, double lat, double lng) =>
      Future.value(null);
}
