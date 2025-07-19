// lib/screens/route_suggestion_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/route_suggestion.dart';
import '../providers/transit_provider.dart';

class RouteSuggestionScreen extends StatefulWidget {
  const RouteSuggestionScreen({Key? key}) : super(key: key);

  @override
  State<RouteSuggestionScreen> createState() => _RouteSuggestionScreenState();
}

class _RouteSuggestionScreenState extends State<RouteSuggestionScreen> {
  @override
  void initState() {
    super.initState();
    // Load route suggestions when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransitProvider>().loadRouteSuggestions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TransitProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Route Suggestions'),
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: () => _showFilterDialog(context, provider),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => provider.loadRouteSuggestions(),
              ),
            ],
          ),
          body: Column(
            children: [
              _buildFilterChips(provider),
              Expanded(child: _buildBody(provider)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChips(TransitProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Viability: ',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Expanded(
                child: Wrap(
                  spacing: 8,
                  children: ['All', 'High', 'Medium', 'Low'].map((filter) {
                    final isSelected = provider.viabilityFilter == filter;
                    return FilterChip(
                      label: Text(filter),
                      selected: isSelected,
                      onSelected: (selected) {
                        provider.setViabilityFilter(filter);
                      },
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('Min Demand: ',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Expanded(
                child: Slider(
                  value: provider.demandThreshold,
                  max: 100,
                  divisions: 10,
                  label: provider.demandThreshold.round().toString(),
                  onChanged: (value) {
                    provider.setDemandThreshold(value);
                  },
                ),
              ),
              Text('${provider.demandThreshold.round()}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBody(TransitProvider provider) {
    if (provider.isLoadingRoutes) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading route suggestions...'),
          ],
        ),
      );
    }

    if (provider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Error: ${provider.error}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                provider.clearError();
                provider.loadRouteSuggestions();
              },
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    if (provider.routeSuggestions.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.route,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No route suggestions found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Try adjusting your filters or refresh the data',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: provider.routeSuggestions.length,
      itemBuilder: (context, index) {
        final route = provider.routeSuggestions[index];
        return _buildRouteCard(route, index);
      },
    );
  }

  Widget _buildRouteCard(RouteSuggestion route, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _selectRoute(route),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      route.routeName ?? 'Route ${route.routeId}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (route.viability != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getViabilityColor(route.viability!),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        route.viability!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Route ID: ${route.routeId}',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (route.duration != null) ...[
                    const Icon(Icons.access_time, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text('${route.duration} min'),
                    const SizedBox(width: 16),
                  ],
                  if (route.distance != null) ...[
                    const Icon(Icons.straighten, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text('${route.distance!.toStringAsFixed(1)} km'),
                    const SizedBox(width: 16),
                  ],
                  const Icon(Icons.directions_bus,
                      size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text('${route.stops.length} stops'),
                ],
              ),
              if (route.estimatedDemand != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.people, size: 16, color: Colors.blue),
                    const SizedBox(width: 4),
                    Text(
                      'Demand: ${route.estimatedDemand!.toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: _getDemandColor(route.estimatedDemand!),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
              if (route.stops.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on,
                        size: 16, color: Colors.green),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        route.stops.first.name ?? 'Unknown Stop',
                        style: const TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (route.stops.length > 1) ...[
                  const SizedBox(height: 4),
                  const Row(
                    children: [
                      SizedBox(width: 20),
                      Text(
                        '⋮',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          size: 16, color: Colors.red),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          route.stops.last.name ?? 'Unknown Stop',
                          style: const TextStyle(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                if (route.stops.length > 2)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'via ${route.stops.length - 2} intermediate stop${route.stops.length > 3 ? 's' : ''}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getViabilityColor(String viability) {
    switch (viability.toLowerCase()) {
      case 'high':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getDemandColor(double demand) {
    if (demand < 30) return Colors.green;
    if (demand < 70) return Colors.orange;
    return Colors.red;
  }

  void _showFilterDialog(BuildContext context, TransitProvider provider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Filter Routes'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Adjust filters to refine route suggestions'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  provider.setViabilityFilter('All');
                  provider.setDemandThreshold(0.0);
                },
                child: const Text('Reset Filters'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _selectRoute(RouteSuggestion route) {
    // Show route details in a bottom sheet or navigate to details screen
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        route.routeName ?? 'Route ${route.routeId}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: route.stops.length,
                      itemBuilder: (context, index) {
                        final stop = route.stops[index];
                        return ListTile(
                          leading: CircleAvatar(
                            radius: 12,
                            backgroundColor: index == 0
                                ? Colors.green
                                : index == route.stops.length - 1
                                    ? Colors.red
                                    : Colors.blue,
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(stop.name ?? 'Unknown Stop'),
                          subtitle: Text(
                            'ID: ${stop.stopId}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: stop.demand != null
                              ? Chip(
                                  label: Text(
                                      '${stop.demand!.toStringAsFixed(0)}%'),
                                  backgroundColor: _getDemandColor(stop.demand!)
                                      .withOpacity(0.2),
                                )
                              : null,
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
