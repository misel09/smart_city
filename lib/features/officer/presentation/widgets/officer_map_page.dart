import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../../reports/presentation/providers/complaints_provider.dart';
import '../../../reports/domain/models/complaint.dart';
import '../../../reports/presentation/pages/complaint_details_page.dart';

class OfficerMapPage extends StatefulWidget {
  const OfficerMapPage({super.key});

  @override
  State<OfficerMapPage> createState() => _OfficerMapPageState();
}

class _OfficerMapPageState extends State<OfficerMapPage> {
  final MapController _mapController = MapController();
  ComplaintStatus? _filterStatus;
  
  // Default to a reasonable view (India) until location is determined, 
  // but as an officer, you probably want to see all your complaints.
  LatLng _initialCenter = const LatLng(20.5937, 78.9629); 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060D1F),
      body: Stack(
        children: [
          Consumer<ComplaintsProvider>(
            builder: (context, provider, child) {
              final allComplaints = provider.allComplaints;
              
              // Apply status filter
              final filteredComplaints = _filterStatus == null 
                  ? allComplaints 
                  : allComplaints.where((c) => c.status == _filterStatus).toList();

              // Calculate center if we have complaints
              if (filteredComplaints.isNotEmpty && _initialCenter.latitude == 20.5937) {
                _initialCenter = filteredComplaints.first.location;
              }

              return FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _initialCenter,
                  initialZoom: 12.0,
                  minZoom: 3.0,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                  ),
                ),
                children: [
                   TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.smartcity.app', 
                    tileDisplay: const TileDisplay.fadeIn(),
                  ),
                  MarkerLayer(
                    markers: filteredComplaints.map((c) {
                      return Marker(
                        point: c.location,
                        width: 45,
                        height: 45,
                        child: GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => ComplaintDetailsPage(complaint: c)),
                          ),
                          child: Icon(
                            Icons.location_on_rounded,
                            color: c.statusColor,
                            size: 40,
                            shadows: [
                              Shadow(color: c.statusColor.withOpacity(0.5), blurRadius: 10),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              );
            },
          ),

          // Search Bar Overlay (Visual only or implement if needed)
          Positioned(
            top: 20,
            left: 20,
            right: 80, // Leave room for filters
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A).withOpacity(0.9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  Icon(Icons.search_rounded, color: Colors.white.withOpacity(0.5), size: 18),
                  const SizedBox(width: 12),
                  const Text(
                    'Tracking Tehsil Issues...',
                    style: TextStyle(color: Colors.white38, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),

          // Filters at Top Right
          Positioned(
            top: 20,
            right: 20,
            child: PopupMenuButton<ComplaintStatus?>(
              icon: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF4FC3F7),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4FC3F7).withOpacity(0.3),
                      blurRadius: 15,
                    )
                  ],
                ),
                child: const Icon(Icons.tune_rounded, color: Colors.white, size: 20),
              ),
              color: const Color(0xFF18181B),
              offset: const Offset(0, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
              onSelected: (status) => setState(() => _filterStatus = status),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: null,
                  child: Text('All Issues', style: TextStyle(color: Colors.white)),
                ),
                const PopupMenuDivider(height: 1),
                _buildFilterItem('New Issues', ComplaintStatus.registered, const Color(0xFF4FC3F7)),
                _buildFilterItem('In Progress', ComplaintStatus.inProgress, const Color(0xFFFFB74D)),
                _buildFilterItem('Resolved', ComplaintStatus.resolved, const Color(0xFF81C784)),
                _buildFilterItem('Reviewed', ComplaintStatus.reviewed, const Color(0xFFBA68C8)),
              ],
            ),
          ),

          // My Location Button
          Positioned(
            bottom: 30,
            right: 20,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: const Color(0xFF0F172A),
              onPressed: () {
                // Return to initial center
                _mapController.move(_initialCenter, 12.0);
              },
              child: const Icon(Icons.my_location_rounded, color: Color(0xFF4FC3F7)),
            ),
          ),
        ],
      ),
    );
  }

  PopupMenuItem<ComplaintStatus?> _buildFilterItem(String label, ComplaintStatus status, Color color) {
    return PopupMenuItem(
      value: status,
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
        ],
      ),
    );
  }
}
