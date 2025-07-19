// lib/models/stop.dart
class Stop {
  final String stopId;
  final double latitude;
  final double longitude;
  final String? name;
  final double? demand;
  final Map<String, dynamic>? additionalData;

  Stop({
    required this.stopId,
    required this.latitude,
    required this.longitude,
    this.name,
    this.demand,
    this.additionalData,
  });

  factory Stop.fromJson(Map<String, dynamic> json) {
    return Stop(
      stopId: json['stop_id']?.toString() ?? '',
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
      name: json['name']?.toString(),
      demand:
          json['demand'] != null ? (json['demand'] as num).toDouble() : null,
      additionalData: json,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stop_id': stopId,
      'latitude': latitude,
      'longitude': longitude,
      if (name != null) 'name': name,
      if (demand != null) 'demand': demand,
    };
  }
}
