import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
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
  final TextEditingController _searchController = TextEditingController();
  bool _searching = false;
  String? _searchError;

  @override
  void initState() {
    super.initState();
    _center = widget.initialPosition;
    _mapController = MapController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchPlace() async {
    final query = _searchController.text.trim();
    if (query.isEmpty || _searching) return;

    setState(() {
      _searching = true;
      _searchError = null;
    });

    try {
      final results = await locationFromAddress(query);
      if (!mounted) return;
      if (results.isEmpty) {
        setState(() {
          _searchError = 'No places found';
          _searching = false;
        });
        return;
      }

      final first = results.first;
      final target = LatLng(first.latitude, first.longitude);
      setState(() {
        _center = target;
        _searching = false;
      });
      _mapController.move(target, 15);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _searchError = 'Could not find that place';
        _searching = false;
      });
    }
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
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Material(
              elevation: 3,
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _searchPlace(),
                    decoration: InputDecoration(
                      hintText: 'Search for a place or address',
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searching
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : IconButton(
                              icon: const Icon(Icons.arrow_forward),
                              onPressed: _searchPlace,
                            ),
                    ),
                  ),
                  if (_searchError != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _searchError!,
                          style: const TextStyle(
                            color: Color(0xFFB42318),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
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
