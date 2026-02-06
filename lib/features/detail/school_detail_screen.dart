import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../models/school.dart';
import '../../models/school_event.dart';
import '../../services/supabase_service.dart';
import '../search/search_provider.dart'; // accessing supabaseServiceProvider
import 'places_provider.dart';
import 'weather_provider.dart';
import 'events_provider.dart';
import 'favorites_provider.dart';

final schoolDetailProvider = FutureProvider.family<School?, String>((ref, id) async {
  final service = ref.watch(supabaseServiceProvider);
  return service.getSchoolDetails(id);
});

class SchoolDetailScreen extends ConsumerWidget {
  final String schoolId;

  const SchoolDetailScreen({super.key, required this.schoolId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schoolAsync = ref.watch(schoolDetailProvider(schoolId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('School Details'),
        actions: [
          Consumer(
            builder: (context, ref, child) {
              final favoritesAsync = ref.watch(favoritesProvider);
              final isFav = favoritesAsync.value?.contains(schoolId) ?? false;
              
              return IconButton(
                icon: Icon(
                  isFav ? Icons.favorite : Icons.favorite_border,
                  color: isFav ? Colors.red : null,
                ),
                onPressed: () async {
                   print("Toggling favorite for school: " + schoolId);
                   await ref.read(favoritesProvider.notifier).toggleFavorite(schoolId);
                   
                   // Show feedback
                   // I don't know how to check the new state easily so I'll just check if it WAS a favorite and flip it for the message
                   // Actually I can just check the provider value again? No, it might not be updated yet.
                   // Let's assume it worked.
                   ScaffoldMessenger.of(context).showSnackBar(
                     const SnackBar(
                       content: Text('Updated favorites!'),
                       duration: Duration(seconds: 1),
                     ),
                   );
                },
              );
            },
          ),
        ],
      ),
      body: schoolAsync.when(
        data: (school) {
          if (school == null) {
            return const Center(child: Text('School not found'));
          }
          return DefaultTabController(
            length: 5,
            child: Column(
              children: [
                Container(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  padding: const EdgeInsets.all(16),
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        school.name,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        school.city ?? school.state ?? 'Unknown Location',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const TabBar(
                  isScrollable: true,
                  tabs: [
                    Tab(text: 'Info'),
                    Tab(text: 'Map'),
                    Tab(text: 'Nearby'),
                    Tab(text: 'Weather'),
                    Tab(text: 'Calendar'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _InfoTab(school: school),
                      _MapTab(school: school),
                      _NearbyTab(school: school),
                      _WeatherTab(school: school),
                      _CalendarTab(school: school),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

class _InfoTab extends StatelessWidget {
  final School school;
  const _InfoTab({required this.school});

  Future<void> _launchUrl(String? urlString) async {
    if (urlString == null) return;
    final Uri url = Uri.parse(urlString.startsWith('http') ? urlString : 'https://$urlString');
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildInfoRow(context, Icons.location_on, 'Address', school.address),
        _buildInfoRow(context, Icons.phone, 'Phone', school.phone),
        if (school.website != null)
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Website'),
            subtitle: Text(school.website!, style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline)),
            onTap: () => _launchUrl(school.website),
          ),
        const Divider(),
        _buildInfoRow(context, Icons.school, 'Type', school.schoolType),
        _buildInfoRow(context, Icons.grade, 'Grades', school.grades),
        _buildInfoRow(context, Icons.people, 'Enrollment', school.enrollment?.toString()),
        if (school.ncesId != null)
          _buildInfoRow(context, Icons.perm_identity, 'NCES ID', school.ncesId),
      ],
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      subtitle: Text(value),
    );
  }
}

class _MapTab extends StatelessWidget {
  final School school;
  const _MapTab({required this.school});

  @override
  Widget build(BuildContext context) {
    if (school.latitude == null || school.longitude == null) {
      return const Center(child: Text('No location data available'));
    }
    
    final position = LatLng(school.latitude!, school.longitude!);
    
    return FlutterMap(
      options: MapOptions(
        initialCenter: position,
        initialZoom: 15,
      ),
      children: [
         TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.school_scout',
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: position,
              width: 80,
              height: 80,
              child: const Icon(Icons.school, size: 40, color: Colors.red),
            ),
          ],
        ),
      ],
    );
  }
}

class _CalendarTab extends ConsumerWidget {
  final School school;
  const _CalendarTab({required this.school});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(eventsProvider(school.id));

    return eventsAsync.when(
      data: (events) {
        if (events.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_note, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No academic calendar found.'),
              ],
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: events.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final event = events[index];
            return _EventCard(event: event);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error loading events: $err')),
    );
  }
}

class _EventCard extends StatelessWidget {
  final SchoolEvent event;

  const _EventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    // Distinct styles for different event types
    Color cardColor;
    IconData typeIcon;
    Color iconColor;

    switch (event.eventType) {
      case 'term':
        cardColor = Colors.blue.shade50;
        typeIcon = Icons.date_range;
        iconColor = Colors.blue;
        break;
      case 'holiday':
        cardColor = Colors.orange.shade50;
        typeIcon = Icons.beach_access;
        iconColor = Colors.orange;
        break;
      case 'event':
      default:
        cardColor = Colors.white;
        typeIcon = Icons.event;
        iconColor = Theme.of(context).primaryColor;
        break;
    }

    return Card(
      elevation: 0,
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Section
            Container(
              width: 50,
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                children: [
                  Text(
                    DateFormat('MMM').format(event.startTime).toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  Text(
                    DateFormat('d').format(event.startTime),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: iconColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            
            // Content Section
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Row(
                     children: [
                       if (event.eventType != 'event') ...[
                         Icon(typeIcon, size: 16, color: iconColor),
                         const SizedBox(width: 4),
                       ],
                       Expanded(
                         child: Text(
                           event.title,
                           style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                         ),
                       ),
                     ],
                   ),
                   const SizedBox(height: 4),
                   // Time / Duration
                   Text(
                     _formatTime(event),
                     style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                   ),
                   if (event.description != null && event.description!.isNotEmpty) ...[
                     const SizedBox(height: 4),
                     Text(
                       event.description!,
                       style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                       maxLines: 2,
                       overflow: TextOverflow.ellipsis,
                     ),
                   ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(SchoolEvent event) {
    if (event.eventType == 'term' || event.eventType == 'holiday') {
      // Show date range for long events
      if (event.endTime != null) {
        return '${DateFormat.yMMMd().format(event.startTime)} - ${DateFormat.yMMMd().format(event.endTime!)}';
      }
      return DateFormat.yMMMd().format(event.startTime);
    }
    
    if (event.isAllDay) return 'All Day';
    
    final start = DateFormat('h:mm a').format(event.startTime);
    final end = event.endTime != null ? ' - ${DateFormat('h:mm a').format(event.endTime!)}' : '';
    return '$start$end';
  }
}

class _NearbyTab extends ConsumerWidget {
  final School school;
  const _NearbyTab({required this.school});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (school.latitude == null || school.longitude == null) {
      return const Center(child: Text('No location data available for this school.'));
    }

    final currentFilter = ref.watch(placesFilterProvider);
    final placesAsync = ref.watch(nearbyPlacesProvider((lat: school.latitude!, lng: school.longitude!)));

    return Column(
      children: [
        SizedBox(
          height: 60,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              _buildFilterChip(ref, 'library', 'Libraries', currentFilter),
              _buildFilterChip(ref, 'cafe', 'Cafes', currentFilter),
              _buildFilterChip(ref, 'park', 'Parks', currentFilter),
              _buildFilterChip(ref, 'transit_station', 'Transit', currentFilter),
              _buildFilterChip(ref, 'restaurant', 'Restaurants', currentFilter),
            ],
          ),
        ),
        Expanded(
          child: placesAsync.when(
            data: (places) {
              if (places.isEmpty) {
                return const Center(child: Text('No places found nearby.'));
              }
              return ListView.builder(
                itemCount: places.length,
                itemBuilder: (context, index) {
                  final place = places[index];
                  return ListTile(
                    leading: place.icon != null 
                        ? Image.network(place.icon!, width: 24, height: 24, errorBuilder: (_, __, ___) => const Icon(Icons.place)) 
                        : const Icon(Icons.place),
                    title: Text(place.name),
                    subtitle: Text(place.address ?? ''),
                    trailing: place.rating != null ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, size: 16, color: Colors.amber),
                        Text(' ${place.rating}'),
                      ],
                    ) : null,
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('Error loading places: $err. Check Internet connection.'),
            )),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(WidgetRef ref, String type, String label, String currentType) {
    final isSelected = type == currentType;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
             ref.read(placesFilterProvider.notifier).state = type;
          }
        },
      ),
    );
  }
}

class _WeatherTab extends ConsumerWidget {
  final School school;
  const _WeatherTab({required this.school});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (school.latitude == null || school.longitude == null) {
      return const Center(child: Text('No location data available for this school.'));
    }

    final weatherAsync = ref.watch(weatherProvider((lat: school.latitude!, lng: school.longitude!)));

    return weatherAsync.when(
      data: (forecast) {
        return Column(
          children: [
            // Current Weather
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Current Weather', style: Theme.of(context).textTheme.titleMedium),
                      Text(
                        '${forecast.current.temp.round()}°F',
                        style: Theme.of(context).textTheme.displayMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(forecast.current.description, style: Theme.of(context).textTheme.bodyLarge),
                    ],
                  ),
                  if (forecast.current.icon.isNotEmpty)
                    Image.network('https://openweathermap.org/img/wn/${forecast.current.icon}@2x.png'),
                ],
              ),
            ),
            const Divider(),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Align(alignment: Alignment.centerLeft, child: Text('7-Day Forecast', style: TextStyle(fontWeight: FontWeight.bold))),
            ),
            Expanded(
              child: ListView.separated(
                itemCount: forecast.daily.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final day = forecast.daily[index];
                  final date = DateTime.fromMillisecondsSinceEpoch(day.dt * 1000);
                  
                  return ListTile(
                    leading: Text(DateFormat('E, MMM d').format(date)),
                    title: Row(
                      children: [
                        if (day.icon.isNotEmpty)
                          Image.network('https://openweathermap.org/img/wn/${day.icon}.png', width: 32, height: 32),
                        const SizedBox(width: 8),
                        Text(day.description),
                      ],
                    ),
                    trailing: Text('${day.maxTemp.round()}° / ${day.minTemp.round()}°'),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text('Error loading weather: $err'),
      )),
    );
  }
}
