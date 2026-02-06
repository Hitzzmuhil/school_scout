import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/school.dart';
import '../../services/supabase_service.dart';

final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  return SupabaseService();
});

// A provider to hold the search results state
final searchResultsProvider = StateNotifierProvider<SearchNotifier, AsyncValue<List<School>>>((ref) {
  return SearchNotifier(ref.watch(supabaseServiceProvider));
});

class SearchNotifier extends StateNotifier<AsyncValue<List<School>>> {
  final SupabaseService _service;

  SearchNotifier(this._service) : super(const AsyncValue.data([]));

  Future<void> searchByName(String query) async {
    if (query.isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }
    
    state = const AsyncValue.loading();
    try {
      final results = await _service.searchSchoolsByName(query);
      state = AsyncValue.data(results);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> searchNearby() async {
    state = const AsyncValue.loading();
    try {
      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      // Get location
      final position = await Geolocator.getCurrentPosition();
      
      // Default radius 5000 meters (5km)
      final results = await _service.getSchoolsNearby(
        position.latitude, 
        position.longitude, 
        5000
      );
      
      state = AsyncValue.data(results);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}
