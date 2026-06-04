import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../../../app.dart';
import '../../../data/models/raw_location_event.dart';
import '../../map/presentation/map_drawing.dart';

/// Compact, read-only map showing one day's route line + pins.
class DayRouteMap extends StatefulWidget {
  final List<RawLocationEvent> route;
  final List<MapPin> pins;
  const DayRouteMap({super.key, required this.route, required this.pins});

  @override
  State<DayRouteMap> createState() => _DayRouteMapState();
}

class _DayRouteMapState extends State<DayRouteMap> {
  MapboxMap? _map;

  ({double lat, double lng}) get _center {
    if (widget.pins.isNotEmpty) {
      return (lat: widget.pins.first.lat, lng: widget.pins.first.lng);
    }
    if (widget.route.isNotEmpty) {
      return (lat: widget.route.first.lat, lng: widget.route.first.lng);
    }
    return (lat: 37.5665, lng: 126.9780); // Seoul fallback
  }

  Future<void> _draw() async {
    final map = _map;
    if (map == null) return;
    await drawRouteLine(map, widget.route, kBrandGreen.toARGB32());
    await drawPins(
      map,
      sourceId: 'day-pins-source',
      layerId: 'day-pins-layer',
      pins: widget.pins,
      color: kBrandGreen.toARGB32(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = _center;
    return MapWidget(
      key: const ValueKey('day-route-map'),
      viewport: CameraViewportState(
        center: Point(coordinates: Position(c.lng, c.lat)),
        zoom: 13.0,
      ),
      onMapCreated: (controller) {
        _map = controller;
        _draw();
      },
    );
  }
}
