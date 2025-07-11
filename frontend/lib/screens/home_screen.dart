import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../providers/transit_provider.dart';
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
    final provider = Provider.of<TransitProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Accra Transit Optimizer'),
        backgroundColor: Colors.blue[900],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildMapView(provider),
          _buildAnalyticsView(provider),
          RouteSuggestionScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
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
            initialCenter: LatLng(5.6037, -0.1870),
            initialZoom: 12,
            onTap: (tapPosition, point) {
              _onMapTap(point, provider);
            },
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.accra_transit_optimizer',
            ),
            MarkerLayer(markers: provider.stopMarkers),
            MarkerLayer(markers: provider.routeMarkers),
          ],
        ),
        if (provider.isLoading)
          const Center(child: CircularProgressIndicator()),
        if (provider.currentDemand != null)
          _buildDemandOverlay(provider.currentDemand!),
      ],
    );
  }

  Widget _buildAnalyticsView(TransitProvider provider) {
    final analytics = provider.analytics;

    if (provider.error != null) {
      return Center(child: Text('Error: ${provider.error}'));
    }

    if (analytics == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildInfoTile('Total Stops', analytics['total_stops'].toString()),
        _buildInfoTile('Total Routes', analytics['total_routes'].toString()),
        _buildInfoTile(
            'Avg Demand', (analytics['avg_demand'] as num).toStringAsFixed(1)),
        _buildInfoTile(
            'Peak Hours', (analytics['peak_hours'] as List).join(', ')),
        _buildInfoTile('Recommendations',
            (analytics['recommendations'] as List).join('\n')),
      ],
    );
  }

  Widget _buildInfoTile(String title, String subtitle) {
    return Card(
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
      ),
    );
  }

  void _onMapTap(LatLng point, TransitProvider provider) {
    final nearest =
        provider.stops.fold<Map<String, dynamic>?>(null, (closest, stop) {
      final stopLat = stop['latitude'];
      final stopLon = stop['longitude'];
      final distance = Distance().as(
        LengthUnit.Meter,
        LatLng(stopLat, stopLon),
        point,
      );
      if (closest == null) return stop;
      final closestDist = Distance().as(
        LengthUnit.Meter,
        LatLng(closest['latitude'], closest['longitude']),
        point,
      );
      return distance < closestDist ? stop : closest;
    });

    if (nearest != null) {
      provider.predictDemand(
          nearest['stop_id'], nearest['latitude'], nearest['longitude']);
    }
  }

  Widget _buildDemandOverlay(Map<String, dynamic> demand) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Card(
        margin: const EdgeInsets.all(12),
        color: Colors.white.withOpacity(0.95),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Demand for Stop ${demand['stop_id']}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('Score: ${demand['demand_score']}'),
              Text('Level: ${demand['demand_level']}'),
              if (demand['recommendations'] != null)
                ...((demand['recommendations'] as List)
                    .map((r) => Text("• $r"))),
            ],
          ),
        ),
      ),
    );
  }
}
