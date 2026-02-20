import 'dart:convert';
import 'dart:math' as math;
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

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  double _currentFloor = 0;
  List<Polygon> _polygons = [];
  String? _highlightedRoomId;
  List<dynamic> _rawFeatures = [];
  bool _mapReady = false;

  // Default campus coordinates and zoom
  final LatLng _defaultCenter = const LatLng(24.8694, 91.8051);
  final double _defaultZoom = 18.0;

  void _animatedMapMove(LatLng destLocation, double destZoom) {
    final controller = AnimationController(
        duration: const Duration(milliseconds: 500),
        vsync: this
    );

    final latTween = Tween<double>(
        begin: _mapController.camera.center.latitude,
        end: destLocation.latitude);
    final lngTween = Tween<double>(
        begin: _mapController.camera.center.longitude,
        end: destLocation.longitude);
    final zoomTween = Tween<double>(
        begin: _mapController.camera.zoom,
        end: destZoom);

    final animation = CurvedAnimation(parent: controller, curve: Curves.fastOutSlowIn);

    controller.addListener(() {
      _mapController.move(
        LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
        zoomTween.evaluate(animation),
      );
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed || status == AnimationStatus.dismissed) {
        controller.dispose();
      }
    });

    controller.forward();
  }

  void _animatedMapRotate() {
    final controller = AnimationController(
        duration: const Duration(milliseconds: 400),
        vsync: this
    );

    double currentRotation = _mapController.camera.rotation;
    double mod = currentRotation % 360.0;
    double destRotation = currentRotation - mod;
    if (mod > 180.0) {
      destRotation += 360.0;
    }

    final rotationTween = Tween<double>(begin: currentRotation, end: destRotation);
    final animation = CurvedAnimation(parent: controller, curve: Curves.easeInOut);

    controller.addListener(() {
      _mapController.rotate(rotationTween.evaluate(animation));
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed || status == AnimationStatus.dismissed) {
        controller.dispose();
      }
    });

    controller.forward();
  }

  List<Marker> _buildRoomLabels() {
    List<Marker> markers = [];

    for (var feature in _rawFeatures) {
      final String roomId = feature['properties']['room_no']?.toString() ?? '';
      if (roomId.isEmpty || roomId == "null" || roomId.toLowerCase() == 'wall' || roomId.toLowerCase() == 'walls') continue;

      final geometry = feature['geometry'];
      List<LatLng> points = [];

      if (geometry['type'] == 'Polygon') {
        points = (geometry['coordinates'][0] as List).map((c) => LatLng(c[1].toDouble(), c[0].toDouble())).toList();
      } else if (geometry['type'] == 'MultiPolygon') {
        points = (geometry['coordinates'][0][0] as List).map((c) => LatLng(c[1].toDouble(), c[0].toDouble())).toList();
      }

      if (points.isEmpty) continue;

      double latSum = 0, lngSum = 0;
      for (var p in points) { latSum += p.latitude; lngSum += p.longitude; }
      LatLng center = LatLng(latSum / points.length, lngSum / points.length);

      bool isHighlighted = roomId.trim().toLowerCase() == _highlightedRoomId?.trim().toLowerCase();

      markers.add(
        Marker(
          point: center,
          width: 60,
          height: 20,
          alignment: Alignment.center,
          child: IgnorePointer(
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: isHighlighted ? Colors.white : Colors.white.withValues(alpha: 1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: isHighlighted ? Colors.black : Colors.black26, width: 1),
                ),
                child: Text(
                  roomId,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isHighlighted ? Colors.black : Colors.black87,
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

  List<LatLng> _extractOuterPoints(Map<String, dynamic> geometry) {
    try {
      if (geometry['type'] == 'Polygon') {
        return (geometry['coordinates'][0] as List).map((c) => LatLng(c[1].toDouble(), c[0].toDouble())).toList();
      } else if (geometry['type'] == 'MultiPolygon') {
        return (geometry['coordinates'][0][0] as List).map((c) => LatLng(c[1].toDouble(), c[0].toDouble())).toList();
      }
    } catch (e) {
      debugPrint("Error extracting points: $e");
    }
    return [];
  }

  double _calculateBoundingBoxArea(List<LatLng> points) {
    if (points.isEmpty) return double.infinity;
    double minLat = points[0].latitude, maxLat = points[0].latitude;
    double minLng = points[0].longitude, maxLng = points[0].longitude;

    for (var p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }
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
      _rawFeatures = data['features'];
      _updatePolygons();

      setState(() {
        _currentFloor = floor;
      });

      if (_highlightedRoomId != null && _mapReady) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _focusOnRoom(_highlightedRoomId!));
      }
    } catch (e) {
      debugPrint("Error loading GeoJSON: $e");
    }
  }

  void _updatePolygons() {
    List<Polygon> newPolygons = [];
    for (var feature in _rawFeatures) {
      final geometry = feature['geometry'];
      final String roomId = feature['properties']['room_no']?.toString() ?? '';

      if (geometry['type'] == 'Polygon') {
        _addPolygonWithHoles(geometry['coordinates'], roomId, newPolygons);
      } else if (geometry['type'] == 'MultiPolygon') {
        for (var poly in geometry['coordinates']) {
          _addPolygonWithHoles(poly, roomId, newPolygons);
        }
      }
    }
    setState(() {
      _polygons = newPolygons;
    });
  }

  void _addPolygonWithHoles(List rings, String roomId, List<Polygon> list) {
    if (rings.isEmpty) return;

    List<LatLng> outerPoints = (rings[0] as List).map((c) => LatLng(c[1].toDouble(), c[0].toDouble())).toList();

    List<List<LatLng>> holes = [];
    if (rings.length > 1) {
      for (int i = 1; i < rings.length; i++) {
        holes.add((rings[i] as List).map((c) => LatLng(c[1].toDouble(), c[0].toDouble())).toList());
      }
    }

    bool isMatch = roomId.trim().toLowerCase() == _highlightedRoomId?.trim().toLowerCase();
    bool isWall = roomId.toLowerCase() == 'wall' || roomId.toLowerCase() == 'walls';

    list.add(
      Polygon(
        points: outerPoints,
        holePointsList: holes,
        color: isMatch
            ? Colors.yellow.withValues(alpha: 1)
            : (isWall ? Colors.brown : Colors.orangeAccent.withValues(alpha: 1)),
        borderColor: Colors.black,
        borderStrokeWidth: isWall ? 2 : 1,
      ),
    );
  }

  void _handleMapTap(LatLng tapPoint) {
    String? foundRoomId;
    double smallestArea = double.infinity;

    for (var feature in _rawFeatures) {
      final String roomId = feature['properties']['room_no']?.toString() ?? '';
      if (roomId.isEmpty || roomId == "null" || roomId.toLowerCase() == 'wall' || roomId.toLowerCase() == 'walls') continue;

      List<LatLng> points = _extractOuterPoints(feature['geometry']);
      if (_isPointInPolygon(tapPoint, points)) {
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
      });
      _updatePolygons();
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
      final searchId = roomId.trim().toLowerCase();
      final targetFeature = _rawFeatures.firstWhere(
            (f) => f['properties']['room_no']?.toString().trim().toLowerCase() == searchId,
        orElse: () => null,
      );

      if (targetFeature != null) {
        List<LatLng> allPoints = _extractOuterPoints(targetFeature['geometry']);
        if (allPoints.isNotEmpty) {
          double latSum = 0, lngSum = 0;
          for (var p in allPoints) { latSum += p.latitude; lngSum += p.longitude; }
          LatLng center = LatLng(latSum / allPoints.length, lngSum / allPoints.length);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _animatedMapMove(center, 21.0);
          });
        }
      }
    } catch (e) {
      debugPrint("Focus error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // --- UPDATE: Safely fetch camera stats to prevent render exceptions ---
    bool isRotated = false;
    double currentRotation = 0.0;
    double currentZoom = _defaultZoom;

    if (_mapReady) {
      try {
        currentRotation = _mapController.camera.rotation;
        currentZoom = _mapController.camera.zoom;
        isRotated = (currentRotation % 360).abs() > 0.1;
      } catch (e) {
        // MapController is temporarily not ready during this exact frame.
        // We catch the error and let it fall back to default values for a millisecond.
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("LU Campus Map"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _defaultCenter,
              initialZoom: _defaultZoom,
              maxZoom: 22,
              onPositionChanged: (position, hasGesture) => setState(() {}),
              onMapReady: () {
                setState(() => _mapReady = true);
                Future.delayed(const Duration(milliseconds: 300), () {
                  if (_highlightedRoomId != null && mounted) _focusOnRoom(_highlightedRoomId!);
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
              // Use our safely extracted currentZoom variable here
              if (_mapReady && currentZoom > 20.0)
                MarkerLayer(markers: _buildRoomLabels()),
            ],
          ),

          // --- Reset to Campus Default View Button ---
          Positioned(
            top: 16,
            left: 16,
            child: FloatingActionButton(
              heroTag: "reset_campus_view",
              mini: true,
              backgroundColor: Colors.white,
              elevation: 4,
              onPressed: () {
                if (_mapReady) {
                  _animatedMapMove(_defaultCenter, _defaultZoom);
                }
              },
              child: const Icon(Icons.school, color: Colors.blueAccent, size: 24),
            ),
          ),

          // --- Animated Compass / Reset Rotation Button ---
          Positioned(
            top: 16,
            right: 16,
            child: AnimatedOpacity(
              opacity: isRotated ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              child: IgnorePointer(
                ignoring: !isRotated,
                child: FloatingActionButton(
                  heroTag: "reset_rotation",
                  mini: true,
                  backgroundColor: Colors.white,
                  elevation: 4,
                  onPressed: _animatedMapRotate,
                  // Use our safely extracted currentRotation variable here
                  child: Transform.rotate(
                    angle: -currentRotation * (math.pi / -180),
                    child: const Icon(Icons.navigation, color: Colors.redAccent, size: 28),
                  ),
                ),
              ),
            ),
          ),

          // --- Floor Selection Buttons ---
          Positioned(
            right: 20,
            bottom: 40,
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
                    backgroundColor: _currentFloor == floor ? Colors.deepOrange : Colors.white,
                    child: Text(
                      floor % 1 == 0 ? floor.toInt().toString() : floor.toString(),
                      style: TextStyle(color: _currentFloor == floor ? Colors.white : Colors.black),
                    ),
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