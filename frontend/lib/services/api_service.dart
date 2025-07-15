import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl =
      "https://accra-transit-optimizer.onrender.com/api/v1";

  static Future<List<dynamic>> getStops(
      {int limit = 100, bool includeDemand = true}) async {
    final response = await http.get(
      Uri.parse("$baseUrl/stops?limit=$limit&include_demand=$includeDemand"),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception("Failed to fetch stops; ${response.body}");
    }
  }

  static Future<Map<String, dynamic>> getAnalytics() async {
    final response = await http.get(Uri.parse("$baseUrl/analytics"));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception("Failed to fetch analytics; ${response.body}");
    }
  }

  static Future<Map<String, dynamic>> predictDemand({
    required String stopId,
    required int hour,
    required int dayOfWeek,
    required double latitude,
    required double longitude,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/predict_demand"),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        "stop_id": stopId,
        "hour": hour,
        "day_of_week": dayOfWeek,
        "latitude": latitude,
        "longitude": longitude,
      }),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception("Failed to predict demand; ${response.body}");
    }
  }

  static Future<List<dynamic>> suggestRoutes({int maxRoutes = 10}) async {
    final response = await http.post(
      Uri.parse("$baseUrl/suggest_routes"),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        "max_routes": maxRoutes,
      }),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception("Failed to suggest routes; ${response.body}");
    }
  }

  static Future<Map<String, dynamic>> suggestRouteFromTo(
      double startLat, double startLon, double endLat, double endLon) async {
    final response = await http.post(
      Uri.parse("$baseUrl/suggest_route"),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        "start_latitude": startLat,
        "start_longitude": startLon,
        "end_latitude": endLat,
        "end_longitude": endLon,
      }),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception("Failed to suggest custom route; ${response.body}");
    }
  }
}
