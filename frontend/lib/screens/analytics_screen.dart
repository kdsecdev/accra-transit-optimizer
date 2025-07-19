// lib/screens/analytics_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/transit_provider.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<TransitProvider>(
      builder: (context, provider, child) {
        if (provider.isLoadingAnalytics) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading analytics...'),
              ],
            ),
          );
        }

        if (provider.error != null) {
          return _buildErrorView(provider);
        }

        if (provider.analytics == null) {
          return const Center(
            child: Text('No analytics data available'),
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.loadAnalytics(),
          child: _buildAnalyticsContent(provider.analytics!),
        );
      },
    );
  }

  Widget _buildErrorView(TransitProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          const Text('Failed to load analytics',
              style: TextStyle(fontSize: 18)),
          const SizedBox(height: 8),
          Text(provider.error!, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => provider.loadAnalytics(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsContent(Map<String, dynamic> analytics) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildOverviewCard(analytics),
        const SizedBox(height: 16),
        _buildDemandAnalysisCard(analytics),
        const SizedBox(height: 16),
        _buildRouteAnalysisCard(analytics),
        const SizedBox(height: 16),
        _buildRecommendationsCard(analytics),
      ],
    );
  }

  Widget _buildOverviewCard(Map<String, dynamic> analytics) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('System Overview',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildStatRow(
                'Total Stops', analytics['total_stops']?.toString() ?? 'N/A'),
            _buildStatRow(
                'Total Routes', analytics['total_routes']?.toString() ?? 'N/A'),
            _buildStatRow('Active Vehicles',
                analytics['active_vehicles']?.toString() ?? 'N/A'),
            _buildStatRow('Average Demand',
                (analytics['avg_demand'] as num?)?.toStringAsFixed(1) ?? 'N/A'),
          ],
        ),
      ),
    );
  }

  Widget _buildDemandAnalysisCard(Map<String, dynamic> analytics) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Demand Analysis',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildStatRow('Peak Hours',
                (analytics['peak_hours'] as List?)?.join(', ') ?? 'N/A'),
            _buildStatRow('Highest Demand Stop',
                analytics['highest_demand_stop']?.toString() ?? 'N/A'),
            _buildStatRow('Lowest Demand Stop',
                analytics['lowest_demand_stop']?.toString() ?? 'N/A'),
            _buildStatRow('Average Wait Time',
                analytics['avg_wait_time']?.toString() ?? 'N/A'),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteAnalysisCard(Map<String, dynamic> analytics) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Route Analysis',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildStatRow('Most Efficient Route',
                analytics['most_efficient_route']?.toString() ?? 'N/A'),
            _buildStatRow('Busiest Route',
                analytics['busiest_route']?.toString() ?? 'N/A'),
            _buildStatRow('Route Coverage',
                analytics['route_coverage']?.toString() ?? 'N/A'),
            _buildStatRow('Optimization Score',
                analytics['optimization_score']?.toString() ?? 'N/A'),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationsCard(Map<String, dynamic> analytics) {
    final recommendations = analytics['recommendations'] as List? ?? [];

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('AI Recommendations',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            if (recommendations.isEmpty)
              const Text('No recommendations available')
            else
              ...recommendations.map((rec) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.lightbulb_outline,
                            size: 16, color: Colors.orange),
                        const SizedBox(width: 8),
                        Expanded(child: Text(rec.toString())),
                      ],
                    ),
                  )),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
