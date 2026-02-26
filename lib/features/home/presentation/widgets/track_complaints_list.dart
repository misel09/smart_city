import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../features/reports/presentation/providers/complaints_provider.dart';
import '../../../../features/reports/domain/models/complaint.dart';
import '../../../../features/reports/presentation/pages/complaint_details_page.dart';

class TrackComplaintsList extends StatelessWidget {
  const TrackComplaintsList({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04), // Frosted glass panel effect
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.08), width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Text(
              'TRACK MY COMPLAINTS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Colors.white54,
                letterSpacing: 1.2,
              ),
            ),
          ),
          Consumer<ComplaintsProvider>(
            builder: (context, provider, child) {
              final items = provider.myComplaints;
              
              if (provider.isLoading) {
                return const Padding(
                  padding: EdgeInsets.all(40.0),
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4FC3F7)),
                    ),
                  ),
                );
              }
              
              if (items.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(40.0),
                  child: Center(
                    child: Text("No complaints yet.", 
                      style: TextStyle(color: Colors.white54))),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final Complaint item = items[index];
                  
                  IconData iconData = Icons.report_problem_rounded;
                  if (item.category.contains('Water')) iconData = Icons.water_drop_rounded;
                  if (item.category.contains('Light')) iconData = Icons.lightbulb_rounded;
                  if (item.category.contains('Garbage')) iconData = Icons.delete_outline_rounded;
                  if (item.category.contains('Road') || item.category.contains('Pothole')) iconData = Icons.edit_road_rounded;

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ComplaintDetailsPage(complaint: item),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.07), // Glass card
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.08)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Left Icon
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: item.statusColor.withOpacity(0.15),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: item.statusColor.withOpacity(0.4),
                                width: 1.5,
                              ),
                            ),
                            child: Icon(
                              iconData,
                              color: item.statusColor,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // Status Pill
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: item.statusColor.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    item.statusText,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: item.statusColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Right Icon
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 14,
                              color: Colors.white54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 80), 
        ],
      ),
    );
  }
}
