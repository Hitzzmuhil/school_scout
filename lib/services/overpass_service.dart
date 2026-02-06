import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/place.dart';

class OverpassService {
  // Overpass API endpoint
  static const String _overpassUrl = 'https://overpass-api.de/api/interpreter';

  Future<List<Place>> getNearbyPlaces(double lat, double lng, String type) async {
    String queryTag = "";
    
    if (type == 'library') {
        queryTag = '["amenity"="library"]';
    } else if (type == 'cafe') {
        queryTag = '["amenity"="cafe"]';
    } else if (type == 'park') {
        queryTag = '["leisure"="park"]';
    } else if (type == 'transit_station') {
        queryTag = '["public_transport"="station"]';
    } else {
        queryTag = '["amenity"="restaurant"]';
    }

    String query = '[out:json][timeout:25];node' + queryTag + '(around:1500,' + lat.toString() + ',' + lng.toString() + ');out body;';
    
    print("Calling Overpass: " + query);

    try {
      var url = Uri.parse(_overpassUrl);
      var response = await http.post(
        url,
        body: query,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'}, 
      );

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        var elements = data['elements'] as List; // casting to list

        List<Place> places = [];
        
        // Looping to create objects
        for (var e in elements) {
            String name = e['tags']['name'] ?? 'Unknown Name';
            if (name != 'Unknown Name') {
                // creating place manually
                var p = Place(
                    name: name,
                    address: _formatAddress(e['tags']),
                );
                places.add(p);
            }
        }
        
        print("Found " + places.length.toString() + " places");
        return places;

      } else {
        print("API Error: " + response.statusCode.toString());
        throw Exception('Overpass API Error');
      }
    } catch (e) {
      print("Crash in overpass: " + e.toString());
      throw Exception('Failed to load places: $e');
    }
  }

  String? _formatAddress(Map<String, dynamic> tags) {
    final street = tags['addr:street'];
    final housenumber = tags['addr:housenumber'];
    final city = tags['addr:city'];
    
    if (street != null) {
      return '${housenumber ?? ''} $street${city != null ? ', $city' : ''}'.trim();
    }
    return null;
  }
}
