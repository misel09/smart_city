import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../features/reports/presentation/providers/complaints_provider.dart';
import '../../../../features/reports/presentation/pages/contractor_complaint_details_page.dart';

import '../../../../features/reports/domain/models/complaint.dart';

class WorkQueueList extends StatelessWidget {
  const WorkQueueList({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'WORK QUEUE',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text('See All', style: TextStyle(color: Color(0xFF4FC3F7), fontSize: 13, fontWeight: FontWeight.bold)),
              )
            ],
          ),
          const SizedBox(height: 14),
          Consumer<ComplaintsProvider>(
            builder: (context, provider, child) {
              final items = provider.takenComplaints
                  .where((c) => c.status == ComplaintStatus.inProgress || c.status == ComplaintStatus.rejected)
                  .toList();
              
              if (provider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              
              if (items.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Text('No work available nearby', style: TextStyle(color: Colors.white54)),
                  ),
                );
              }
              
              // Only show first 3 items in this preview list
              final displayItems = items.take(3).toList();
              
                  return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                itemCount: displayItems.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = displayItems[index];
                  return GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ContractorComplaintDetailsPage(complaint: item),
                      ),
                    ),
                    child: _WorkQueueItem(
                      title: item.title,
                      distance: 'Assigned',
                      category: item.category,
                      icon: Icons.assignment_rounded,
                      color: item.statusColor,
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _WorkQueueItem extends StatelessWidget {
  final String title;
  final String distance;
  final String category;
  final IconData icon;
  final Color color;

  const _WorkQueueItem({
    required this.title,
    required this.distance,
    required this.category,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded,
                        color: Colors.white38, size: 12),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(distance,
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 12)),
                    ),
                    const SizedBox(width: 10),
                    Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: Colors.white24,
                          shape: BoxShape.circle,
                        )),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(category,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 12)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

}
