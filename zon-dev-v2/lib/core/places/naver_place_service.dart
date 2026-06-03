import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'place_models.dart';
import 'place_service.dart';

/// Naver Local Search API — text-only, no native coordinate support.
///
/// Location grounding (two-level, with fallback):
///   full  = gu + dong + road  → "일산동구 풍산동 백마로"
///   base  = gu + dong         → "일산동구 풍산동"
///
/// Search tries full anchor first; falls back to base if 0 results.
class NaverPlaceService implements PlaceService {
  final Dio _searchDio;
  final Dio _geocodeDio;

  // (fullAnchor, baseAnchor) cached per coarse coordinate (4dp ≈ 11m)
  final Map<String, (String?, String?)> _anchorCache = {};

  NaverPlaceService({
    required String clientId,
    required String clientSecret,
    required String mapClientId,
    required String mapClientSecret,
  })  : _searchDio = Dio(BaseOptions(
          baseUrl: 'https://openapi.naver.com/v1/search/',
          headers: {
            'X-Naver-Client-Id': clientId,
            'X-Naver-Client-Secret': clientSecret,
          },
        )),
        _geocodeDio = Dio(BaseOptions(
          baseUrl: 'https://maps.apigw.ntruss.com/map-reversegeocode/v2/',
          headers: {
            'x-ncp-apigw-api-key-id': mapClientId,
            'x-ncp-apigw-api-key': mapClientSecret,
          },
        ));

  @override
  PlaceProvider get provider => PlaceProvider.naver;

  /// Returns (fullAnchor, baseAnchor). Both may be null.
  /// full  = gu+dong+road  (most specific — first choice)
  /// base  = gu+dong       (no road — fallback when full yields 0 results)
  Future<(String?, String?)> _anchors(double lat, double lng) async {
    final key = '${lat.toStringAsFixed(4)},${lng.toStringAsFixed(4)}';
    if (_anchorCache.containsKey(key)) return _anchorCache[key]!;

    final result = await _anchorsViaNcp(lat, lng) ?? await _anchorsViaNominatim(lat, lng);
    return _anchorCache[key] = result ?? (null, null);
  }

  /// NCP Maps Reverse Geocoding (requires Maps-specific API keys, not IAM).
  /// Returns null on auth failure so Nominatim takes over.
  Future<(String, String)?> _anchorsViaNcp(double lat, double lng) async {
    try {
      final res = await _geocodeDio.get<Map<String, dynamic>>(
        'gc',
        queryParameters: {
          'coords': '$lng,$lat',
          'orders': 'roadaddr,admcode',
          'output': 'json',
        },
      );
      final results = res.data?['results'] as List? ?? [];
      String? road, dong, gu;

      for (final r in results) {
        if ((r as Map)['name'] == 'roadaddr') {
          road = (r['land'] as Map?)?['name'] as String?;
        }
        if ((r as Map)['name'] == 'admcode') {
          final region = r['region'] as Map?;
          dong = (region?['area3'] as Map?)?['name'] as String?;
          gu   = (region?['area2'] as Map?)?['name'] as String?;
        }
      }

      final base = [if (gu?.isNotEmpty == true) gu!, if (dong?.isNotEmpty == true) dong!].join(' ');
      final full = [if (base.isNotEmpty) base, if (road?.isNotEmpty == true) road!].join(' ');
      if (full.isEmpty) return null;
      debugPrint('[Geocode/NCP] full:"$full" base:"$base"');
      return (full, base.isNotEmpty ? base : full);
    } catch (_) {
      return null;
    }
  }

  /// Nominatim (OSM) — free, no key, cached so 1 req/sec limit is never hit.
  Future<(String, String)?> _anchorsViaNominatim(double lat, double lng) async {
    try {
      final res = await Dio().get<Map<String, dynamic>>(
        'https://nominatim.openstreetmap.org/reverse',
        queryParameters: {
          'lat': lat,
          'lon': lng,
          'format': 'json',
          'accept-language': 'ko',
          'addressdetails': 1,
        },
        options: Options(headers: {'User-Agent': 'ZON-app/1.0'}),
      );
      final addr = res.data?['address'] as Map?;
      if (addr == null) return null;
      debugPrint('[Geocode/Nominatim] raw: $addr');

      final road = (addr['road'] ?? addr['pedestrian'] ?? addr['footway']) as String?;
      final dong = (addr['suburb'] ?? addr['quarter'] ?? addr['neighbourhood']) as String?;
      final gu   = (addr['borough'] ?? addr['city_district']) as String?;

      final baseParts = [
        if (gu?.isNotEmpty   == true) gu!,
        if (dong?.isNotEmpty == true) dong!,
      ];
      final fullParts = [...baseParts, if (road?.isNotEmpty == true) road!];

      if (fullParts.isEmpty) return null;

      final full = fullParts.join(' ');
      final base = baseParts.isNotEmpty ? baseParts.join(' ') : full;
      debugPrint('[Geocode/Nominatim] full:"$full" base:"$base"');
      return (full, base);
    } catch (e) {
      debugPrint('[Geocode/Nominatim] error: $e');
      return null;
    }
  }

  @override
  Future<List<PlaceResult>> nearby(double lat, double lng) =>
      search('', lat, lng);

  @override
  Future<List<PlaceResult>> search(
      String query, double lat, double lng) async {
    try {
      final (fullAnchor, baseAnchor) = await _anchors(lat, lng);
      final trimmed = query.trim();

      // 1. Try with full anchor (gu+dong+road)
      if (fullAnchor != null) {
        final q = '$fullAnchor $trimmed'.trim();
        debugPrint('[NaverSearch] query="$q" (full)');
        final results = await _doSearch(q);
        if (results.isNotEmpty) return results;

        // 2. Fall back to base anchor (gu+dong) if road was too specific
        if (baseAnchor != null && baseAnchor != fullAnchor) {
          final qBase = '$baseAnchor $trimmed'.trim();
          debugPrint('[NaverSearch] query="$qBase" (base fallback)');
          final fallback = await _doSearch(qBase);
          if (fallback.isNotEmpty) return fallback;
        }
      }

      // 3. Last resort — query only, no location anchor
      final qLast = trimmed.isNotEmpty ? trimmed : '';
      debugPrint('[NaverSearch] query="$qLast" (no anchor)');
      return qLast.isNotEmpty ? await _doSearch(qLast) : [];
    } catch (e, st) {
      debugPrint('[NaverSearch] error: $e\n$st');
      return [];
    }
  }

  Future<List<PlaceResult>> _doSearch(String q) async {
    final response = await _searchDio.get<String>(
      'local.json',
      queryParameters: {
        'query': q.trim(),
        'display': 5,
        'sort': 'random',
      },
    );
    if (response.statusCode != 200 || response.data == null) return [];
    final body = jsonDecode(response.data!) as Map<String, dynamic>;
    final items = body['items'] as List? ?? [];
    debugPrint('[NaverSearch] got ${items.length} results');
    return items.map((item) {
      final itemLng = (double.tryParse(item['mapx']?.toString() ?? '0') ?? 0) / 1e7;
      final itemLat = (double.tryParse(item['mapy']?.toString() ?? '0') ?? 0) / 1e7;
      final name = _stripHtml(item['title'] as String? ?? '');
      final roadAddr = item['roadAddress'] as String?;
      return PlaceResult(
        placeId: item['link'] as String? ?? name,
        name: name,
        address: (roadAddr?.isNotEmpty == true) ? roadAddr : item['address'] as String?,
        lat: itemLat,
        lng: itemLng,
        categories: [item['category'] as String? ?? '']
            .where((c) => c.isNotEmpty)
            .toList(),
        externalSource: 'naver',
      );
    }).toList();
  }

  static final _htmlTag = RegExp(r'<[^>]*>');
  String _stripHtml(String s) => s.replaceAll(_htmlTag, '');
}
