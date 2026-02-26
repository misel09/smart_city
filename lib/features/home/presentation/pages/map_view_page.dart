import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../features/reports/presentation/providers/complaints_provider.dart';
import 'package:intl/intl.dart';
import '../../../../features/reports/domain/models/complaint.dart';
import '../../../../features/reports/presentation/pages/complaint_details_page.dart';
import '../../../../features/reports/presentation/pages/contractor_complaint_details_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../../core/config/api_config.dart';

class MapViewPage extends StatefulWidget {
  const MapViewPage({super.key});

  @override
  State<MapViewPage> createState() => _MapViewPageState();
}

class _MapViewPageState extends State<MapViewPage> {
  final MapController _mapController = MapController();
  
  String _userRole = '';

  @override
  void initState() {
    super.initState();
    _fetchUserInfo();
  }

  Future<void> _fetchUserInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Try to get from prefs first
      final cachedRole = prefs.getString('role');
      if (cachedRole != null && cachedRole.isNotEmpty) {
        if (mounted) setState(() => _userRole = cachedRole.toLowerCase().trim());
      }
      
      final token = prefs.getString('token');
      if (token == null) return;

       // Always verify or fetch from backend just to be safe
      final res = await http.get(
        Uri.parse(ApiConfig.meUrl),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final fetchedRole = data['role']?.toString().toLowerCase().trim() ?? '';
        
        // Save to prefs for future use
        await prefs.setString('role', fetchedRole);
        
        if (mounted) {
          setState(() {
            _userRole = fetchedRole;
          });
        }
      }
    } catch (_) {
      // Ignore errors, role will fallback to user
    }
  }

  // Center of India (Approx)
  final LatLng _center = const LatLng(20.5937, 78.9629);

  // Handle keyboard panning
  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      final double panStep = 0.01 * (20 / _mapController.camera.zoom); // Dynamic step based on zoom
      LatLng currentCenter = _mapController.camera.center;
      
      if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        _mapController.move(LatLng(currentCenter.latitude + panStep, currentCenter.longitude), _mapController.camera.zoom);
      } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        _mapController.move(LatLng(currentCenter.latitude - panStep, currentCenter.longitude), _mapController.camera.zoom);
      } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        _mapController.move(LatLng(currentCenter.latitude, currentCenter.longitude - panStep), _mapController.camera.zoom);
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        _mapController.move(LatLng(currentCenter.latitude, currentCenter.longitude + panStep), _mapController.camera.zoom);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF18181B),
      body: Focus(
        autofocus: true,
        onKeyEvent: (node, event) {
          _handleKeyEvent(event);
          return KeyEventResult.handled;
        },
        child: Stack(
          children: [
            // Map Layer
            MouseRegion(
              cursor: SystemMouseCursors.grab,
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _center,
                  initialZoom: 5.0,
                  minZoom: 3.0,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                    scrollWheelVelocity: 0.015, // Smoother scroll zoom
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.smartcity.app', 
                  ),
                  Consumer<ComplaintsProvider>(
                    builder: (context, provider, child) {
                      // Group complaints by location
                      final Map<String, List<Complaint>> grouped = {};
                      for (var complaint in provider.nearbyComplaints) {
                        final key = '${complaint.location.latitude.toStringAsFixed(4)},${complaint.location.longitude.toStringAsFixed(4)}';
                        if (!grouped.containsKey(key)) {
                          grouped[key] = [];
                        }
                        grouped[key]!.add(complaint);
                      }

                      return MarkerLayer(
                        markers: grouped.entries.map((entry) {
                          final complaints = entry.value;
                          final location = complaints.first.location;
                          
                          return Marker(
                            point: location,
                            width: 50,
                            height: 50,
                            alignment: Alignment.center,
                            child: GestureDetector(
                              onTap: () {
                                if (complaints.length == 1) {
                                  _showIssueDetails(context, complaints.first);
                                } else {
                                  _showMultipleIssuesList(context, complaints);
                                }
                              },
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    color: complaints.first.statusColor,
                                    size: 45,
                                  ),
                                  if (complaints.length > 1)
                                    Positioned(
                                      top: 0,
                                      right: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(5),
                                        decoration: BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white, width: 1.5),
                                        ),
                                        child: Text(
                                          '${complaints.length}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          
          // Back Button
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
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: const Icon(Icons.arrow_back, color: Colors.black),
              ),
            ),
          ),
          
          // Map Type Indicator
          Positioned(
            top: 50,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: const Row(
                children: [
                  Icon(Icons.public, size: 16, color: Colors.blue),
                  SizedBox(width: 8),
                  Text(
                    'India View',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
    floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'zoom_in',
            mini: true,
            backgroundColor: Colors.white,
            onPressed: () {
              final currentZoom = _mapController.camera.zoom;
              _mapController.move(_mapController.camera.center, currentZoom + 1);
            },
            child: const Icon(Icons.add, color: Colors.black),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'zoom_out',
            mini: true,
            backgroundColor: Colors.white,
            onPressed: () {
              final currentZoom = _mapController.camera.zoom;
              _mapController.move(_mapController.camera.center, currentZoom - 1);
            },
            child: const Icon(Icons.remove, color: Colors.black),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'center_location',
            onPressed: () {
              _mapController.move(_center, 5.0);
            },
            backgroundColor: Colors.blue, // Highlight main action
            child: const Icon(Icons.center_focus_strong, color: Colors.white),
          ),
        ],
      ),
    );
  }


  void _showMultipleIssuesList(BuildContext context, List<Complaint> complaints) {
    // Sort by timestamp descending (latest first)
    complaints.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true, // Allow custom height
      builder: (context) => Container(
        height: 450, // Fixed height for swipe view
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A), // Dark Ocean Blue
          border: Border(
            top: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
            child: Column(
              children: [
                const SizedBox(height: 16),
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Text(
                        '${complaints.length} Issues Here',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.swipe, size: 20, color: Colors.white.withOpacity(0.6)), // Indication to swipe
                      const SizedBox(width: 4),
                      Text('Swipe', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
                    ],
                  ),
                ),
            const SizedBox(height: 16),
            Expanded(
              child: PageView.builder(
                controller: PageController(viewportFraction: 0.9), // Show peek of next card
                itemCount: complaints.length,
                itemBuilder: (context, index) {
                  final complaint = complaints[index];
                  final timeString = DateFormat('MMM d, h:mm a').format(complaint.timestamp);
                  
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B), // Slightly lighter ocean blue for cards
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                      boxShadow: [
                         BoxShadow(
                           color: Colors.black.withOpacity(0.3),
                           blurRadius: 10,
                           offset: const Offset(0, 4),
                         )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                         // Status Tag & Close
                         Padding(
                           padding: const EdgeInsets.all(16),
                           child: Row(
                             children: [
                               Container(
                                 padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                 decoration: BoxDecoration(
                                   color: complaint.statusColor.withOpacity(0.1),
                                   borderRadius: BorderRadius.circular(8),
                                 ),
                                 child: Text(
                                   complaint.statusText,
                                   style: TextStyle(
                                     color: complaint.statusColor,
                                     fontSize: 12,
                                     fontWeight: FontWeight.bold,
                                   ),
                                 ),
                               ),
                               const Spacer(),
                               Text(
                                 '${index + 1}/${complaints.length}',
                                 style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
                               ),
                             ],
                           ),
                         ),
                         Divider(height: 1, color: Colors.white.withOpacity(0.1)),
                         Padding(
                           padding: const EdgeInsets.all(16),
                           child: Column(
                             crossAxisAlignment: CrossAxisAlignment.start,
                             children: [
                               Text(
                                 complaint.title,
                                 maxLines: 2,
                                 overflow: TextOverflow.ellipsis,
                                 style: const TextStyle(
                                   fontSize: 18,
                                   fontWeight: FontWeight.bold,
                                   color: Colors.white,
                                 ),
                               ),
                               const SizedBox(height: 8),
                               Text(
                                 complaint.description,
                                 maxLines: 2,
                                 overflow: TextOverflow.ellipsis,
                                 style: const TextStyle(color: Colors.white70, fontSize: 14),
                               ),
                               const SizedBox(height: 12),
                               Row(
                                 children: [
                                   Icon(Icons.access_time, size: 14, color: Colors.white.withOpacity(0.5)),
                                   const SizedBox(width: 4),
                                   Text(
                                     timeString,
                                     style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                                   ),
                                 ],
                               ),
                             ],
                           ),
                         ),
                         const Spacer(),
                         Padding(
                           padding: const EdgeInsets.all(16),
                           child: SizedBox(
                             width: double.infinity,
                             child: ElevatedButton(
                               onPressed: () async {
                                 if (!context.mounted) return;
                                 Navigator.pop(context); // Close sheet
                                 if (_userRole == 'contractor') {
                                   Navigator.push(
                                     context, 
                                     MaterialPageRoute(builder: (_) => ContractorComplaintDetailsPage(complaint: complaint)),
                                   );
                                 } else {
                                   Navigator.push(
                                     context, 
                                     MaterialPageRoute(builder: (_) => ComplaintDetailsPage(complaint: complaint)),
                                   );
                                 }
                               },
                               style: ElevatedButton.styleFrom(
                                 backgroundColor: AppColors.primary,
                                 padding: const EdgeInsets.symmetric(vertical: 14),
                                 shape: RoundedRectangleBorder(
                                   borderRadius: BorderRadius.circular(12),
                                 ),
                               ),
                               child: const Text('View Full Details', style: TextStyle(color: Colors.white)),
                             ),
                           ),
                         ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // Keep existing single issue details
  void _showIssueDetails(BuildContext context, Complaint complaint) {
    final timeString = DateFormat('MMM d, h:mm a').format(complaint.timestamp);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A), // Dark Ocean Blue
          border: Border(
            top: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: complaint.statusColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    complaint.statusText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              complaint.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Reported: $timeString',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (!context.mounted) return;
                  Navigator.pop(context); // Close sheet
                  if (_userRole == 'contractor') {
                    Navigator.push(
                      context, 
                      MaterialPageRoute(builder: (_) => ContractorComplaintDetailsPage(complaint: complaint)),
                    );
                  } else {
                    Navigator.push(
                      context, 
                      MaterialPageRoute(builder: (_) => ComplaintDetailsPage(complaint: complaint)),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('View Full Details', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
