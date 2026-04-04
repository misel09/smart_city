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
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

class MapViewPage extends StatefulWidget {
  const MapViewPage({super.key});

  @override
  State<MapViewPage> createState() => _MapViewPageState();
}

class _MapViewPageState extends State<MapViewPage> {
  final MapController _mapController = MapController();
  
  String _userRole = '';
  LatLng _latLngCenter = const LatLng(22.57, 72.93); 
  double _currentZoom = 10.5;
  bool _hasMovedToLocation = false;
  String _selectedStatus = 'All'; 
  bool _isFilterExpanded = false;
  double _selectedRadius = 10.0;
  LatLng? _userLocation;

  @override
  void initState() {
    super.initState();
    _fetchUserInfo().then((_) {
      _fetchInitialData();
    });
    _loadCachedLocation();
  }

  Future<void> _fetchInitialData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;

    if (_userRole.toLowerCase().contains('officer')) {
      debugPrint('MapViewPage: Officer detected, fetching all complaints');
      context.read<ComplaintsProvider>().fetchAllComplaints(token).then((_) {
        if (mounted) {
          final count = context.read<ComplaintsProvider>().allComplaints.length;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Viewing $count urban issues'),
              duration: const Duration(seconds: 2),
              backgroundColor: const Color(0xFF0F172A),
            ),
          );
          if (!_hasMovedToLocation) {
             _moveToFirstComplaint();
          }
        }
      });
    } else {
      debugPrint('MapViewPage: Citizen/Contractor detected, fetching nearby');
      _fetchNearbyComplaints();
    }
  }

  void _moveToFirstComplaint() {
    final complaints = context.read<ComplaintsProvider>().allComplaints;
    if (complaints.isNotEmpty) {
      final target = complaints.first.location;
      _mapController.move(target, 12.0);
      setState(() {
        _latLngCenter = target;
        _currentZoom = 12.0;
        _hasMovedToLocation = true;
      });
    }
  }

  Future<void> _loadCachedLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lat = prefs.getDouble('last_lat');
      final lng = prefs.getDouble('last_lng');
      
      if (lat != null && lng != null && mounted) {
        setState(() {
          _latLngCenter = LatLng(lat, lng);
          _currentZoom = 12.0;
        });
        
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) {
            _mapController.move(_latLngCenter, 12.0);
            setState(() => _hasMovedToLocation = true);
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _fetchNearbyComplaints({LatLng? location}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return;

      LatLng currentPos;
      if (location != null) {
        currentPos = location;
      } else {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 5),
        );
        currentPos = LatLng(position.latitude, position.longitude);
        await prefs.setDouble('last_lat', position.latitude);
        await prefs.setDouble('last_lng', position.longitude);
      }

      if (mounted) {
        setState(() {
          _userLocation = currentPos;
          _latLngCenter = currentPos;
          if (!_hasMovedToLocation) {
            _mapController.move(currentPos, 12.0);
            _hasMovedToLocation = true;
          }
        });

        // Trigger fetch asynchronously
        context.read<ComplaintsProvider>().fetchNearbyComplaints(
          token, 
          currentPos.latitude, 
          currentPos.longitude,
          radius: _selectedRadius,
        ).then((_) {
           if (mounted) {
              final bool isOfficer = _userRole.toLowerCase().contains('officer');
              int count;
              if (isOfficer) {
                count = context.read<ComplaintsProvider>().nearbyComplaints.length;
              } else {
                count = context.read<ComplaintsProvider>().nearbyComplaints.where((c) {
                  final status = c.status;
                  return status == ComplaintStatus.registered || 
                         status == ComplaintStatus.inProgress;
                }).length;
              }
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Viewing $count issues within ${_selectedRadius.toInt()}km'),
                  duration: const Duration(seconds: 2),
                  backgroundColor: const Color(0xFF0F172A),
                ),
              );
           }
        });
      }
    } catch (_) {
      if (mounted && !_hasMovedToLocation) {
        _moveToFirstComplaint();
      }
    }
  }

  Future<void> _fetchUserInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedRole = prefs.getString('role');
      if (cachedRole != null && cachedRole.isNotEmpty) {
        if (mounted) {
          setState(() {
            _userRole = cachedRole.toLowerCase().trim();
          });
        }
      }
      
      final token = prefs.getString('token');
      if (token == null) return;

      final res = await http.get(
        Uri.parse(ApiConfig.meUrl),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final fetchedRole = data['role']?.toString().toLowerCase().trim() ?? '';
        await prefs.setString('role', fetchedRole);
        
        if (mounted) {
          setState(() {
            _userRole = fetchedRole;
          });
        }
      }
    } catch (e) {
      debugPrint('MapViewPage: Error in _fetchUserInfo: $e');
    }
  }

  Future<void> _openGoogleMaps(double lat, double lng) async {
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open Google Maps')),
        );
      }
    }
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      final double panStep = 0.01 * (20 / _mapController.camera.zoom);
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
    final bool isOfficer = _userRole.toLowerCase().contains('officer');

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
            MouseRegion(
              cursor: SystemMouseCursors.grab,
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _latLngCenter,
                  initialZoom: _currentZoom,
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
                  if (!isOfficer && _userLocation != null)
                    CircleLayer(
                      circles: [
                        CircleMarker(
                          point: _userLocation!,
                          radius: _selectedRadius * 1000, // Convert km to meters
                          useRadiusInMeter: true,
                          color: AppColors.primary.withOpacity(0.1),
                          borderColor: AppColors.primary.withOpacity(0.3),
                          borderStrokeWidth: 2,
                        ),
                      ],
                    ),
                  if (!isOfficer && _userLocation != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _userLocation!,
                          width: 40,
                          height: 40,
                          alignment: Alignment.center,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.2),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.person_pin_circle,
                                color: AppColors.primary,
                                size: 30,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  Consumer<ComplaintsProvider>(
                    builder: (context, provider, child) {
                      // Determine which complaints to show
                      List<Complaint> sourceComplaints;
                      
                      if (isOfficer) {
                        sourceComplaints = provider.allComplaints;
                      } else {
                        // User and Contractor ONLY see "Registered" and "In Progress" nearby issues
                        sourceComplaints = provider.nearbyComplaints.where((c) {
                          final status = c.status;
                          return status == ComplaintStatus.registered || 
                                 status == ComplaintStatus.inProgress;
                        }).toList();
                      }

                      debugPrint('MapViewPage: Rendering markers. Role: [$_userRole], isOfficer: $isOfficer, Source: ${isOfficer ? "All" : "Nearby (Registered/InProgress)"}, Count: ${sourceComplaints.length}');

                      List<Complaint> filtered = sourceComplaints;
                      
                      // Secondary filter (Status Picker at top right) - Only for Officers
                      if (isOfficer && _selectedStatus != 'All') {
                        filtered = filtered.where((c) => 
                          c.statusText.toLowerCase() == _selectedStatus.toLowerCase()
                        ).toList();
                      }

                      final Map<String, List<Complaint>> grouped = {};
                      for (var complaint in filtered) {
                        final key = '${complaint.location.latitude.toStringAsFixed(3)},${complaint.location.longitude.toStringAsFixed(3)}';
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
            
            // Only show status filters for Officer
            if (isOfficer)
              Positioned(
                top: 50,
                right: 20,
                child: _buildStatusFilters(),
              ),

            if (!isOfficer)
              Positioned(
                bottom: 30,
                left: 20,
                right: 80, // Leave space for center FAB
                child: _buildRadiusSelector(),
              ),
          ],
        ),
      ),
      floatingActionButton: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton(
              heroTag: 'refresh_complaints',
              mini: true,
              backgroundColor: const Color(0xFF0F172A),
              onPressed: () => _fetchInitialData(),
              child: const Icon(Icons.refresh_rounded, color: Color(0xFF4FC3F7)),
            ),
            const SizedBox(height: 8),
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
                _mapController.move(_latLngCenter, 12.0);
              },
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.my_location, color: Colors.white),
            ),
          ],
        ),
    );
  }

  void _showMultipleIssuesList(BuildContext context, List<Complaint> complaints) {
    complaints.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: 450,
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
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
                      Icon(Icons.swipe, size: 20, color: Colors.white.withOpacity(0.6)),
                      const SizedBox(width: 4),
                      Text('Swipe', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
                    ],
                  ),
                ),
            const SizedBox(height: 16),
            Expanded(
              child: PageView.builder(
                controller: PageController(viewportFraction: 0.9),
                itemCount: complaints.length,
                itemBuilder: (context, index) {
                  final complaint = complaints[index];
                  final timeString = DateFormat('MMM d, h:mm a').format(complaint.timestamp);
                  
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
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
                                 style: TextStyle(color: Colors.white38, fontSize: 12),
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
                                   Icon(Icons.access_time, size: 14, color: Colors.white38),
                                   const SizedBox(width: 4),
                                   Text(
                                     timeString,
                                     style: const TextStyle(color: Colors.white38, fontSize: 12),
                                   ),
                                 ],
                               ),
                             ],
                           ),
                         ),
                         const Spacer(),
                         Padding(
                           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                           child: Row(
                             children: [
                               Expanded(
                                 child: ElevatedButton(
                                   onPressed: () async {
                                     if (!context.mounted) return;
                                     Navigator.pop(context);
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
                                   child: const Text('Full Details', style: TextStyle(color: Colors.white, fontSize: 13)),
                                 ),
                               ),
                               const SizedBox(width: 8),
                               Expanded(
                                 child: OutlinedButton.icon(
                                   onPressed: () => _openGoogleMaps(complaint.location.latitude, complaint.location.longitude),
                                   icon: const Icon(Icons.map, size: 16, color: Colors.blue),
                                   label: const Text('Google Map', style: TextStyle(color: Colors.white, fontSize: 13)),
                                   style: OutlinedButton.styleFrom(
                                     side: const BorderSide(color: Colors.blue),
                                     padding: const EdgeInsets.symmetric(vertical: 14),
                                     shape: RoundedRectangleBorder(
                                       borderRadius: BorderRadius.circular(12),
                                     ),
                                   ),
                                 ),
                               ),
                             ],
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

  void _showIssueDetails(BuildContext context, Complaint complaint) {
    final timeString = DateFormat('MMM d, h:mm a').format(complaint.timestamp);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
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
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      if (!context.mounted) return;
                      Navigator.pop(context);
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
                    child: const Text('Full Details', style: TextStyle(color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _openGoogleMaps(complaint.location.latitude, complaint.location.longitude),
                    icon: const Icon(Icons.location_on_outlined, color: Colors.blue),
                    label: const Text('Google Map', style: TextStyle(color: Colors.white)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.blue),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getFilterColor(String filter) {
    switch (filter) {
      case 'Registered':
        return Colors.orange;
      case 'In Progress':
        return Colors.blue;
      case 'Resolved':
        return Colors.green;
      case 'Reviewed':
        return Colors.teal;
      default:
        return Colors.indigoAccent;
    }
  }

  Widget _buildStatusFilters() {
    final filters = ['All', 'Registered', 'In Progress', 'Resolved', 'Reviewed'];

    return GestureDetector(
      onTap: () => setState(() => _isFilterExpanded = !_isFilterExpanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: _isFilterExpanded ? 160 : 110,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.filter_list, color: _getFilterColor(_selectedStatus), size: 18),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    _selectedStatus,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            if (_isFilterExpanded) ...[
              const SizedBox(height: 12),
              ...filters.where((f) => f != _selectedStatus).map((f) => _buildFilterItem(f)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFilterItem(String filter) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedStatus = filter;
          _isFilterExpanded = false;
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(Icons.circle, color: _getFilterColor(filter), size: 10),
            const SizedBox(width: 12),
            Text(
              filter,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRadiusSelector() {
    final radii = [10.0, 25.0, 50.0];
    
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: radii.map((r) {
          final isSelected = _selectedRadius == r;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                if (_selectedRadius != r) {
                  setState(() {
                    _selectedRadius = r;
                  });
                  // Immediately fetch with existing location if available for speed
                  _fetchNearbyComplaints(location: _userLocation);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    '${r.toInt()} km',
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white60,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
