import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../features/reports/presentation/providers/complaints_provider.dart';
import '../../../../features/reports/domain/models/complaint.dart';

class StatusCards extends StatelessWidget {
  const StatusCards({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ComplaintsProvider>(
      builder: (context, provider, child) {
        final taken = provider.takenComplaints;
        
        final pending = taken.where((c) => c.status == ComplaintStatus.inProgress).length;
        final priority = taken.where((c) => 
            c.status == ComplaintStatus.inProgress && 
            (c.priority == 'High' || c.priority == 'Urgent')
        ).length;
        final resolved = taken.where((c) => c.status == ComplaintStatus.resolved).length;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            children: [
              _buildPillCard(
                title: 'Pending',
                count: pending.toString().padLeft(1, '0'),
                baseColor: const Color(0xFF29B6F6),
                icon: Icons.pending_actions_rounded,
              ),
              const SizedBox(width: 8),
              _buildPillCard(
                title: 'Priority',
                count: priority.toString().padLeft(1, '0'),
                baseColor: const Color(0xFFEF5350),
                icon: Icons.priority_high_rounded,
              ),
              const SizedBox(width: 8),
              _buildPillCard(
                title: 'Resolved',
                count: resolved.toString().padLeft(1, '0'),
                baseColor: const Color(0xFF66BB6A),
                icon: Icons.check_circle_rounded,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPillCard({
    required String title,
    required String count,
    required Color baseColor,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: baseColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: baseColor.withOpacity(0.3), width: 1.5),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: baseColor, size: 20),
            const SizedBox(height: 6),
            Text(
              count,
              style: TextStyle(
                color: baseColor,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: TextStyle(
                color: baseColor.withOpacity(0.8),
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
