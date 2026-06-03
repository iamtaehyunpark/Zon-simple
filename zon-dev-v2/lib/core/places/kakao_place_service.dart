import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'place_models.dart';
import 'place_service.dart';

/// Kakao Local API — the real coordinate-grounded nearby search for Korea.
/// Docs: https://developers.kakao.com/docs/latest/ko/local/dev-guide
///
/// Auth header: `Authorization: KakaoAK {REST_API_KEY}`.
/// Coordinates are passed as `x` = longitude, `y` = latitude; `radius` is in
/// metres (max 20,000); `sort=distance` ranks by proximity. Each result carries
/// a `distance` field (metres from x,y) which we use to merge category fan-outs.
class KakaoPlaceService implements PlaceService {
  final Dio _dio;
  final int _radiusM;

  KakaoPlaceService({required String restApiKey, int radiusM = 500})
      : _radiusM = radiusM,
        _dio = Dio(BaseOptions(
          baseUrl: 'https://dapi.kakao.com/v2/local/search/',
          headers: {'Authorization': 'KakaoAK $restApiKey'},
        ));


  /// Kakao has no "all categories" call, so `nearby` fans out across the
  /// category groups worth surfacing in a place diary and merges by distance.
  static const _nearbyCategories = <String>[
    'FD6', // 음식점
    'CE7', // 카페
    'AT4', // 관광명소
    'CT1', // 문화시설
    'MT1', // 대형마트
    'HP8', // 병원
  ];

  @override
  Future<List<PlaceResult>> nearby(double lat, double lng) async {
    final batches = await Future.wait(
      _nearbyCategories.map(
        (code) => _query('category.json', {'category_group_code': code}, lat, lng),
      ),
    );

    // Merge across categories, keeping the nearest occurrence of each place.
    final byId = <String, ({PlaceResult place, int distance})>{};
    for (final batch in batches) {
      for (final entry in batch) {
        final existing = byId[entry.place.placeId];
        if (existing == null || entry.distance < existing.distance) {
          byId[entry.place.placeId] = entry;
        }
      }
    }

    final merged = byId.values.toList()
      ..sort((a, b) => a.distance.compareTo(b.distance));
    debugPrint('[KakaoNearby] merged ${merged.length} results');
    return merged.map((e) => e.place).toList();
  }

  @override
  Future<List<PlaceResult>> search(String query, double lat, double lng) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return nearby(lat, lng);
    debugPrint('[KakaoSearch] query="$trimmed"');
    // No radius cap on text search: the user is naming a specific place that
    // may be well beyond the nearby radius — we just bias toward the closest
    // match via sort=distance.
    final results =
        await _query('keyword.json', {'query': trimmed}, lat, lng, useRadius: false);
    return results.map((e) => e.place).toList();
  }

  /// One Local API call, grounded at (lat,lng). Returns place + distance pairs
  /// already sorted by distance (the API does the sorting). [useRadius] caps
  /// results to [_radiusM] — on for `nearby`, off for text `search`.
  Future<List<({PlaceResult place, int distance})>> _query(
    String path,
    Map<String, dynamic> extraParams,
    double lat,
    double lng, {
    bool useRadius = true,
  }) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        path,
        queryParameters: {
          ...extraParams,
          'x': '$lng',
          'y': '$lat',
          if (useRadius) 'radius': '$_radiusM',
          'sort': 'distance',
          'size': 15,
        },
      );
      final docs = res.data?['documents'] as List? ?? [];
      return docs.map(_fromDoc).toList();
    } catch (e) {
      debugPrint('[Kakao] $path error: $e');
      return const [];
    }
  }

  ({PlaceResult place, int distance}) _fromDoc(dynamic doc) {
    final m = doc as Map;
    final lng = double.tryParse(m['x']?.toString() ?? '') ?? 0;
    final lat = double.tryParse(m['y']?.toString() ?? '') ?? 0;
    final road = m['road_address_name'] as String?;
    final jibun = m['address_name'] as String?;
    final category = m['category_name'] as String?;
    final place = PlaceResult(
      placeId: m['id']?.toString() ?? (m['place_name'] as String? ?? ''),
      name: m['place_name'] as String? ?? '',
      address: (road != null && road.isNotEmpty) ? road : jibun,
      lat: lat,
      lng: lng,
      categories: (category != null && category.isNotEmpty)
          ? category.split(' > ')
          : const [],
      externalSource: 'kakao',
    );
    final distance = int.tryParse(m['distance']?.toString() ?? '') ?? 1 << 30;
    return (place: place, distance: distance);
  }
}
