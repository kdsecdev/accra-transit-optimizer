// lib/providers/transit_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:latlong2/latlong.dart';

import '../services/api_service.dart';

class TransitProvider extends ChangeNotifier {
  List<dynamic> _stops = [];
  List<dynamic> _routeSuggestions = [];
  List<List<LatLng>> _routePolylines = [];
  Map<String, dynamic>? _currentDemand;
  Map<String, dynamic>? _analytics;
  Map<String, dynamic>? _suggestedRoute;
  bool _isLoading = false;
  String? _error;

  // Filters
  String _viabilityFilter = "All";
  double _demandThreshold = 30;

  List<dynamic> get stops => _stops;
  List<dynamic> get routeSuggestions => _filteredRouteSuggestions();
  Map<String, dynamic>? get currentDemand => _currentDemand;
  Map<String, dynamic>? get analytics => _analytics;
  Map<String, dynamic>? get suggestedRoute => _suggestedRoute;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get viabilityFilter => _viabilityFilter;
  double get demandThreshold => _demandThreshold;

  List<Marker> get stopMarkers => _stops.map((stop) {
        return Marker(
          point: LatLng(stop['latitude'], stop['longitude']),
          width: 40,
          height: 40,
          child:
              const Icon(Icons.location_pin, color: Colors.redAccent, size: 32),
        );
      }).toList();

  List<Marker> get routeMarkers => _routeSuggestions.map((route) {
        return Marker(
          point: LatLng(route['center_lat'], route['center_lon']),
          width: 36,
          height: 36,
          child: const Icon(Icons.directions_bus_filled,
              color: Colors.green, size: 30),
        );
      }).toList();

  List<Polyline> get routePolylines => _routePolylines.map((points) {
        return Polyline(
          points: points,
          strokeWidth: 5.0,
          color: Colors.deepPurpleAccent.withOpacity(0.8),
        );
      }).toList();

  void _showError(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.red[700],
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

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
      _showError("Stops did not load successfully");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadStops() async {
    try {
      _stops = await ApiService.getStops(limit: 100, includeDemand: true);
    } catch (e) {
      _error = 'Error loading stops: \$e';
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
        dayOfWeek: now.weekday - 1,
        latitude: lat,
        longitude: lon,
      );
    } catch (e) {
      _error = 'Error predicting demand: \$e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadRouteSuggestions() async {
    try {
      _routeSuggestions = await ApiService.suggestRoutes(maxRoutes: 20);
    } catch (e) {
      _error = 'Error loading route suggestions: \$e';
    }
  }

  Future<void> loadAnalytics() async {
    try {
      _analytics = await ApiService.getAnalytics();
    } catch (e) {
      _error = 'Error loading analytics: \$e';
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
          viability == "\${_viabilityFilter} Viability";
      return passesDemand && passesViability;
    }).toList();
  }

  void setRoutePolylines(List<List<LatLng>> shapePoints) {
    _routePolylines = shapePoints;
    notifyListeners();
  }

  Future<void> suggestRouteFromTo(
      double startLat, double startLon, double endLat, double endLon) async {
    _isLoading = true;
    notifyListeners();

    try {
      _suggestedRoute = await ApiService.suggestRouteFromTo(
          startLat, startLon, endLat, endLon);
    } catch (e) {
      _error = 'Error suggesting route: \$e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
