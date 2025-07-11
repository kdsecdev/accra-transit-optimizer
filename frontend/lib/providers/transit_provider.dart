// lib/providers/transit_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../services/api_service.dart';

class TransitProvider extends ChangeNotifier {
  List<dynamic> _stops = [];
  List<dynamic> _routeSuggestions = [];
  List<List<LatLng>> _routePolylines = [];
  Map<String, dynamic>? _currentDemand;
  Map<String, dynamic>? _analytics;
  bool _isLoading = false;
  String? _error;

  // Filters
  String _viabilityFilter = "All";
  double _demandThreshold = 30;

  List<dynamic> get stops => _stops;
  List<dynamic> get routeSuggestions => _filteredRouteSuggestions();
  Map<String, dynamic>? get currentDemand => _currentDemand;
  Map<String, dynamic>? get analytics => _analytics;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get viabilityFilter => _viabilityFilter;
  double get demandThreshold => _demandThreshold;

  List<Marker> get stopMarkers => _stops.map((stop) {
        return Marker(
          point: LatLng(stop['latitude'], stop['longitude']),
          width: 30,
          height: 30,
          child: const Icon(Icons.location_on, color: Colors.red, size: 30),
        );
      }).toList();

  List<Marker> get routeMarkers => _routeSuggestions.map((route) {
        return Marker(
          point: LatLng(route['center_lat'], route['center_lon']),
          width: 30,
          height: 30,
          child:
              const Icon(Icons.directions_bus, color: Colors.green, size: 28),
        );
      }).toList();

  List<Polyline> get routePolylines => _routePolylines.map((points) {
        return Polyline(
          points: points,
          strokeWidth: 4.0,
          color: Colors.blueAccent,
        );
      }).toList();

  Future<void> loadAllData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await Future.wait([
        loadStops(),
        loadRouteSuggestions(),
        loadAnalytics(),
      ]);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadStops() async {
    try {
      _stops = await ApiService.getStops(limit: 100, includeDemand: true);
    } catch (e) {
      _error = 'Error loading stops: $e';
    }
  }

  Future<void> predictDemand(String stopId, double lat, double lon) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final now = DateTime.now();
      _currentDemand = await ApiService.predictDemand(
        stopId: stopId,
        hour: now.hour,
        dayOfWeek: now.weekday - 1, // Monday = 0
        latitude: lat,
        longitude: lon,
      );
    } catch (e) {
      _error = 'Error predicting demand: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadRouteSuggestions() async {
    try {
      _routeSuggestions = await ApiService.suggestRoutes(maxRoutes: 20);
    } catch (e) {
      _error = 'Error loading route suggestions: $e';
    }
  }

  Future<void> loadAnalytics() async {
    try {
      _analytics = await ApiService.getAnalytics();
      print("LOADED ANALYTICS: $_analytics"); // ✅ Add this
    } catch (e) {
      _error = 'Error loading analytics: $e';
    }
  }

  void setViabilityFilter(String viability) {
    _viabilityFilter = viability;
    notifyListeners();
  }

  void setDemandThreshold(double threshold) {
    _demandThreshold = threshold;
    notifyListeners();
  }

  List<dynamic> _filteredRouteSuggestions() {
    return _routeSuggestions.where((route) {
      final demand = route['estimated_demand'] ?? 0;
      final viability = route['viability'] ?? '';
      final passesDemand = demand >= _demandThreshold;
      final passesViability = _viabilityFilter == "All" ||
          viability == "${_viabilityFilter} Viability";
      return passesDemand && passesViability;
    }).toList();
  }

  void setRoutePolylines(List<List<LatLng>> shapePoints) {
    _routePolylines = shapePoints;
    notifyListeners();
  }
}
