// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../providers/transit_provider.dart';
import 'analytics_screen.dart';
import 'route_suggestion_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MapController _mapController = MapController();
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TransitProvider>(context, listen: false).loadAllData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accra Transit Optimizer'),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _refreshData(),
          ),
        ],
      ),
      body: Consumer<TransitProvider>(
        builder: (context, provider, child) {
          return IndexedStack(
            index: _currentIndex,
            children: [
              _buildMapView(provider),
              const AnalyticsScreen(),
              const RouteSuggestionScreen(),
            ],
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
          BottomNavigationBarItem(
              icon: Icon(Icons.analytics), label: 'Analytics'),
          BottomNavigationBarItem(icon: Icon(Icons.route), label: 'Routes'),
        ],
      ),
    );
  }

  Widget _buildMapView(TransitProvider provider) {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: const LatLng(5.6037, -0.1870),
            initialZoom: 12.0,
            minZoom: 8.0,
            maxZoom: 18.0,
            onTap: (tapPosition, point) => _onMapTap(point, provider),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.accra_transit_optimizer',
            ),
            if (provider.stopMarkers.isNotEmpty)
              MarkerLayer(markers: provider.stopMarkers),
          ],
        ),
        if (provider.isLoading) _buildLoadingOverlay(),
        if (provider.error != null) _buildErrorOverlay(provider),
        if (provider.currentDemand != null)
          _buildDemandOverlay(provider.currentDemand!),
        _buildMapControls(),
      ],
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.3),
      child: const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading transit data...'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorOverlay(TransitProvider provider) {
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Card(
        color: Colors.red[50],
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.red),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(provider.error!,
                      style: const TextStyle(color: Colors.red))),
              TextButton(
                onPressed: () => provider.clearError(),
                child: const Text('Dismiss'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDemandOverlay(Map<String, dynamic> demand) {
    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: Card(
        elevation: 8,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Stop ${demand['stop_id'] ?? 'Unknown'}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () =>
                        Provider.of<TransitProvider>(context, listen: false)
                            .clearCurrentDemand(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('Demand Score: ${demand['demand_score'] ?? 'N/A'}'),
              Text('Demand Level: ${demand['demand_level'] ?? 'N/A'}'),
              if (demand['recommendations'] != null)
                ...((demand['recommendations'] as List)
                    .map((r) => Text('• $r'))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMapControls() {
    return Positioned(
      top: 16,
      right: 16,
      child: Column(
        children: [
          FloatingActionButton(
            mini: true,
            onPressed: () =>
                _mapController.move(const LatLng(5.6037, -0.1870), 12.0),
            child: const Icon(Icons.my_location),
          ),
        ],
      ),
    );
  }

  void _onMapTap(LatLng point, TransitProvider provider) {
    final nearest = provider.findNearestStop(point.latitude, point.longitude);
    if (nearest != null) {
      provider.predictDemand(
          nearest.stopId, nearest.latitude, nearest.longitude);
    }
  }

  Future<void> _refreshData() async {
    await Provider.of<TransitProvider>(context, listen: false).loadAllData();
  }
}
