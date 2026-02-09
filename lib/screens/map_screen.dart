import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapScreen extends StatefulWidget {
  final String? targetRoomId;
  final double? targetFloor;

  const MapScreen({super.key, this.targetRoomId, this.targetFloor});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  double _currentFloor = 0;
  List<Polygon> _polygons = [];
  String? _highlightedRoomId;
  List<dynamic> _rawFeatures = [];
  bool _mapReady = false;

  List<Marker> _buildRoomLabels() {
    List<Marker> markers = [];

    for (var feature in _rawFeatures) {
      final String roomId = feature['properties']['room_no']?.toString() ?? '';
      if (roomId.isEmpty || roomId == "null") continue;

      // Get the center point of the room to place the label
      final List<LatLng> points = _extractPoints(feature['geometry']);
      if (points.isEmpty) continue;

      double latSum = 0, lngSum = 0;
      for (var p in points) { latSum += p.latitude; lngSum += p.longitude; }
      LatLng center = LatLng(latSum / points.length, lngSum / points.length);

      bool isHighlighted = roomId.trim().toLowerCase() == _highlightedRoomId?.trim().toLowerCase();

      markers.add(
        Marker(
          point: center,
          width: 80,
          height: 40,
          alignment: Alignment.center,
          child: IgnorePointer( // Allows taps to pass through to the polygon layer
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: isHighlighted ? Colors.pink : Colors.white.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: isHighlighted ? Colors.white : Colors.black26, width: 1),
                ),
                child: Text(
                  roomId,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isHighlighted ? Colors.white : Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
      );
    }
    return markers;
  }

  List<LatLng> _extractPoints(Map<String, dynamic> geometry) {
    List<LatLng> points = [];
    try {
      if (geometry['type'] == 'Polygon') {
        // In your file, index [0] is often the building, [1] is the room
        // We extract all rings to ensure we can tap any part of the geometry
        for (var ring in geometry['coordinates']) {
          points.addAll((ring as List).map((c) => LatLng(c[1].toDouble(), c[0].toDouble())));
        }
      } else if (geometry['type'] == 'MultiPolygon') {
        // MultiPolygons add one more level of nesting
        for (var poly in geometry['coordinates']) {
          for (var ring in poly) {
            points.addAll((ring as List).map((c) => LatLng(c[1].toDouble(), c[0].toDouble())));
          }
        }
      }
    } catch (e) {
      debugPrint("Error extracting points: $e");
    }
    return points;
  }

  double _calculateBoundingBoxArea(List<LatLng> points) {
    if (points.isEmpty) return double.infinity;

    double minLat = points[0].latitude;
    double maxLat = points[0].latitude;
    double minLng = points[0].longitude;
    double maxLng = points[0].longitude;

    for (var p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    // Returns the area of the bounding box
    return (maxLat - minLat) * (maxLng - minLng);
  }

  @override
  void initState() {
    super.initState();
    _currentFloor = widget.targetFloor ?? 0.0;
    _highlightedRoomId = widget.targetRoomId;
    _loadFloorData(_currentFloor);
  }

  Future<void> _loadFloorData(double floor) async {
    String floorName = floor == floor.toInt() ? floor.toInt().toString() : floor.toString();

    try {
      final String response = await rootBundle.loadString('assets/map/floor_$floorName.geojson');
      final data = json.decode(response);

      List<Polygon> newPolygons = [];
      // 1. Update the features list first
      _rawFeatures = data['features'];

      for (var feature in _rawFeatures) {
        final geometry = feature['geometry'];
        final String roomId = feature['properties']['room_no']?.toString() ?? '';

        if (geometry['type'] == 'Polygon') {
          for (int i = 0; i < geometry['coordinates'].length; i++) {
            _addPolygonToList(geometry['coordinates'][i], roomId, newPolygons);
          }
        } else if (geometry['type'] == 'MultiPolygon') {
          for (var poly in geometry['coordinates']) {
            for (var ring in poly) {
              _addPolygonToList(ring, roomId, newPolygons);
            }
          }
        }
      }

      // 2. Update state
      setState(() {
        _polygons = newPolygons;
        _currentFloor = floor;
      });

      // 3. Trigger the focus ONLY after the UI has had a chance to build the new polygons
      if (_highlightedRoomId != null && _mapReady) {
        // Small delay or post-frame callback ensures the map controller is ready for the new data
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _focusOnRoom(_highlightedRoomId!);
        });
      }
    } catch (e) {
      debugPrint("Error loading GeoJSON: $e");
    }
  }

  void _addPolygonToList(List coords, String roomId, List<Polygon> list) {
    List<LatLng> points = coords.map((c) => LatLng(c[1].toDouble(), c[0].toDouble())).toList();

    // Fuzzy matching to handle case-sensitivity between Supabase and QGIS
    bool isMatch = roomId.trim().toLowerCase() == _highlightedRoomId?.trim().toLowerCase();

    list.add(
      Polygon(
        points: points,
        // Using withValues to avoid deprecated withOpacity
        color: isMatch
            ? Colors.pink.withValues(alpha: 0.8)
            : Colors.blue.withValues(alpha: 0.3),
        borderColor: Colors.blue,
        borderStrokeWidth: 2,
      ),
    );
  }

  void _handleMapTap(LatLng tapPoint) {
    String? foundRoomId;
    double smallestArea = double.infinity;

    for (var feature in _rawFeatures) {
      final String roomId = feature['properties']['room_no']?.toString() ?? '';
      if (roomId.isEmpty || roomId == "null") continue;

      final geometry = feature['geometry'];
      // Logic to extract points from Polygon or MultiPolygon...
      List<LatLng> points = _extractPoints(geometry);

      if (_isPointInPolygon(tapPoint, points)) {
        // Heuristic: Smaller coordinate spread usually means a room, not a building
        double area = _calculateBoundingBoxArea(points);
        if (area < smallestArea) {
          smallestArea = area;
          foundRoomId = roomId;
        }
      }
    }

    if (foundRoomId != null) {
      setState(() {
        _highlightedRoomId = foundRoomId;
        // Regenerate the polygons list to update the pink highlight colors
        _polygons = _rawFeatures.map((feature) {
          final geometry = feature['geometry'];
          final String roomId = feature['properties']['room_no']?.toString() ?? '';
          List<Polygon> featurePolys = [];

          if (geometry['type'] == 'Polygon') {
            for (var ring in geometry['coordinates']) {
              _addPolygonToList(ring, roomId, featurePolys);
            }
          } else if (geometry['type'] == 'MultiPolygon') {
            for (var poly in geometry['coordinates']) {
              for (var ring in poly) {
                _addPolygonToList(ring, roomId, featurePolys);
              }
            }
          }
          return featurePolys;
        }).expand((i) => i).toList();
      });

      // FIX: Call focus directly here so it happens on the 1st tap!
      _focusOnRoom(foundRoomId);
    }
  }

  bool _isPointInPolygon(LatLng point, List<LatLng> polygon) {
    var lat = point.latitude;
    var lng = point.longitude;
    var isInside = false;
    for (var i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
      if (((polygon[i].latitude > lat) != (polygon[j].latitude > lat)) &&
          (lng < (polygon[j].longitude - polygon[i].longitude) * (lat - polygon[i].latitude) / (polygon[j].latitude - polygon[i].latitude) + polygon[i].longitude)) {
        isInside = !isInside;
      }
    }
    return isInside;
  }

  void _focusOnRoom(String roomId) {
    if (!_mapReady || _rawFeatures.isEmpty) return;

    try {

      if (!_mapController.camera.center.latitude.isFinite) return;
      final searchId = roomId.trim().toLowerCase();

      // Find the feature in the CURRENTLY LOADED floor features
      final targetFeature = _rawFeatures.firstWhere(
            (f) => f['properties']['room_no']?.toString().trim().toLowerCase() == searchId,
        orElse: () => null,
      );

      if (targetFeature != null) {
        List<LatLng> allPoints = _extractPoints(targetFeature['geometry']);

        if (allPoints.isNotEmpty) {
          // Calculate the centroid
          double latSum = 0, lngSum = 0;
          for (var p in allPoints) {
            latSum += p.latitude;
            lngSum += p.longitude;
          }
          LatLng center = LatLng(latSum / allPoints.length, lngSum / allPoints.length);

          // Move the map
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _mapController.move(center, 19.5);
            }
          });
        }
      } else {
        debugPrint("Room $roomId not found on Floor $_currentFloor");
      }
    } catch (e) {
      debugPrint("Focus error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("LU Campus Map"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(24.8694, 91.8051),
              initialZoom: 18.0,
              onPositionChanged: (position, hasGesture) {
                if (hasGesture) {
                  setState(() {}); // Rebuilds the UI to check if zoom > 18.5
                }
              },
              onMapReady: () {
                setState(() => _mapReady = true);
                // Small delay allows the map to finish internal setup
                Future.delayed(const Duration(milliseconds: 300), () {
                  if (_highlightedRoomId != null && mounted) {
                    _focusOnRoom(_highlightedRoomId!);
                  }
                });
              },
              onTap: (tapPosition, point) => _handleMapTap(point),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.imtiaz.lu360',
              ),
              PolygonLayer(polygons: _polygons),
              if (_mapReady && _mapController.camera.zoom > 18.5)
                MarkerLayer(markers: _buildRoomLabels()),
            ],
          ),
          Positioned(
            right: 20,
            bottom: 100,
            child: Column(
              children: [3.0, 2.0, 1.0, 0.0].map((floor) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: FloatingActionButton.small(
                    heroTag: "floor_$floor",
                    onPressed: () {
                      _highlightedRoomId = null;
                      _loadFloorData(floor);
                    },
                    backgroundColor: _currentFloor == floor ? Colors.pink : Colors.white,
                    child: Text(floor % 1 == 0 ? floor.toInt().toString() : floor.toString()),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}