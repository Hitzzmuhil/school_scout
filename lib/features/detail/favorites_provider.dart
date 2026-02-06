import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/supabase_service.dart';
import '../search/search_provider.dart';

final favoritesProvider = StateNotifierProvider<FavoritesNotifier, AsyncValue<List<String>>>((ref) {
  return FavoritesNotifier(ref.watch(supabaseServiceProvider));
});

class FavoritesNotifier extends StateNotifier<AsyncValue<List<String>>> {
  final SupabaseService _service;

  FavoritesNotifier(this._service) : super(const AsyncValue.loading()) {
    loadFavorites();
  }

  Future<void> loadFavorites() async {
    try {
      final ids = await _service.getFavoriteSchoolIds();
      state = AsyncValue.data(ids);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> toggleFavorite(String schoolId) async {
    final currentState = state.value;
    if (currentState == null) return;

    try {
      if (currentState.contains(schoolId)) {
        await _service.removeFavorite(schoolId);
        state = AsyncValue.data(currentState.where((id) => id != schoolId).toList());
      } else {
        await _service.addFavorite(schoolId);
        state = AsyncValue.data([...currentState, schoolId]);
      }
    } catch (e) {
      // Revert or show error
      loadFavorites();
    }
  }
  
  bool isFavorite(String schoolId) {
    return state.value?.contains(schoolId) ?? false;
  }
}
