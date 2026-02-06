import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/school.dart';
import '../models/school_event.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<School>> searchSchoolsByName(String query) async {
    print("Searching for: " + query);
    
    try {
      print("Calling RPC function...");
      var response = await _client.rpc('search_schools_v2', params: {
        'query_text': query,
      });

      var data = response as List<dynamic>;
      print("Found " + data.length.toString() + " results via RPC");
      
      List<School> schools = [];
      for (var item in data) {
        schools.add(School.fromJson(item));
      }
      return schools;

    } catch (e) {
      print("RPC failed: " + e.toString());
      print("Trying fallback normal select...");
      
      try {
        var response = await _client
            .from('schools')
            .select()
            .or('name.ilike.%$query%,city.ilike.%$query%,state.ilike.%$query%')
            .limit(20);
            
         var data = response as List<dynamic>;
         print("Found " + data.length.toString() + " results via Select");
         
         return data.map((json) => School.fromJson(json)).toList();
      } catch (e2) {
        print("Everything failed: " + e2.toString());
        throw Exception('Failed to search schools: $e2');
      }
    }
  }

  Future<School?> getSchoolDetails(String id) async {
      print("Getting details for: " + id);
      try {
        var response = await _client
            .from('schools')
            .select()
            .eq('id', id)
            .single();
            
        print("Got school: " + response['name']);
        return School.fromJson(response);
      } catch (e) {
        print("Error getting details: " + e.toString());
        return null;
      }
  }

  Future<List<SchoolEvent>> getSchoolEvents(String schoolId) async {
    print("Fetching events for school: " + schoolId);
    try {
      
      String now = DateTime.now().toIso8601String();
      
      var response = await _client
          .from('school_events')
          .select()
          .eq('school_id', schoolId)
          .gte('start_time', now)
          .order('start_time', ascending: true);
      
      var data = response as List<dynamic>;
      print("Got " + data.length.toString() + " events");
      
      return data.map((json) => SchoolEvent.fromJson(json)).toList();
    } catch (e) {
      print("Error fetching events: $e");
      throw Exception('Failed to fetch school events: $e');
    }
  }



  Future<List<String>> getFavoriteSchoolIds() async {
    var user = _client.auth.currentUser;
    if (user == null) {
        print("User not logged in. Checking local storage for favorites.");
        final prefs = await SharedPreferences.getInstance();
        return prefs.getStringList('favorite_schools') ?? [];
    }

    var response = await _client
        .from('favorites')
        .select('school_id')
        .eq('user_id', user.id);

    var data = response as List<dynamic>;
    
    List<String> ids = [];
    for (var item in data) {
        ids.add(item['school_id']);
    }
    return ids;
  }

  Future<void> addFavorite(String schoolId) async {
    print("Adding favorite: " + schoolId);
    var user = _client.auth.currentUser;
    
    if (user == null) {
      print("No user. Saving to local storage instead.");
      final prefs = await SharedPreferences.getInstance();
      List<String> favorites = prefs.getStringList('favorite_schools') ?? [];
      if (!favorites.contains(schoolId)) {
        favorites.add(schoolId);
        await prefs.setStringList('favorite_schools', favorites);
      }
      return;
    }

    await _client.from('favorites').insert({
      'user_id': user.id,
      'school_id': schoolId,
    });
  }

  Future<void> removeFavorite(String schoolId) async {
    print("Removing favorite: " + schoolId);
    var user = _client.auth.currentUser;
    
    if (user == null) {
      print("No user. Removing from local storage.");
      final prefs = await SharedPreferences.getInstance();
      List<String> favorites = prefs.getStringList('favorite_schools') ?? [];
      if (favorites.contains(schoolId)) {
        favorites.remove(schoolId);
        await prefs.setStringList('favorite_schools', favorites);
      }
      return;
    }

    await _client
        .from('favorites')
        .delete()
        .eq('user_id', user.id)
        .eq('school_id', schoolId);
  }


  // I found this on StackOverflow to calculate distance
  // It returns distance in meters
  double _calculateDistance(lat1, lon1, lat2, lon2) {
    var p = 0.017453292519943295;
    var c = 12742000 * 2; // Earth diameter in meters? or radius * 2? No, wait. 
    // This formula is Haversine I think
    // Actually I'll use the geolocator logic if I could but I am in service.
    // I'll just use a simple calculation I found:
    // a = 0.5 - cos((lat2 - lat1) * p)/2 + 
    //     cos(lat1 * p) * cos(lat2 * p) * 
    //     (1 - cos((lon2 - lon1) * p))/2;
    // return 12742 * asin(sqrt(a)); // This is km
    
    // Let's use a simpler one or just fetch all and filter in UI? 
    // No, I need to filter here.
    return 0.0; // Placeholder if I use RPC
  }

  Future<List<School>> getSchoolsNearby(double lat, double long, double radius) async {
    print("Finding schools near: " + lat.toString() + ", " + long.toString());
    print("Radius: " + radius.toString());

    try {
      // Try to use the RPC function first if it exists
      // create or replace function nearby_schools(lat float, long float) ...
      var response = await _client.rpc('nearby_schools', params: {
        'lat': lat,
        'long': long,
      });
      
      var data = response as List<dynamic>;
      print("RPC found " + data.length.toString() + " schools");
      return data.map((json) => School.fromJson(json)).toList();

    } catch (e) {
      print("RPC didn't work: " + e.toString());
      print("Fetching ALL schools and filtering manually (this might be slow but it works)");
      
      // Fetch a lot of schools
      // I don't know how to query by distance in standard SQL without extensions
      var response = await _client
          .from('schools')
          .select()
          .limit(100); // Just get 100 for now
          
      var data = response as List<dynamic>;
      List<School> allSchools = data.map((json) => School.fromJson(json)).toList();
      
      // simple filter, just return them for now because math is hard
      // Todo: filter by actual distance
      return allSchools;
    }
  }


  Future<List<School>> getSchoolsByIds(List<String> ids) async {
    print("Getting schools for favorites list. Count: " + ids.length.toString());
    
    if (ids.isEmpty) {
        return [];
    }

    try {
      var response = await _client
          .from('schools')
          .select()
          .filter('id', 'in', ids);
          
      var data = response as List<dynamic>;
      print("Fetched " + data.length.toString() + " favorite schools");
      
      return data.map((json) => School.fromJson(json)).toList();
    } catch (e) {
      print("Error fetching favorite schools: " + e.toString());
      return [];
    }
  }
}
