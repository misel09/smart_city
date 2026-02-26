import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/models/complaint.dart';
import '../../../../core/theme/app_colors.dart';

class ComplaintStatusTimeline extends StatelessWidget {
  final Complaint complaint;

  const ComplaintStatusTimeline({
    super.key,
    required this.complaint,
  });

  @override
  Widget build(BuildContext context) {
    // Determine which checkpoints to show and what time they occurred.
    // 1. Reported (Always present)
    final nodes = <_TimelineNodeData>[
      _TimelineNodeData(
        title: 'Reported',
        time: complaint.timestamp,
        isCompleted: true,
        icon: Icons.app_registration_rounded,
        color: Colors.orange,
      ),
    ];

    // 2. Under Review (Taken by contractor)
    if (complaint.takenAt != null ||
        complaint.status == ComplaintStatus.inProgress ||
        complaint.status == ComplaintStatus.resolved ||
        complaint.status == ComplaintStatus.reviewed ||
        complaint.status == ComplaintStatus.rejected) {
      nodes.add(
        _TimelineNodeData(
          title: 'Under Review',
          time: complaint.takenAt,
          isCompleted: complaint.takenAt != null ||
              complaint.status == ComplaintStatus.inProgress ||
              complaint.status == ComplaintStatus.resolved ||
              complaint.status == ComplaintStatus.reviewed,
          icon: Icons.assignment_ind_rounded,
          color: Colors.blue,
        ),
      );
    }

    // 3. Resolved
    if (complaint.resolvedAt != null ||
        complaint.status == ComplaintStatus.resolved ||
        complaint.status == ComplaintStatus.reviewed) {
      nodes.add(
        _TimelineNodeData(
          title: 'Resolved',
          time: complaint.resolvedAt,
          isCompleted: complaint.resolvedAt != null ||
              complaint.status == ComplaintStatus.resolved ||
              complaint.status == ComplaintStatus.reviewed,
          icon: Icons.check_circle_rounded,
          color: Colors.green,
        ),
      );
    }

    // 4. Reviewed (or Rejected)
    if (complaint.reviewedAt != null ||
        complaint.status == ComplaintStatus.reviewed ||
        complaint.status == ComplaintStatus.rejected) {
      final isRejected = complaint.status == ComplaintStatus.rejected;
      nodes.add(
        _TimelineNodeData(
          title: isRejected ? 'Rejected' : 'Reviewed',
          time: complaint.reviewedAt,
          isCompleted: complaint.reviewedAt != null ||
              complaint.status == ComplaintStatus.reviewed ||
              complaint.status == ComplaintStatus.rejected,
          icon: isRejected ? Icons.cancel_rounded : Icons.rate_review_rounded,
          color: isRejected ? Colors.red : Colors.teal,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'STATUS TIMELINE',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Colors.white54,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 20),
          ...List.generate(nodes.length, (index) {
            final node = nodes[index];
            final isLast = index == nodes.length - 1;
            return _TimelineNode(
              data: node,
              isLast: isLast,
            );
          }),
        ],
      ),
    );
  }
}

class _TimelineNodeData {
  final String title;
  final DateTime? time;
  final bool isCompleted;
  final IconData icon;
  final Color color;

  _TimelineNodeData({
    required this.title,
    this.time,
    required this.isCompleted,
    required this.icon,
    required this.color,
  });
}

class _TimelineNode extends StatelessWidget {
  final _TimelineNodeData data;
  final bool isLast;

  const _TimelineNode({
    required this.data,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left side: Timeline indicator
        Column(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: data.isCompleted
                    ? data.color.withOpacity(0.2)
                    : Colors.white.withOpacity(0.05),
                shape: BoxShape.circle,
                border: Border.all(
                  color: data.isCompleted
                      ? data.color
                      : Colors.white.withOpacity(0.1),
                  width: 2,
                ),
              ),
              child: Icon(
                data.icon,
                size: 16,
                color: data.isCompleted ? data.color : Colors.white24,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: data.isCompleted
                    ? data.color.withOpacity(0.5)
                    : Colors.white.withOpacity(0.1),
              ),
          ],
        ),
        const SizedBox(width: 16),
        // Right side: Content
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 6.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: data.isCompleted ? Colors.white : Colors.white54,
                  ),
                ),
                const SizedBox(height: 4),
                if (data.time != null)
                  Text(
                    DateFormat('MMM d, yyyy • h:mm a').format(data.time!),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.5),
                    ),
                  )
                else
                  Text(
                    'Pending',
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: Colors.white.withOpacity(0.3),
                    ),
                  ),
                if (!isLast) const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
