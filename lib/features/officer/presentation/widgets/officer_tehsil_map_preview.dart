import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../../reports/presentation/providers/complaints_provider.dart';
import '../../../reports/domain/models/complaint.dart';
import '../../../reports/presentation/pages/complaint_details_page.dart';
import '../../../home/presentation/pages/map_view_page.dart';

class OfficerTehsilMapPreview extends StatelessWidget {
  const OfficerTehsilMapPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        height: 300,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
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
            // REAL MAP BACKGROUND
            Consumer<ComplaintsProvider>(
              builder: (context, provider, child) {
                final khedaItems = provider.allComplaints.where((c) => 
                  c.address.toLowerCase().contains('kheda')
                ).toList();

                // If no Kheda items, center on typical Kheda coordinates
                final center = khedaItems.isNotEmpty 
                    ? khedaItems.first.location 
                    : const LatLng(22.75, 72.68); 

                return FlutterMap(
                  options: MapOptions(
                    initialCenter: center,
                    initialZoom: 11.0,
                    interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.smartcity.app',
                      tileDisplay: const TileDisplay.fadeIn(),
                    ),
                    MarkerLayer(
                      markers: khedaItems.map((c) {
                        return Marker(
                          point: c.location,
                          width: 30,
                          height: 30,
                          child: Icon(Icons.location_on_rounded, color: c.statusColor, size: 24),
                        );
                      }).toList(),
                    ),
                  ],
                );
              },
            ),

            // GRADIANT OVERLAY for professional look
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
                    const Icon(Icons.security_rounded, size: 16, color: Color(0xFF4FC3F7)),
                    const SizedBox(width: 8),
                    const Text(
                      'KHEDA JURISDICTION',
                      style: TextStyle(
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

            // EXPAND BUTTON
            Positioned(
              top: 16,
              right: 16,
              child: GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MapViewPage())),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4FC3F7),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: const Color(0xFF4FC3F7).withOpacity(0.3), blurRadius: 10)],
                  ),
                  child: const Icon(Icons.fullscreen_rounded, color: Colors.white, size: 20),
                ),
              ),
            ),
            
            // BOTTOM LIST OF ISSUES
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SizedBox(
                height: 120,
                child: Consumer<ComplaintsProvider>(
                  builder: (context, provider, child) {
                    final khedaItems = provider.allComplaints.where((c) => 
                      c.address.toLowerCase().contains('kheda')
                    ).toList();

                    if (khedaItems.isEmpty) {
                      return Center(
                        child: Text(
                          "No active reports in Kheda Tehsil",
                          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      scrollDirection: Axis.horizontal,
                      itemCount: khedaItems.length,
                      itemBuilder: (context, index) {
                        final item = khedaItems[index];
                        return GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ComplaintDetailsPage(complaint: item))),
                          child: Container(
                            width: 140,
                            margin: const EdgeInsets.only(right: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A).withOpacity(0.95),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withOpacity(0.1)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  item.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                                Row(
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(color: item.statusColor, shape: BoxShape.circle),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(item.statusText, style: TextStyle(color: item.statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
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
    );
  }
}
