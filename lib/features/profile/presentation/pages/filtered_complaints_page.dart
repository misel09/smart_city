import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../features/reports/presentation/providers/complaints_provider.dart';
import '../../../../features/reports/domain/models/complaint.dart';
import '../../../../features/reports/presentation/pages/complaint_details_page.dart';
import '../../../../features/reports/presentation/pages/contractor_complaint_details_page.dart';

class FilteredComplaintsPage extends StatelessWidget {
  final String title;
  final List<ComplaintStatus>? filterStatuses;
  final String? filterPriority;
  final bool isContractor;

  const FilteredComplaintsPage({
    super.key,
    required this.title,
    this.filterStatuses,
    this.filterPriority,
    required this.isContractor,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060D1F), // Dark theme
      appBar: AppBar(
        title: Text(title,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Consumer<ComplaintsProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF4FC3F7)));
          }

          final sourceList = isContractor ? provider.takenComplaints : provider.myComplaints;
          
          List<Complaint> items = sourceList;
          if (filterStatuses != null && filterStatuses!.isNotEmpty) {
            items = items.where((c) => filterStatuses!.contains(c.status)).toList();
          }

          if (filterPriority != null && filterPriority!.isNotEmpty) {
            // Priority tasks should also exclude resolved and reviewed tasks
            items = items.where((c) => 
                c.priority.toLowerCase() == filterPriority!.toLowerCase() &&
                c.status != ComplaintStatus.resolved &&
                c.status != ComplaintStatus.reviewed).toList();
          }

          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_rounded,
                      size: 80, color: Colors.white.withOpacity(0.2)),
                  const SizedBox(height: 16),
                  Text(
                    'No tasks found',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 18,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
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
                      builder: (context) => isContractor 
                          ? ContractorComplaintDetailsPage(complaint: item)
                          : ComplaintDetailsPage(complaint: item),
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
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
    );
  }
}
