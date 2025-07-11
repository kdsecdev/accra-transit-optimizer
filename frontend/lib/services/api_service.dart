// lib/services/api_service.dart
import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http:// 192.168.171.61/api/v1';

  static Future<Map<String, dynamic>> predictDemand({
    required String stopId,
    required int hour,
    required int dayOfWeek,
    required double latitude,
    required double longitude,
  }) async {
    final url = Uri.parse('$baseUrl/predict_demand');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'stop_id': stopId,
        'hour': hour,
        'day_of_week': dayOfWeek,
        'latitude': latitude,
        'longitude': longitude,
      }),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Demand prediction failed: ${response.body}');
    }
  }

  static Future<List<dynamic>> suggestRoutes({
    int maxRoutes = 5,
    double minDemandThreshold = 30.0,
  }) async {
    final url = Uri.parse('$baseUrl/suggest_routes');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'max_routes': maxRoutes,
        'min_demand_threshold': minDemandThreshold,
      }),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Route suggestion failed: ${response.body}');
    }
  }

  static Future<List<dynamic>> getStops({
    int limit = 100,
    bool includeDemand = false,
  }) async {
    final url =
        Uri.parse('$baseUrl/stops?limit=$limit&include_demand=$includeDemand');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch stops: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> getAnalytics() async {
    final url = Uri.parse('$baseUrl/analytics');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch analytics: ${response.body}');
    }
  }
}
