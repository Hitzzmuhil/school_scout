import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class OpenRouteService {
  final String? _apiKey = dotenv.env['OPENROUTESERVICE_API_KEY'];
  static const String _baseUrl = 'https://api.openrouteservice.org/geocode/search';

  Future<List<Map<String, dynamic>>> searchAddress(String query) async {
    if (_apiKey == null) {
      throw Exception('OpenRouteService API Key not configured');
    }

    // ORS Geocoding API
    final url = Uri.parse(
      '$_baseUrl'
      '?api_key=$_apiKey'
      '&text=$query'
    );

    try {
      final response = await http.get(url, headers: {
        'Accept': 'application/json',
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> features = data['features'];

        return features.map((feature) {
          final props = feature['properties'];
          final geometry = feature['geometry'];
          final coords = geometry['coordinates'] as List; // [lon, lat]

          return {
            'name': props['name'] ?? props['label'] ?? 'Unknown',
            'label': props['label'],
            'lat': coords[1],
            'lng': coords[0],
          };
        }).toList();
      } else {
         throw Exception('OpenRouteService Error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to geocode address: $e');
    }
  }
}
