import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../models/school.dart';
import 'search_provider.dart';
import 'school_map.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  bool _isMapView = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchResultsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('School Scout'),
        actions: [
          IconButton(
            icon: Icon(_isMapView ? Icons.list : Icons.map),
            onPressed: () {
              setState(() {
                _isMapView = !_isMapView;
              });
            },
            tooltip: _isMapView ? 'Show List' : 'Show Map',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search schools by name...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(searchResultsProvider.notifier).searchByName("");
                        },
                      ),
                    ),
                    onSubmitted: (value) {
                      ref.read(searchResultsProvider.notifier).searchByName(value);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  onPressed: () {
                     ref.read(searchResultsProvider.notifier).searchNearby();
                     _searchController.clear();
                  },
                  icon: const Icon(Icons.my_location),
                  tooltip: 'Schools Nearby',
                ),
              ],
            ),
          ),
          Expanded(
            child: searchState.when(
              data: (schools) {
                if (schools.isEmpty) {
                  return const Center(
                    child: Text('No schools found. Try searching or using your location.'),
                  );
                }
                
                if (_isMapView) {
                  return SchoolMap(
                    schools: schools,
                    onSchoolSelected: (school) {
                        // context.push('/school/${school.id}');
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Selected: ${school.name}'))
                        );
                    },
                    initialPosition: schools.first.latitude != null 
                        ? LatLng(schools.first.latitude!, schools.first.longitude!)
                        : const LatLng(37.0902, -95.7129),
                  );
                }

                return ListView.builder(
                  itemCount: schools.length,
                  itemBuilder: (context, index) {
                    final school = schools[index];
                    return ListTile(
                      leading: const Icon(Icons.school),
                      title: Text(school.name),
                      subtitle: Text(school.city ?? school.state ?? 'Unknown Location'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        context.push('/school/${school.id}');
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text('Error: $error', style: const TextStyle(color: Colors.red)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
