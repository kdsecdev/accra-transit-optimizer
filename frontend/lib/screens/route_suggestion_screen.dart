// lib/screens/route_suggestion_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../providers/transit_provider.dart';

class RouteSuggestionScreen extends StatefulWidget {
  const RouteSuggestionScreen({super.key});

  @override
  State<RouteSuggestionScreen> createState() => _RouteSuggestionScreenState();
}

class _RouteSuggestionScreenState extends State<RouteSuggestionScreen> {
  final _startLat = TextEditingController();
  final _startLon = TextEditingController();
  final _endLat = TextEditingController();
  final _endLon = TextEditingController();

  @override
  void initState() {
    super.initState();
    _detectLocation();
  }

  Future<void> _detectLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      Fluttertoast.showToast(msg: "Location services are disabled.");
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.deniedForever) {
      Fluttertoast.showToast(
          msg: "Location permissions are permanently denied.");
      return;
    }

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        Fluttertoast.showToast(msg: "Location permission denied.");
        return;
      }
    }

    Position position = await Geolocator.getCurrentPosition();
    _startLat.text = position.latitude.toString();
    _startLon.text = position.longitude.toString();

    Fluttertoast.showToast(
      msg: "Location detected: ${position.latitude}, ${position.longitude}",
      toastLength: Toast.LENGTH_SHORT,
      backgroundColor: Colors.green,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TransitProvider>(context);

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text("Route Suggestion"),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildCupertinoText("Start Latitude", _startLat),
              const SizedBox(height: 10),
              _buildCupertinoText("Start Longitude", _startLon),
              const SizedBox(height: 10),
              _buildCupertinoText("End Latitude", _endLat),
              const SizedBox(height: 10),
              _buildCupertinoText("End Longitude", _endLon),
              const SizedBox(height: 20),
              CupertinoButton.filled(
                child: const Text("Suggest Route"),
                onPressed: () async {
                  final sLat = double.tryParse(_startLat.text);
                  final sLon = double.tryParse(_startLon.text);
                  final eLat = double.tryParse(_endLat.text);
                  final eLon = double.tryParse(_endLon.text);

                  if (sLat != null &&
                      sLon != null &&
                      eLat != null &&
                      eLon != null) {
                    await provider.suggestRouteFromTo(sLat, sLon, eLat, eLon);
                    if (provider.error != null) {
                      Fluttertoast.showToast(
                        msg: provider.error!,
                        backgroundColor: Colors.redAccent,
                      );
                    }
                  } else {
                    Fluttertoast.showToast(
                      msg: "Invalid coordinates entered.",
                      backgroundColor: Colors.red,
                    );
                  }
                },
              ),
              const SizedBox(height: 30),
              SizedBox(
                height: 300,
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: LatLng(5.6037, -0.1870),
                    initialZoom: 13,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName:
                          'com.example.accra_transit_optimizer',
                    ),
                    if (provider.suggestedRoute != null)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: (provider.suggestedRoute!["shape"] as List)
                                .map((p) => LatLng(p["lat"], p["lon"]))
                                .toList(),
                            strokeWidth: 5.0,
                            color: Colors.deepOrange,
                          ),
                        ],
                      ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCupertinoText(String label, TextEditingController controller) {
    return CupertinoTextField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: true),
      placeholder: label,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}
