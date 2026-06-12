import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Size;
import '../../features/map/presentation/map_drawing.dart';

/// A single dot to plot on a [MiniMap]. Markers are grouped by [color] into
/// one circle layer each.
class MiniMapMarker {
  final String id;
  final String kind;
  final String name;
  final double lat;
  final double lng;
  final int color;
  final double radius;
  const MiniMapMarker({
    required this.id,
    required this.lat,
    required this.lng,
    required this.color,
    this.kind = 'pin',
    this.name = '',
    this.radius = 7.0,
  });
}

/// A lightweight, embeddable Mapbox map used for place backgrounds, stamp
/// galleries and the profile map tab. Non-interactive by default (a static
/// snapshot centred on [lat]/[lng]); pass [interactive] to allow pan/zoom.
///
/// Draws [markers] as circle layers and an optional [route] polyline. Map
/// ornaments (logo, compass, scale bar, attribution) are hidden for a clean
/// surface.
class MiniMap extends StatefulWidget {
  final double lat;
  final double lng;
  final double zoom;
  final List<MiniMapMarker> markers;
  final List<List<double>>? route; // [lng,lat] pairs
  final int routeColor;
  final bool interactive;
  final void Function(MapboxMap map)? onMapReady;

  /// Called whenever the camera moves (pan/zoom). Useful for positioning
  /// coordinate-anchored Flutter overlays via [MapboxMap.pixelForCoordinate].
  final void Function(MapboxMap map)? onCameraChanged;

  const MiniMap({
    super.key,
    required this.lat,
    required this.lng,
    this.zoom = 15.0,
    this.markers = const [],
    this.route,
    this.routeColor = 0xFF8B6EC4,
    this.interactive = false,
    this.onMapReady,
    this.onCameraChanged,
  });

  @override
  State<MiniMap> createState() => _MiniMapState();
}

class _MiniMapState extends State<MiniMap> {
  MapboxMap? _map;

  @override
  void didUpdateWidget(covariant MiniMap old) {
    super.didUpdateWidget(old);
    if (_map != null &&
        (old.markers != widget.markers || old.route != widget.route)) {
      _drawOverlays(_map!);
    }
  }

  Future<void> _onCreated(MapboxMap map) async {
    _map = map;
    if (!widget.interactive) {
      try {
        await map.gestures.updateSettings(GesturesSettings(
          rotateEnabled: false,
          pinchToZoomEnabled: false,
          scrollEnabled: false,
          pitchEnabled: false,
          doubleTapToZoomInEnabled: false,
          doubleTouchToZoomOutEnabled: false,
          quickZoomEnabled: false,
          pinchPanEnabled: false,
        ));
      } catch (_) {}
    }
    // Hide ornaments for a clean mini surface.
    for (final fn in [
      () => map.logo.updateSettings(LogoSettings(enabled: false)),
      () => map.compass.updateSettings(CompassSettings(enabled: false)),
      () => map.scaleBar.updateSettings(ScaleBarSettings(enabled: false)),
      () => map.attribution.updateSettings(AttributionSettings(enabled: false)),
    ]) {
      try {
        await fn();
      } catch (_) {}
    }
    widget.onMapReady?.call(map);
  }

  Future<void> _drawOverlays(MapboxMap map) async {
    // Route first so markers sit on top.
    final route = widget.route;
    if (route != null && route.length >= 2) {
      await drawLine(map, route, widget.routeColor, idPrefix: 'mini-route');
    }
    // Group markers by color → one circle layer per color.
    final byColor = <int, List<MiniMapMarker>>{};
    for (final m in widget.markers) {
      byColor.putIfAbsent(m.color, () => []).add(m);
    }
    var i = 0;
    for (final entry in byColor.entries) {
      final radius = entry.value.first.radius;
      await drawPins(
        map,
        sourceId: 'mini-pins-$i-source',
        layerId: 'mini-pins-$i-layer',
        pins: [
          for (final m in entry.value)
            MapPin(id: m.id, kind: m.kind, name: m.name, lat: m.lat, lng: m.lng),
        ],
        color: entry.key,
        circleRadius: radius,
      );
      i++;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MapWidget(
      key: ValueKey('minimap-${widget.lat}-${widget.lng}'),
      styleUri: MapboxStyles.MAPBOX_STREETS,
      textureView: true,
      // ignore: deprecated_member_use
      cameraOptions: CameraOptions(
        center: Point(coordinates: Position(widget.lng, widget.lat)),
        zoom: widget.zoom,
      ),
      onMapCreated: _onCreated,
      onStyleLoadedListener: (_) {
        final m = _map;
        if (m != null) _drawOverlays(m);
      },
      onCameraChangeListener: widget.onCameraChanged == null
          ? null
          : (_) {
              final m = _map;
              if (m != null) widget.onCameraChanged!(m);
            },
    );
  }
}
