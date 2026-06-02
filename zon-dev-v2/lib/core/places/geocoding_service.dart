abstract class GeocodingService {
  Future<String?> reverseGeocode(double lat, double lng);
}

class GeocodedPlace {
  final String name;
  final String? address;
  final double lat;
  final double lng;
  const GeocodedPlace({
    required this.name,
    this.address,
    required this.lat,
    required this.lng,
  });
}
