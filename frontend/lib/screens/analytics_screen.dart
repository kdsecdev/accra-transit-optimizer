// lib/screens/analytics_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/transit_provider.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TransitProvider>(context);
    final analytics = provider.analytics;
    if (analytics == null) {
      return const Center(child: CupertinoActivityIndicator());
    }

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text("Analytics"),
        backgroundColor: CupertinoColors.white,
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildAnalyticsCard(
              icon: CupertinoIcons.bus,
              title: "Total Routes",
              value: analytics["total_routes"].toString(),
            ),
            _buildAnalyticsCard(
              icon: CupertinoIcons.location_solid,
              title: "Total Stops",
              value: analytics["total_stops"].toString(),
            ),
            _buildAnalyticsCard(
              icon: CupertinoIcons.chart_bar,
              title: "Avg Demand",
              value: analytics["avg_demand"].toStringAsFixed(1),
            ),
            _buildAnalyticsCard(
              icon: CupertinoIcons.clock,
              title: "Peak Hours",
              value: (analytics["peak_hours"] as List).join(', '),
            ),
            _buildAnalyticsCard(
              icon: CupertinoIcons.lightbulb,
              title: "Recommendations",
              value: (analytics["recommendations"] as List).join('\n• '),
              multiline: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsCard({
    required IconData icon,
    required String title,
    required String value,
    bool multiline = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        crossAxisAlignment:
            multiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 32, color: CupertinoColors.activeBlue),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  multiline ? "• $value" : value,
                  style: const TextStyle(fontSize: 15),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
