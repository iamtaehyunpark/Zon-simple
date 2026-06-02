import 'package:dio/dio.dart';
import 'geocoding_service.dart';

/// Naver Reverse Geocoding (Naver Cloud Platform Maps API).
/// Credentials: NCP — different from Naver Search API.
/// Header names: X-NCP-APIGW-API-KEY-ID / X-NCP-APIGW-API-KEY
/// Note: coords parameter is lng,lat order.
class NaverGeocodingService implements GeocodingService {
  final Dio _dio;

  NaverGeocodingService({
    required String clientId,
    required String clientSecret,
    Dio? dio,
  }) : _dio = dio ??
            Dio(BaseOptions(
              baseUrl:
                  'https://naveropenapi.apigw.naver.com/map-reversegeocode/v2/',
              headers: {
                'X-NCP-APIGW-API-KEY-ID': clientId,
                'X-NCP-APIGW-API-KEY': clientSecret,
              },
            ));

  @override
  Future<String?> reverseGeocode(double lat, double lng) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'gc',
        queryParameters: {
          'coords': '$lng,$lat', // Naver expects lng,lat
          'sourcecrs': 'epsg:4326',
          'output': 'json',
          'orders': 'roadaddr,addr',
        },
      );

      if (response.statusCode != 200 || response.data == null) return null;

      final results = response.data!['results'] as List? ?? [];
      if (results.isEmpty) return null;

      // Prefer road address (도로명), fall back to land-lot (지번)
      final r = results.firstWhere(
        (x) => x['name'] == 'roadaddr',
        orElse: () => results.first,
      ) as Map<String, dynamic>;

      final region = r['region'] as Map<String, dynamic>? ?? {};
      final area2 = region['area2']?['name'] as String? ?? ''; // 구/군
      final area3 = region['area3']?['name'] as String? ?? ''; // 동
      final land = r['land'] as Map<String, dynamic>?;
      final road = land?['name'] as String? ?? '';
      final num1 = land?['number1'] as String? ?? '';
      final num2 = land?['number2'] as String? ?? '';
      final number = [num1, num2].where((s) => s.isNotEmpty).join('-');

      if (road.isNotEmpty) {
        // e.g. "강남구 테헤란로 152"
        return [area2, road, number].where((s) => s.isNotEmpty).join(' ');
      }
      // e.g. "강남구 역삼동"
      final district = [area2, area3].where((s) => s.isNotEmpty).join(' ');
      return district.isEmpty ? null : district;
    } catch (_) {
      return null;
    }
  }
}
