import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/school.dart';
import '../../services/supabase_service.dart';
import '../search/search_provider.dart';
import '../detail/favorites_provider.dart';
import 'package:go_router/go_router.dart';

final favoriteSchoolsProvider = FutureProvider<List<School>>((ref) async {
  final service = ref.watch(supabaseServiceProvider);
  final favoriteIds = ref.watch(favoritesProvider).value ?? [];
  
  if (favoriteIds.isEmpty) {
    return [];
  }
  
  return service.getSchoolsByIds(favoriteIds);
});

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesAsync = ref.watch(favoriteSchoolsProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Favorite Schools'),
      ),
      body: favoritesAsync.when(
        data: (schools) {
          if (schools.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No favorites yet!'),
                  SizedBox(height: 8),
                  Text('Go add some schools to your list.'),
                ],
              ),
            );
          }
          
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: schools.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final school = schools[index];
              return ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.school),
                ),
                title: Text(school.name),
                subtitle: Text(school.city ?? 'Unknown City'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                    context.push('/detail/${school.id}');
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
