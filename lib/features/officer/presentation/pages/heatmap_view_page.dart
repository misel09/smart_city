import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../../reports/presentation/providers/complaints_provider.dart';
import '../../../reports/domain/models/complaint.dart';

class HeatmapViewPage extends StatefulWidget {
  final List<Complaint> complaints;
  
  const HeatmapViewPage({super.key, required this.complaints});

  @override
  State<HeatmapViewPage> createState() => _HeatmapViewPageState();
}

class _HeatmapViewPageState extends State<HeatmapViewPage> {
  final MapController _mapController = MapController();

  @override
  Widget build(BuildContext context) {
    // Find center point for the map, default to Anand just in case
    LatLng center = const LatLng(22.57, 72.93);
    if (widget.complaints.isNotEmpty) {
      center = widget.complaints.first.location;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. The Interactive Heatmap
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: center,
              initialZoom: 12.0,
              minZoom: 3.0,
              interactionOptions: const InteractionOptions(
                 flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                 scrollWheelVelocity: 0.015,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.smartcity.app', 
              ),
              MarkerLayer(
                markers: widget.complaints.map((c) {
                  return Marker(
                    point: c.location,
                    width: 80,
                    height: 80,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.15),
                            blurRadius: 40,
                            spreadRadius: 20,
                          )
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          // 2. Back Button
          Positioned(
            top: 50,
            left: 20,
            child: InkWell(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: const Icon(Icons.arrow_back, color: Colors.black),
              ),
            ),
          ),

          // 3. Floating Map Controls (Zoom)
          Positioned(
             bottom: 30,
             right: 20,
             child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FloatingActionButton(
                    heroTag: 'heatmap_zoom_in',
                    mini: true,
                    backgroundColor: Colors.white,
                    onPressed: () {
                      final zoom = _mapController.camera.zoom;
                      _mapController.move(_mapController.camera.center, zoom + 1);
                    },
                    child: const Icon(Icons.add, color: Colors.black),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton(
                    heroTag: 'heatmap_zoom_out',
                    mini: true,
                    backgroundColor: Colors.white,
                    onPressed: () {
                      final zoom = _mapController.camera.zoom;
                      _mapController.move(_mapController.camera.center, zoom - 1);
                    },
                    child: const Icon(Icons.remove, color: Colors.black),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton(
                    heroTag: 'heatmap_center',
                    backgroundColor: const Color(0xFF4FC3F7),
                    onPressed: () {
                      _mapController.move(center, 12.0);
                    },
                    child: const Icon(Icons.my_location, color: Colors.white),
                  ),
                ],
             ),
          )
        ],
      ),
    );
  }
}
