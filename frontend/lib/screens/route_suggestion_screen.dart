// lib/screens/route_suggestion_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../providers/transit_provider.dart';

class RouteSuggestionScreen extends StatefulWidget {
  @override
  _RouteSuggestionScreenState createState() => _RouteSuggestionScreenState();
}

class _RouteSuggestionScreenState extends State<RouteSuggestionScreen> {
  String _viabilityFilter = "All";
  double _demandThreshold = 30.0;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TransitProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Suggested Routes'),
        backgroundColor: Colors.blue[900],
      ),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: LatLng(5.6037, -0.1870),
              initialZoom: 12,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.accra_transit_optimizer',
              ),
              MarkerLayer(markers: provider.routeMarkers),
              PolylineLayer(polylines: provider.routePolylines),
            ],
          ),
          if (provider.isLoading)
            const Center(child: CircularProgressIndicator()),
          _buildFilterOverlay(),
        ],
      ),
    );
  }

  Widget _buildFilterOverlay() {
    return Positioned(
      top: 12,
      left: 12,
      right: 12,
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              DropdownButton<String>(
                value: _viabilityFilter,
                items: ["All", "High", "Medium", "Low"]
                    .map((v) => DropdownMenuItem<String>(
                          value: v,
                          child: Text("Viability: $v"),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _viabilityFilter = value;
                    });
                    // TODO: Apply filter to provider
                  }
                },
              ),
              DropdownButton<double>(
                value: _demandThreshold,
                items: [30.0, 50.0, 70.0]
                    .map((v) => DropdownMenuItem<double>(
                          value: v,
                          child: Text("Demand > $v"),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _demandThreshold = value;
                    });
                    // TODO: Apply filter to provider
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
