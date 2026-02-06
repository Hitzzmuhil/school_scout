import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../models/school.dart';

class SchoolMap extends StatefulWidget {
  final List<School> schools;
  final Function(School) onSchoolSelected;
  final LatLng initialPosition;

  const SchoolMap({
    super.key,
    required this.schools,
    required this.onSchoolSelected,
    required this.initialPosition,
  });

  @override
  State<SchoolMap> createState() => _SchoolMapState();
}

class _SchoolMapState extends State<SchoolMap> {
  final MapController _mapController = MapController();

  @override
  void didUpdateWidget(covariant SchoolMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialPosition != oldWidget.initialPosition) {
       _mapController.move(widget.initialPosition, 13);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: widget.initialPosition,
        initialZoom: 13.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.school_scout',
        ),
        MarkerLayer(
          markers: widget.schools.map((school) {
            if (school.latitude == null || school.longitude == null) {
               return null;
            }
            return Marker(
              point: LatLng(school.latitude!, school.longitude!),
              width: 80,
              height: 80,
              child: GestureDetector(
                onTap: () => widget.onSchoolSelected(school),
                child: const Icon(Icons.school, color: Colors.red, size: 40),
              ),
            );
          }).whereType<Marker>().toList(),
        ),
      ],
    );
  }
}
