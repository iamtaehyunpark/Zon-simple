import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../../../data/models/raw_location_event.dart';

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

Future<void> drawRouteLine(
    MapboxMap map, List<RawLocationEvent> events, int color) async {
  await _remove(map, 'route-source', 'route-layer');
  if (events.length < 2) return;
  final coords = events.map((e) => '[${e.lng},${e.lat}]').join(',');
  await map.style.addSource(GeoJsonSource(
    id: 'route-source',
    data:
        '{"type":"Feature","geometry":{"type":"LineString","coordinates":[$coords]}}',
  ));
  await map.style.addLayer(LineLayer(
    id: 'route-layer',
    sourceId: 'route-source',
    lineColor: color,
    lineWidth: 3.0,
    lineOpacity: 0.85,
  ));
}

Future<void> drawPins(
  MapboxMap map, {
  required String sourceId,
  required String layerId,
  required List<MapPin> pins,
  required int color,
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
    circleRadius: 8.0,
    circleColor: color,
    circleStrokeWidth: 2.0,
    circleStrokeColor: 0xFFFFFFFF,
  ));
}
