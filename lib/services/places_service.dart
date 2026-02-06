import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/place.dart';

class PlacesService {
  final String? _apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'];

  Future<List<Place>> getNearbyPlaces(double lat, double lng, String type) async {
    if (_apiKey == null || _apiKey!.contains('YOUR_')) {
      throw Exception('Google Maps API Key not configured');
    }

    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
      '?location=$lat,$lng'
      '&radius=1500'
      '&type=$type'
      '&key=$_apiKey'
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'OK' || data['status'] == 'ZERO_RESULTS') {
        final List<dynamic> results = data['results'];
        return results.map((json) => Place.fromJson(json)).toList();
      } else {
        throw Exception('Google Places API Error: ${data['status']} - ${data['error_message']}');
      }
    } else {
      throw Exception('Failed to load places: ${response.statusCode}');
    }
  }
}
