import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../features/reports/presentation/providers/complaints_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../pages/map_view_page.dart';
import '../../../../features/reports/presentation/pages/complaint_details_page.dart';
import '../../../../features/reports/presentation/pages/contractor_complaint_details_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NearbyComplaintsList extends StatelessWidget {
  const NearbyComplaintsList({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MapViewPage()),
          );
        },
        child: Container(
          height: 250,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
            image: const DecorationImage(
              image: NetworkImage('https://tile.openstreetmap.org/15/9643/12321.png'), // Safe static map
              fit: BoxFit.cover,
              opacity: 0.25, // Dimmed for dark mode
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header inside the box
              Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF060D1F).withOpacity(0.85),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.map_rounded, size: 20, color: Color(0xFF4FC3F7)),
                    SizedBox(width: 12),
                    Text(
                      'Nearby Complaints (Map View)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              
              const Spacer(),
              
              // List of cards overlaying the bottom of the map box
              SizedBox(
                height: 140,
                child: Consumer<ComplaintsProvider>(
                  builder: (context, provider, child) {
                    final items = provider.nearbyComplaints;

                    if (provider.isLoading) {
                      return const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4FC3F7)),
                        ),
                      );
                    }
                    
                    if (items.isEmpty) {
                      return Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            "No nearby complaints",
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
                      scrollDirection: Axis.horizontal,
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return GestureDetector(
                          onTap: () async {
                            final prefs = await SharedPreferences.getInstance();
                            final role = prefs.getString('role')?.toLowerCase().trim() ?? '';
                            if (!context.mounted) return;
                            
                            if (role == 'contractor') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => ContractorComplaintDetailsPage(complaint: item)),
                              );
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => ComplaintDetailsPage(complaint: item)),
                              );
                            }
                          },
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
                                   const SizedBox(width: 4),
                                   if (item.priority == 'Urgent' || item.priority == 'High')
                                     Container(
                                       padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                       decoration: BoxDecoration(
                                         color: item.priority == 'Urgent' ? Colors.red.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
                                         borderRadius: BorderRadius.circular(8),
                                         border: Border.all(color: item.priority == 'Urgent' ? Colors.red.withOpacity(0.5) : Colors.orange.withOpacity(0.5)),
                                       ),
                                       child: Text(
                                         item.priority,
                                         style: TextStyle(
                                           fontSize: 9,
                                           fontWeight: FontWeight.bold,
                                           color: item.priority == 'Urgent' ? Colors.red : Colors.orange,
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
            ],
          ),
        ),
      ),
    );
  }
}
