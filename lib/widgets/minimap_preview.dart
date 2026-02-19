import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MiniMapPreview extends StatefulWidget {
  final String roomId;
  final double floor;

  const MiniMapPreview({super.key, required this.roomId, required this.floor});

  @override
  State<MiniMapPreview> createState() => _MiniMapPreviewState();
}

class _MiniMapPreviewState extends State<MiniMapPreview> {
  final MapController _mapController = MapController();
  List<Polygon> _polygons = [];
  LatLng? _roomCenter;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAndCenterRoom();
  }

  Future<void> _loadAndCenterRoom() async {
    String floorName = widget.floor == widget.floor.toInt()
        ? widget.floor.toInt().toString()
        : widget.floor.toString();

    try {
      final String response = await rootBundle.loadString('assets/map/floor_$floorName.geojson');
      final data = json.decode(response);
      final rawFeatures = data['features'];

      List<Polygon> newPolygons = [];
      LatLng? calculatedCenter;

      for (var feature in rawFeatures) {
        final geometry = feature['geometry'];
        final String currentRoomId = feature['properties']['room_no']?.toString() ?? '';

        // Check if this specific feature is our target room or a wall
        bool isMatch = currentRoomId.trim().toLowerCase() == widget.roomId.trim().toLowerCase();
        bool isWall = currentRoomId.toLowerCase() == 'wall' || currentRoomId.toLowerCase() == 'walls';

        List<LatLng> outerPoints = [];
        List<List<LatLng>> holes = [];

        // Parse coordinates for ALL features, not just the target room
        if (geometry['type'] == 'Polygon') {
          var rings = geometry['coordinates'];
          if (rings.isNotEmpty) {
            outerPoints = (rings[0] as List).map((c) => LatLng(c[1].toDouble(), c[0].toDouble())).toList();
            for (int i = 1; i < rings.length; i++) {
              holes.add((rings[i] as List).map((c) => LatLng(c[1].toDouble(), c[0].toDouble())).toList());
            }
          }
        } else if (geometry['type'] == 'MultiPolygon') {
          for (var poly in geometry['coordinates']) {
            if (poly.isNotEmpty) {
              outerPoints = (poly[0] as List).map((c) => LatLng(c[1].toDouble(), c[0].toDouble())).toList();
              for (int i = 1; i < poly.length; i++) {
                holes.add((poly[i] as List).map((c) => LatLng(c[1].toDouble(), c[0].toDouble())).toList());
              }
            }
          }
        }

        if (outerPoints.isNotEmpty) {
          // If this is the target room, calculate the camera center
          if (isMatch && calculatedCenter == null) {
            double latSum = 0, lngSum = 0;
            for (var p in outerPoints) { latSum += p.latitude; lngSum += p.longitude; }
            calculatedCenter = LatLng(latSum / outerPoints.length, lngSum / outerPoints.length);
          }

          // Add EVERY polygon to the map, but color the target room differently
          newPolygons.add(
            Polygon(
              points: outerPoints,
              holePointsList: holes, // Including holes so courtyards/gaps look correct
              color: isMatch
                  ? Colors.yellow.withOpacity(0.8) // Highlighted room
                  : (isWall ? Colors.brown.withOpacity(0.8) : Colors.orangeAccent.withOpacity(0.6)), // Other rooms & walls
              borderColor: Colors.black,
              borderStrokeWidth: isWall ? 2 : 1,
            ),
          );
        }
      }

      if (mounted) {
        setState(() {
          _polygons = newPolygons;
          // Fallback to campus center if room isn't found
          _roomCenter = calculatedCenter ?? const LatLng(24.8694, 91.8051);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("MiniMap Error: $e");
      if (mounted) {
        setState(() {
          _roomCenter = const LatLng(24.8694, 91.8051);
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: 180,
        width: double.infinity,
        color: const Color(0xFFE0E0E0),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return SizedBox(
      height: 180,
      width: double.infinity,
      // IgnorePointer prevents panning/zooming in the preview
      child: IgnorePointer(
        child: FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _roomCenter!,
            initialZoom: 19.5, // Zoomed in close to the room
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.imtiaz.lu360',
            ),
            PolygonLayer(polygons: _polygons),
          ],
        ),
      ),
    );
  }
}