import 'place_models.dart';

/// Abstract interface — implement per provider.
abstract class PlaceService {
  PlaceProvider get provider;

  /// Nearby places ranked by distance (no query text).
  Future<List<PlaceResult>> nearby(double lat, double lng);

  /// Text search within a location context.
  Future<List<PlaceResult>> search(String query, double lat, double lng);
}
