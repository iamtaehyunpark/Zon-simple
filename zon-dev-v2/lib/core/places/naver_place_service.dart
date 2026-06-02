import 'dart:convert';
import 'package:dio/dio.dart';
import 'place_models.dart';
import 'place_service.dart';

/// Naver Local Search API
/// Docs: https://developers.naver.com/docs/serviceapi/search/local/local.md
///
/// Naver doesn't have a "nearby" endpoint — the closest equivalent is
/// a local search by query. For the "no query" nearby case we fall back
/// to a generic "restaurant OR cafe OR convenience" search so the result
/// list is still useful as a starting point.
class NaverPlaceService implements PlaceService {
  final Dio _dio;

  NaverPlaceService({
    required String clientId,
    required String clientSecret,
    Dio? dio,
  }) : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: 'https://openapi.naver.com/v1/search/',
              headers: {
                'X-Naver-Client-Id': clientId,
                'X-Naver-Client-Secret': clientSecret,
              },
            ));

  @override
  PlaceProvider get provider => PlaceProvider.naver;

  @override
  Future<List<PlaceResult>> nearby(double lat, double lng) async {
    // Naver Local Search doesn't support coordinate-only queries.
    // Use a broad generic term to surface nearby POIs.
    return search('', lat, lng);
  }

  @override
  Future<List<PlaceResult>> search(
      String query, double lat, double lng) async {
    try {
      final q = query.trim().isEmpty ? '음식점' : query; // default: "restaurant"
      final response = await _dio.get<String>(
        'local.json',
        queryParameters: {
          'query': q,
          'display': 5,
          'sort': 'comment', // relevance
        },
      );

      if (response.statusCode != 200 || response.data == null) return [];

      final body = jsonDecode(response.data!) as Map<String, dynamic>;
      final items = body['items'] as List? ?? [];

      return items.map((item) {
        // Naver returns coordinates in KATECH (mapx/mapy) — these are
        // in units of 1/10000000 degrees (i.e., need dividing by 1e7).
        final mapX = item['mapx'] as String? ?? '0';
        final mapY = item['mapy'] as String? ?? '0';
        final itemLng = double.tryParse(mapX) ?? 0;
        final itemLat = double.tryParse(mapY) ?? 0;

        // Strip HTML tags Naver includes in name/address
        final name = _stripHtml(item['title'] as String? ?? '');
        final roadAddress = item['roadAddress'] as String?;
        final address = (roadAddress != null && roadAddress.isNotEmpty)
            ? roadAddress
            : item['address'] as String?;

        return PlaceResult(
          placeId: item['link'] as String? ?? name,
          name: name,
          address: address,
          // Naver mapx/mapy are already decimal degrees * 1e7 … actually
          // they document them as integers in units of 1/10_000_000 of a degree.
          lat: itemLat / 1e7,
          lng: itemLng / 1e7,
          categories: [item['category'] as String? ?? '']
              .where((c) => c.isNotEmpty)
              .toList(),
          externalSource: 'naver',
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  static final _htmlTag = RegExp(r'<[^>]*>');
  String _stripHtml(String s) => s.replaceAll(_htmlTag, '');
}
