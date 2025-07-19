// lib/providers/transit_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/route_suggestion.dart';
import '../models/stop.dart';
import '../services/api_service.dart';

class TransitProvider extends ChangeNotifier {
  // Data
  List<Stop> _stops = [];
  List<RouteSuggestion> _routeSuggestions = [];
  Map<String, dynamic>? _analytics;
  Map<String, dynamic>? _currentDemand;
  Map<String, dynamic>? _customRoute;

  // Loading states
  bool _isLoading = false;
  bool _isLoadingStops = false;
  bool _isLoadingRoutes = false;
  bool _isLoadingAnalytics = false;
  bool _isLoadingDemand = false;

  // Error state
  String? _error;

  // Filters
  String _viabilityFilter = "All";
  double _demandThreshold = 0.0;

  // Getters
  List<Stop> get stops => _stops;
  List<RouteSuggestion> get routeSuggestions => _filteredRouteSuggestions;
  Map<String, dynamic>? get analytics => _analytics;
  Map<String, dynamic>? get currentDemand => _currentDemand;
  Map<String, dynamic>? get customRoute => _customRoute;

  bool get isLoading => _isLoading;
  bool get isLoadingStops => _isLoadingStops;
  bool get isLoadingRoutes => _isLoadingRoutes;
  bool get isLoadingAnalytics => _isLoadingAnalytics;
  bool get isLoadingDemand => _isLoadingDemand;

  String? get error => _error;
  String get viabilityFilter => _viabilityFilter;
  double get demandThreshold => _demandThreshold;

  // Filtered route suggestions
  List<RouteSuggestion> get _filteredRouteSuggestions {
    return _routeSuggestions.where((route) {
      final demand = route.estimatedDemand ?? 0.0;
      final viability = route.viability ?? '';

      final passesDemand = demand >= _demandThreshold;
      final passesViability = _viabilityFilter == "All" ||
          viability.toLowerCase().contains(_viabilityFilter.toLowerCase());

      return passesDemand && passesViability;
    }).toList();
  }

  // Markers for map
  List<Marker> get stopMarkers {
    return _stops.map((stop) {
      return Marker(
        point: LatLng(stop.latitude, stop.longitude),
        width: 40,
        height: 40,
        child: GestureDetector(
          onTap: () =>
              predictDemand(stop.stopId, stop.latitude, stop.longitude),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.directions_bus,
              color: _getStopColor(stop.demand),
              size: 24,
            ),
          ),
        ),
      );
    }).toList();
  }

  Color _getStopColor(double? demand) {
    if (demand == null) return Colors.grey;
    if (demand < 30) return Colors.green;
    if (demand < 70) return Colors.orange;
    return Colors.red;
  }

  // Clear methods
  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearCurrentDemand() {
    _currentDemand = null;
    notifyListeners();
  }

  void clearCustomRoute() {
    _customRoute = null;
    notifyListeners();
  }

  // Load all data
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
      _error = "Failed to load data: ${e.toString()}";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load stops
  Future<void> loadStops() async {
    _isLoadingStops = true;
    notifyListeners();

    try {
      final stopsData =
          await ApiService.getStops(limit: 100, includeDemand: true);
      _stops = stopsData.map((data) => Stop.fromJson(data)).toList();
    } catch (e) {
      _error = "Failed to load stops: ${e.toString()}";
    } finally {
      _isLoadingStops = false;
      notifyListeners();
    }
  }

  // Load route suggestions
  Future<void> loadRouteSuggestions() async {
    _isLoadingRoutes = true;
    notifyListeners();

    try {
      final routesData = await ApiService.suggestRoutes(maxRoutes: 20);
      _routeSuggestions =
          routesData.map((data) => RouteSuggestion.fromJson(data)).toList();
    } catch (e) {
      _error = "Failed to load route suggestions: ${e.toString()}";
    } finally {
      _isLoadingRoutes = false;
      notifyListeners();
    }
  }

  // Load analytics
  Future<void> loadAnalytics() async {
    _isLoadingAnalytics = true;
    notifyListeners();

    try {
      _analytics = await ApiService.getAnalytics();
    } catch (e) {
      _error = "Failed to load analytics: ${e.toString()}";
    } finally {
      _isLoadingAnalytics = false;
      notifyListeners();
    }
  }

  // Predict demand
  Future<void> predictDemand(String stopId, double lat, double lon) async {
    _isLoadingDemand = true;
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
      _error = "Failed to predict demand: ${e.toString()}";
    } finally {
      _isLoadingDemand = false;
      notifyListeners();
    }
  }

  // Suggest custom route
  Future<void> suggestCustomRoute(
      double startLat, double startLon, double endLat, double endLon) async {
    _isLoading = true;
    notifyListeners();

    try {
      _customRoute = await ApiService.suggestFromTo(
        startLat: startLat,
        startLon: startLon,
        endLat: endLat,
        endLon: endLon,
      );
    } catch (e) {
      _error = "Failed to suggest custom route: ${e.toString()}";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Filters
  void setViabilityFilter(String filter) {
    _viabilityFilter = filter;
    notifyListeners();
  }

  void setDemandThreshold(double threshold) {
    _demandThreshold = threshold;
    notifyListeners();
  }

  // Utility methods
  Stop? findNearestStop(double lat, double lon) {
    if (_stops.isEmpty) return null;

    final distance = Distance();
    final point = LatLng(lat, lon);

    return _stops.reduce((a, b) {
      final distanceA =
          distance.as(LengthUnit.Meter, point, LatLng(a.latitude, a.longitude));
      final distanceB =
          distance.as(LengthUnit.Meter, point, LatLng(b.latitude, b.longitude));
      return distanceA < distanceB ? a : b;
    });
  }
}
