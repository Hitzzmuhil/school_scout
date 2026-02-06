import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/school.dart';
import '../models/school_event.dart';

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
        print("User not logged in");
        return [];
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
    if (user == null) throw Exception('User not logged in');

    await _client.from('favorites').insert({
      'user_id': user.id,
      'school_id': schoolId,
    });
  }

  Future<void> removeFavorite(String schoolId) async {
    print("Removing favorite: " + schoolId);
    var user = _client.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    await _client
        .from('favorites')
        .delete()
        .eq('user_id', user.id)
        .eq('school_id', schoolId);
  }
}
