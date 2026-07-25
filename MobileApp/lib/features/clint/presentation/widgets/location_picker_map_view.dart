import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class LocationPickerMapView extends StatefulWidget {
  const LocationPickerMapView({
    super.key,
    required this.initialPosition,
    required this.title,
    required this.confirmLabel,
  });

  final LatLng initialPosition;
  final String title;
  final String confirmLabel;

  static Future<LatLng?> pick(
    BuildContext context, {
    required LatLng initialPosition,
    required String title,
    required String confirmLabel,
  }) {
    return Navigator.of(context).push<LatLng>(
      MaterialPageRoute(
        builder: (_) => LocationPickerMapView(
          initialPosition: initialPosition,
          title: title,
          confirmLabel: confirmLabel,
        ),
      ),
    );
  }

  @override
  State<LocationPickerMapView> createState() => _LocationPickerMapViewState();
}

class _LocationPickerMapViewState extends State<LocationPickerMapView> {
  late final MapController _mapController;
  late LatLng _center;

  @override
  void initState() {
    super.initState();
    _center = widget.initialPosition;
    _mapController = MapController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 13,
              onPositionChanged: (position, _) {
                _center = position.center;
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.alrasmarket.app',
              ),
            ],
          ),
          const Center(
            child: IgnorePointer(
              child: Icon(
                Icons.location_pin,
                size: 44,
                color: Colors.redAccent,
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 18,
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(_center),
              child: Text(widget.confirmLabel),
            ),
          ),
        ],
      ),
    );
  }
}
