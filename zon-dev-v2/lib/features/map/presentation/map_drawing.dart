import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

/// A point to render on the map, carrying enough to identify it on tap.
class MapPin {
  final String id;
  final String kind; // 'stamp' | 'checkin'
  final String name;
  final double lat;
  final double lng;
  const MapPin({
    required this.id,
    required this.kind,
    required this.name,
    required this.lat,
    required this.lng,
  });
}

String _esc(String s) =>
    s.replaceAll('\\', r'\\').replaceAll('"', r'\"').replaceAll('\n', ' ');

String pinFeatureCollection(List<MapPin> pins) {
  final features = pins
      .map((p) =>
          '{"type":"Feature","properties":{"id":"${p.id}","kind":"${p.kind}","name":"${_esc(p.name)}"},'
          '"geometry":{"type":"Point","coordinates":[${p.lng},${p.lat}]}}')
      .join(',');
  return '{"type":"FeatureCollection","features":[$features]}';
}

Future<void> _remove(MapboxMap map, String sourceId, String layerId) async {
  try {
    if (await map.style.styleLayerExists(layerId)) {
      await map.style.removeStyleLayer(layerId);
    }
    if (await map.style.styleSourceExists(sourceId)) {
      await map.style.removeStyleSource(sourceId);
    }
  } catch (_) {/* layer/source not present */}
}

/// Draw a polyline from raw [lng,lat] coordinate pairs (uses [idPrefix] so
/// multiple lines can coexist on one map).
Future<void> drawLine(
  MapboxMap map,
  List<List<double>> coords,
  int color, {
  String idPrefix = 'route',
}) async {
  await _remove(map, '$idPrefix-source', '$idPrefix-layer');
  if (coords.length < 2) return;
  final s = coords.map((c) => '[${c[0]},${c[1]}]').join(',');
  await map.style.addSource(GeoJsonSource(
    id: '$idPrefix-source',
    data:
        '{"type":"Feature","geometry":{"type":"LineString","coordinates":[$s]}}',
  ));
  await map.style.addLayer(LineLayer(
    id: '$idPrefix-layer',
    sourceId: '$idPrefix-source',
    lineColor: color,
    lineWidth: 4.0,
    lineOpacity: 0.75,
    lineCap: LineCap.ROUND,
    lineJoin: LineJoin.ROUND,
  ));
}

/// Like [drawLine] but updates the existing source in place when present, so
/// a frequently-growing line (the live route) animates smoothly instead of
/// flickering through a remove/re-add each time.
Future<void> upsertLine(
  MapboxMap map,
  List<List<double>> coords,
  int color, {
  String idPrefix = 'route',
}) async {
  if (coords.length < 2) return;
  final sourceId = '$idPrefix-source';
  final layerId = '$idPrefix-layer';
  final s = coords.map((c) => '[${c[0]},${c[1]}]').join(',');
  final data =
      '{"type":"Feature","geometry":{"type":"LineString","coordinates":[$s]}}';
  try {
    if (await map.style.styleSourceExists(sourceId)) {
      await map.style.setStyleSourceProperty(sourceId, 'data', data);
      return;
    }
  } catch (_) {}
  try {
    await map.style.addSource(GeoJsonSource(id: sourceId, data: data));
  } catch (_) {
    try {
      await map.style.setStyleSourceProperty(sourceId, 'data', data);
    } catch (_) {}
  }
  try {
    if (!(await map.style.styleLayerExists(layerId))) {
      await map.style.addLayer(LineLayer(
        id: layerId,
        sourceId: sourceId,
        lineColor: color,
        lineWidth: 4.0,
        lineOpacity: 0.75,
        lineCap: LineCap.ROUND,
        lineJoin: LineJoin.ROUND,
      ));
    }
  } catch (_) {}
}

/// Remove a polyline previously drawn with [drawLine] / [upsertLine].
Future<void> removeLine(MapboxMap map, {String idPrefix = 'route'}) =>
    _remove(map, '$idPrefix-source', '$idPrefix-layer');

/// Draw (or clear, when [pin] is null) a ring highlighting the selected pin.
Future<void> drawHighlight(MapboxMap map, MapPin? pin, int color) async {
  await _remove(map, 'highlight-source', 'highlight-layer');
  if (pin == null) return;
  await map.style.addSource(GeoJsonSource(
    id: 'highlight-source',
    data: pinFeatureCollection([pin]),
  ));
  await map.style.addLayer(CircleLayer(
    id: 'highlight-layer',
    sourceId: 'highlight-source',
    circleRadius: 16.0,
    circleColor: 0x00000000,
    circleStrokeWidth: 4.0,
    circleStrokeColor: color,
  ));
}

/// Render hot-place sized circles (Phase C). [places] is a list of records
/// with lat/lng/hotScore/id/name. Radius ∝ log(hotScore+1), clamped 8–32pt.
Future<void> drawHotPlaces(
  MapboxMap map,
  List<({String id, String name, double lat, double lng, double hotScore})>
      places, {
  int color = 0xCC8B6EC4,
}) async {
  const sourceId = 'hot-places-source';
  const layerId = 'hot-places-layer';
  await _remove(map, sourceId, layerId);
  if (places.isEmpty) return;
  final features = places
      .map((p) =>
          '{"type":"Feature","properties":{"id":"${p.id}","kind":"hot",'
          '"name":"${_esc(p.name)}","hotScore":${p.hotScore}},'
          '"geometry":{"type":"Point","coordinates":[${p.lng},${p.lat}]}}')
      .join(',');
  final geojson = '{"type":"FeatureCollection","features":[$features]}';
  await map.style.addSource(GeoJsonSource(id: sourceId, data: geojson));
  await map.style.addLayer(CircleLayer(
    id: layerId,
    sourceId: sourceId,
    circleColor: color,
    circleOpacity: 0.55,
    circleRadius: 12.0, // visual base; individual sizes via data-driven props TBD
    circleStrokeWidth: 1.5,
    circleStrokeColor: 0xFFFFFFFF,
  ));
}

/// Draw a filled convex-hull polygon. [coords] are [lng, lat] pairs (open ring —
/// do not repeat the first point). Renders a fill layer below a stroke layer so
/// that pin markers drawn afterwards sit on top.
Future<void> drawPolygon(
  MapboxMap map,
  List<List<double>> coords,
  int fillColor, {
  String idPrefix = 'polygon',
  double fillOpacity = 0.15,
  double strokeOpacity = 0.55,
  double strokeWidth = 1.5,
}) async {
  final sourceId = '$idPrefix-source';
  final fillLayerId = '$idPrefix-fill-layer';
  final strokeLayerId = '$idPrefix-stroke-layer';
  // Remove stroke first (can't remove source while a layer references it)
  try {
    if (await map.style.styleLayerExists(strokeLayerId)) {
      await map.style.removeStyleLayer(strokeLayerId);
    }
  } catch (_) {}
  await _remove(map, sourceId, fillLayerId);
  if (coords.length < 3) return;
  final ring = [
    ...coords.map((c) => '[${c[0]},${c[1]}]'),
    '[${coords[0][0]},${coords[0][1]}]', // close
  ].join(',');
  final geojson =
      '{"type":"Feature","geometry":{"type":"Polygon","coordinates":[[$ring]]}}';
  await map.style.addSource(GeoJsonSource(id: sourceId, data: geojson));
  await map.style.addLayer(FillLayer(
    id: fillLayerId,
    sourceId: sourceId,
    fillColor: fillColor,
    fillOpacity: fillOpacity,
  ));
  await map.style.addLayer(LineLayer(
    id: strokeLayerId,
    sourceId: sourceId,
    lineColor: fillColor,
    lineWidth: strokeWidth,
    lineOpacity: strokeOpacity,
  ));
}

Future<void> drawPins(
  MapboxMap map, {
  required String sourceId,
  required String layerId,
  required List<MapPin> pins,
  required int color,
  double circleRadius = 8.0,
  double strokeWidth = 2.0,
  double opacity = 1.0,
}) async {
  await _remove(map, sourceId, layerId);
  if (pins.isEmpty) return;
  await map.style.addSource(GeoJsonSource(
    id: sourceId,
    data: pinFeatureCollection(pins),
  ));
  await map.style.addLayer(CircleLayer(
    id: layerId,
    sourceId: sourceId,
    circleRadius: circleRadius,
    circleColor: color,
    circleOpacity: opacity,
    circleStrokeWidth: strokeWidth,
    circleStrokeColor: 0xFFFFFFFF,
  ));
}
