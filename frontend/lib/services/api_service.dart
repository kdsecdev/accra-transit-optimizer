// lib/services/api_service.dart
import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic responseBody;

  ApiException(this.message, {this.statusCode, this.responseBody});

  @override
  String toString() => 'ApiException: $message';
}

class ApiService {
  static const String baseUrl =
      "https://accra-transit-optimizer.onrender.com/api/v1";
  static const Duration defaultTimeout = Duration(seconds: 30);
  static final http.Client _client = http.Client();

  static Future<dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        return Future.value(json.decode(response.body));
      } catch (e) {
        throw ApiException("Failed to parse response JSON");
      }
    } else {
      throw ApiException(
        "Request failed with status ${response.statusCode}",
        statusCode: response.statusCode,
        responseBody: response.body,
      );
    }
  }

  static Future<List<dynamic>> getStops({
    int limit = 100,
    bool includeDemand = true,
  }) async {
    try {
      final response = await _client
          .get(Uri.parse(
              "$baseUrl/stops?limit=$limit&include_demand=$includeDemand"))
          .timeout(defaultTimeout);

      final data = await _handleResponse(response);
      return data is List ? data : [];
    } catch (e) {
      throw ApiException("Failed to fetch stops: ${e.toString()}");
    }
  }

  static Future<Map<String, dynamic>> getAnalytics() async {
    try {
      final response = await _client
          .get(Uri.parse("$baseUrl/analytics"))
          .timeout(defaultTimeout);

      return await _handleResponse(response);
    } catch (e) {
      throw ApiException("Failed to fetch analytics: ${e.toString()}");
    }
  }

  static Future<Map<String, dynamic>> predictDemand({
    required String stopId,
    required int hour,
    required int dayOfWeek,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await _client
          .post(
            Uri.parse("$baseUrl/predict_demand"),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              "stop_id": stopId,
              "hour": hour,
              "day_of_week": dayOfWeek,
              "latitude": latitude,
              "longitude": longitude,
            }),
          )
          .timeout(defaultTimeout);

      return await _handleResponse(response);
    } catch (e) {
      throw ApiException("Failed to predict demand: ${e.toString()}");
    }
  }

  static Future<List<dynamic>> suggestRoutes({int maxRoutes = 10}) async {
    try {
      final response = await _client
          .post(
            Uri.parse("$baseUrl/suggest_routes"),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({"max_routes": maxRoutes}),
          )
          .timeout(defaultTimeout);

      final data = await _handleResponse(response);
      return data is List ? data : [];
    } catch (e) {
      throw ApiException("Failed to suggest routes: ${e.toString()}");
    }
  }

  static Future<Map<String, dynamic>> suggestFromTo({
    required double startLat,
    required double startLon,
    required double endLat,
    required double endLon,
  }) async {
    try {
      final response = await _client
          .post(
            Uri.parse("$baseUrl/suggest_from_to"),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              "start_latitude": startLat,
              "start_longitude": startLon,
              "end_latitude": endLat,
              "end_longitude": endLon,
            }),
          )
          .timeout(defaultTimeout);

      return await _handleResponse(response);
    } catch (e) {
      throw ApiException("Failed to suggest route: ${e.toString()}");
    }
  }

  static Future<Map<String, dynamic>> submitGpsData({
    required double latitude,
    required double longitude,
    required String vehicleId,
    required String routeId,
    int? passengers,
    String? timestamp,
  }) async {
    try {
      final response = await _client
          .post(
            Uri.parse("$baseUrl/submit_gps"),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              "latitude": latitude,
              "longitude": longitude,
              "vehicle_id": vehicleId,
              "route_id": routeId,
              if (passengers != null) "passengers": passengers,
              if (timestamp != null) "timestamp": timestamp,
            }),
          )
          .timeout(defaultTimeout);

      return await _handleResponse(response);
    } catch (e) {
      throw ApiException("Failed to submit GPS data: ${e.toString()}");
    }
  }

  static Future<Map<String, dynamic>> healthCheck() async {
    try {
      final response = await _client
          .get(Uri.parse("$baseUrl/health"))
          .timeout(defaultTimeout);

      return await _handleResponse(response);
    } catch (e) {
      throw ApiException("Health check failed: ${e.toString()}");
    }
  }
}
