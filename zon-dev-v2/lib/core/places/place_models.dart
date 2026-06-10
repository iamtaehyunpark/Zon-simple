/// Unified place result — provider-agnostic.
/// externalSource tells callers which backend supplied this result.
class PlaceResult {
  final String placeId;
  final String name;
  final String? address;
  final double lat;
  final double lng;
  final List<String> categories;
  final String externalSource; // 'kakao' | 'google_places'
  final String? phone;
  final String? website;
  final bool? isOpenNow;
  final String? placeUrl; // provider web URL (Kakao map link, etc.)

  const PlaceResult({
    required this.placeId,
    required this.name,
    this.address,
    required this.lat,
    required this.lng,
    this.categories = const [],
    required this.externalSource,
    this.phone,
    this.website,
    this.isOpenNow,
    this.placeUrl,
  });

  Map<String, dynamic> toJson() => {
        'place_id': placeId,
        'name': name,
        'address': address,
        'lat': lat,
        'lng': lng,
        'categories': categories,
        'external_source': externalSource,
      };
}

/// Korea bounding box (roughly). Used for auto-detection.
bool isKorea(double lat, double lng) =>
    lat >= 33.0 && lat <= 38.9 && lng >= 124.0 && lng <= 132.0;
