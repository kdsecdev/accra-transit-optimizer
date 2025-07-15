import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/transit_provider.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TransitProvider>(context, listen: false);

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Transit Analytics'),
      ),
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            CupertinoSliverRefreshControl(
              onRefresh: () async {
                await provider.loadAnalytics();
              },
            ),
            SliverToBoxAdapter(
              child: Consumer<TransitProvider>(
                builder: (context, provider, _) {
                  final analytics = provider.analytics;

                  if (provider.isLoading && analytics == null) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.only(top: 80),
                        child: CupertinoActivityIndicator(radius: 16),
                      ),
                    );
                  }

                  if (analytics == null) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.only(top: 80),
                        child: Text(
                          "Analytics data not available",
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    );
                  }

                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildCard(
                          title: 'Total Stops',
                          value: analytics['total_stops'].toString(),
                          icon: CupertinoIcons.location,
                        ),
                        _buildCard(
                          title: 'Total Routes',
                          value: analytics['total_routes'].toString(),
                          icon: CupertinoIcons.bus,
                        ),
                        _buildCard(
                          title: 'Average Demand',
                          value: analytics['average_demand'].toStringAsFixed(1),
                          icon: CupertinoIcons.chart_bar_alt_fill,
                        ),
                        _buildCard(
                          title: 'High Demand Stops',
                          value:
                              (analytics['high_demand_stops'] as List<dynamic>)
                                  .join(', '),
                          icon: CupertinoIcons.flame_fill,
                        ),
                        _buildCard(
                          title: 'Last Updated',
                          value: analytics['last_updated'],
                          icon: CupertinoIcons.time,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(icon, color: CupertinoColors.activeBlue, size: 28),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(value),
      ),
    );
  }
}
