import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/overpass_service.dart';
import '../../models/place.dart';

final placesServiceProvider = Provider<OverpassService>((ref) {
  return OverpassService();
});

final placesFilterProvider = StateProvider.autoDispose<String>((ref) => 'library');

final nearbyPlacesProvider = FutureProvider.autoDispose.family<List<Place>, ({double lat, double lng})>((ref, location) async {
  final service = ref.watch(placesServiceProvider);
  final type = ref.watch(placesFilterProvider);
  
  return service.getNearbyPlaces(location.lat, location.lng, type);
});
