import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../reports/presentation/providers/complaints_provider.dart';
import '../../../reports/domain/models/complaint.dart';
import '../../../reports/presentation/pages/complaint_details_page.dart';
import '../../../../features/notifications/domain/models/notification_item.dart';

class OfficerNotificationsPage extends StatefulWidget {
  const OfficerNotificationsPage({super.key});

  @override
  State<OfficerNotificationsPage> createState() => _OfficerNotificationsPageState();
}

class _OfficerNotificationsPageState extends State<OfficerNotificationsPage> {
  List<NotificationItem> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);

    try {
      final List<NotificationItem> items = [];
      final prefs = await SharedPreferences.getInstance();
      final userEmail = prefs.getString('currentUserEmail') ?? 'officer@smartcity.gov';
      
      // 1. Audit Logs (Removed as requested)

      // 2. Complaint Alerts (All system-wide issues relevant to officer)
      final provider = Provider.of<ComplaintsProvider>(context, listen: false);
      for (var c in provider.allComplaints) {
        // 1. New Registration Alert (Always added for each report)
        items.add(NotificationItem(
          id: 'new_${c.id}',
          title: 'System Alert: New Report',
          description: 'Issue "${c.title}" registered in your tehsil.',
          timestamp: c.timestamp,
          type: NotificationType.newReport,
          icon: Icons.emergency_share_rounded,
          color: Colors.orangeAccent,
          associatedComplaintId: c.id,
        ));
 
        // 2. Task Taken Alert
        if (c.takenAt != null) {
          items.add(NotificationItem(
            id: 'taken_${c.id}',
            title: 'Task Assigned',
            description: 'Issue "${c.title}" has been taken by a contractor.',
            timestamp: c.takenAt!,
            type: NotificationType.taskTaken,
            icon: Icons.assignment_ind_rounded,
            color: const Color(0xFF4FC3F7),
            associatedComplaintId: c.id,
          ));
        }

        // 3. Resolution Alert
        if (c.resolvedAt != null) {
          items.add(NotificationItem(
            id: 'res_${c.id}',
            title: 'Task Resolved: Action Required',
            description: 'Issue "${c.title}" marked as resolved by contractor. Pending review.',
            timestamp: c.resolvedAt!,
            type: NotificationType.taskResolved,
            icon: Icons.check_circle_rounded,
            color: Colors.greenAccent,
            associatedComplaintId: c.id,
          ));
        }
 
        // 4. Reviewed Alert
        if (c.reviewedAt != null) {
          items.add(NotificationItem(
            id: 'rev_${c.id}',
            title: 'Audit Complete: Verified',
            description: 'Issue "${c.title}" has been successfully reviewed and closed.',
            timestamp: c.reviewedAt!,
            type: NotificationType.taskReviewed,
            icon: Icons.verified_user_rounded,
            color: Colors.tealAccent,
            associatedComplaintId: c.id,
          ));
        }
      }

      // Sort newest first
      items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      if (mounted) {
        setState(() {
          _notifications = items.take(30).toList(); // Limit for performance
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060D1F),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4FC3F7).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.notifications_active_rounded, color: Color(0xFF4FC3F7), size: 24),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'System Alerts',
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF4FC3F7)))
                  : _notifications.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: _loadNotifications,
                          color: const Color(0xFF4FC3F7),
                          backgroundColor: const Color(0xFF0F172A),
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            itemCount: _notifications.length,
                            itemBuilder: (context, index) => _buildAlertCard(_notifications[index]),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertCard(NotificationItem item) {
    return GestureDetector(
      onTap: () {
        if (item.associatedComplaintId != null) {
          final c = Provider.of<ComplaintsProvider>(context, listen: false)
              .allComplaints.where((c) => c.id == item.associatedComplaintId).firstOrNull;
          if (c != null) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => ComplaintDetailsPage(complaint: c)));
          }
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: item.color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(item.icon, color: item.color, size: 18),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(item.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                      Text('${item.timestamp.hour}:${item.timestamp.minute}', style: TextStyle(color: Colors.white38, fontSize: 10)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.description,
                    style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none_rounded, color: Colors.white10, size: 64),
          const SizedBox(height: 16),
          const Text('No recent system alerts', style: TextStyle(color: Colors.white24, fontSize: 14)),
        ],
      ),
    );
  }
}
