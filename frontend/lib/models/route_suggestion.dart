// lib/models/route_suggestion.dart
import 'package:accra_transit_optimizer/models/stop.dart';

class RouteSuggestion {
  final String routeId;
  final String? routeName;
  final List<Stop> stops;
  final double? estimatedDemand;
  final String? viability;
  final double? distance;
  final int? duration;
  final Map<String, dynamic>? additionalData;

  RouteSuggestion({
    required this.routeId,
    this.routeName,
    required this.stops,
    this.estimatedDemand,
    this.viability,
    this.distance,
    this.duration,
    this.additionalData,
  });

  factory RouteSuggestion.fromJson(Map<String, dynamic> json) {
    return RouteSuggestion(
      routeId: json['route_id']?.toString() ?? '',
      routeName: json['route_name']?.toString(),
      stops: (json['stops'] as List?)
              ?.map((stop) => Stop.fromJson(stop))
              .toList() ??
          [],
      estimatedDemand: json['estimated_demand'] != null
          ? (json['estimated_demand'] as num).toDouble()
          : null,
      viability: json['viability']?.toString(),
      distance: json['distance'] != null
          ? (json['distance'] as num).toDouble()
          : null,
      duration:
          json['duration'] != null ? (json['duration'] as num).toInt() : null,
      additionalData: json,
    );
  }
}
