import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../../reports/presentation/providers/complaints_provider.dart';
import '../../../reports/domain/models/complaint.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../reports/presentation/pages/complaint_details_page.dart';
import '../../../home/presentation/pages/map_view_page.dart';

class OfficerDistrictMapPreview extends StatefulWidget {
  const OfficerDistrictMapPreview({super.key});

  @override
  State<OfficerDistrictMapPreview> createState() => _OfficerDistrictMapPreviewState();
}

class _OfficerDistrictMapPreviewState extends State<OfficerDistrictMapPreview> {
  String _districtName = 'DISTRICT';

  @override
  void initState() {
    super.initState();
    _loadDistrict();
  }

  Future<void> _loadDistrict() async {
    final prefs = await SharedPreferences.getInstance();
    final dist = prefs.getString('officerDistrict');
    if (dist != null && dist.isNotEmpty && mounted) {
      setState(() {
        _districtName = dist;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MapViewPage())),
        child: Container(
          height: 320,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
            image: const DecorationImage(
              image: AssetImage('assets/images/map_preview.png'),
              fit: BoxFit.cover,
              opacity: 0.25,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              )
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              // GRADIANT OVERLAY
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF060D1F).withOpacity(0.8),
                      Colors.transparent,
                      const Color(0xFF060D1F).withOpacity(0.9),
                    ],
                    stops: const [0.0, 0.4, 1.0],
                  ),
                ),
              ),

              // HEADER
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B).withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_city_rounded, size: 16, color: Color(0xFF4FC3F7)),
                      const SizedBox(width: 8),
                      Text(
                        '${_districtName.toUpperCase()} DISTRICT WATCH',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // HELP INDICATOR (Optional, but adds to the "clickable" feel)
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.touch_app_rounded, color: Colors.white70, size: 18),
                ),
              ),
            
            // BOTTOM LIST OF ISSUES
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SizedBox(
                height: 140,
                child: Consumer<ComplaintsProvider>(
                  builder: (context, provider, child) {
                    // Since allComplaints is already locally filtered by ComplaintsProvider
                    // based on officerDistrict, we can just use it directly!
                    final itemsToShow = provider.allComplaints;

                    if (itemsToShow.isEmpty) {
                      return Center(
                        child: Text(
                          "No active reports in $_districtName District",
                          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
                      scrollDirection: Axis.horizontal,
                      itemCount: itemsToShow.length,
                      itemBuilder: (context, index) {
                        final item = itemsToShow[index];
                        return GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ComplaintDetailsPage(complaint: item))),
                          child: Container(
                            width: 150,
                            margin: const EdgeInsets.only(right: 12),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0A2744).withOpacity(0.95), // Solid dark blue card
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: Colors.white.withOpacity(0.15)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                   // Marker Icon
                                  Icon(
                                    Icons.location_on_rounded,
                                    color: item.statusColor, 
                                    size: 28,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    item.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      height: 1.2,
                                    ),
                                  ),
                                   // Status and Priority Pills
                                   Row(
                                     children: [
                                       Container(
                                         padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                         decoration: BoxDecoration(
                                           color: item.statusColor.withOpacity(0.2),
                                           borderRadius: BorderRadius.circular(8),
                                           border: Border.all(color: item.statusColor.withOpacity(0.5)),
                                         ),
                                         child: Text(
                                           item.statusText,
                                           style: TextStyle(
                                             fontSize: 9,
                                             fontWeight: FontWeight.bold,
                                             color: item.statusColor,
                                           ),
                                         ),
                                       ),
                                     ],
                                   ),
                                ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }
}
