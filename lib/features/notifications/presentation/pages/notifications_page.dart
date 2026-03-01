import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../features/reports/presentation/providers/complaints_provider.dart';
import '../../../../features/reports/domain/models/complaint.dart';
import '../../domain/models/notification_item.dart';
import '../../../../features/reports/presentation/pages/complaint_details_page.dart';
import '../../../../features/reports/presentation/pages/contractor_complaint_details_page.dart';

class NotificationsPage extends StatefulWidget {
  final bool isContractor;

  const NotificationsPage({super.key, required this.isContractor});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<NotificationItem> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final List<NotificationItem> items = [];

      // 1. Load Login Logs
      final prefs = await SharedPreferences.getInstance();
      final currentUserEmail = prefs.getString('currentUserEmail') ?? '';
      final userRole = prefs.getString('role') ?? (widget.isContractor ? 'contractor' : 'user');
      
      final loginKey = 'login_history_${currentUserEmail.toLowerCase()}_$userRole';
      final loginLogsString = prefs.getString(loginKey);
      if (loginLogsString != null) {
        final List<dynamic> logs = jsonDecode(loginLogsString);
        for (var timestampStr in logs) {
          items.add(NotificationItem(
            id: 'login_$timestampStr',
            title: 'Logged In Successfully',
            description: 'You securely accessed your account.',
            timestamp: DateTime.parse(timestampStr),
            type: NotificationType.login,
            icon: Icons.login_rounded,
            color: const Color(0xFF4FC3F7),
          ));
        }
      }

      // 1.5 Load Logout Logs
      final logoutKey = 'logout_history_${currentUserEmail.toLowerCase()}_$userRole';
      final logoutLogsString = prefs.getString(logoutKey);
      if (logoutLogsString != null) {
        final List<dynamic> logs = jsonDecode(logoutLogsString);
        for (var timestampStr in logs) {
          items.add(NotificationItem(
            id: 'logout_$timestampStr',
            title: 'Logged Out',
            description: 'You signed out of your account.',
            timestamp: DateTime.parse(timestampStr),
            type: NotificationType.logout,
            icon: Icons.logout_rounded,
            color: Colors.grey.shade400,
          ));
        }
      }

      // 2. Load Complaint Events
      final provider = Provider.of<ComplaintsProvider>(context, listen: false);
      
      if (widget.isContractor) {
        // Contractor Notifications
        
        // Nearby issues (newly registered by others)
        for (var c in provider.nearbyComplaints) {
          if (c.status == ComplaintStatus.registered) {
             items.add(NotificationItem(
              id: 'nearby_${c.id}',
              title: 'New Nearby Issue: ${c.title}',
              description: 'A new issue matching your expertise was reported.',
              timestamp: c.timestamp,
              type: NotificationType.nearbyIssue,
              icon: Icons.location_on_rounded,
              color: Colors.orangeAccent,
              associatedComplaintId: c.id,
            ));
          }
        }
        
        // My taken tasks
        for (var c in provider.takenComplaints) {
           if (c.takenAt != null) {
              items.add(NotificationItem(
                id: 'taken_${c.id}',
                title: 'Task Accepted: ${c.title}',
                description: 'You accepted this task and it is now In Progress.',
                timestamp: c.takenAt!,
                type: NotificationType.taskTaken,
                icon: Icons.assignment_turned_in_rounded,
                color: const Color(0xFF4FC3F7),
                associatedComplaintId: c.id,
              ));
           }
           if (c.resolvedAt != null) {
               items.add(NotificationItem(
                id: 'resolved_${c.id}',
                title: 'Task Resolved: ${c.title}',
                description: 'You marked this task as resolved. Awaiting citizen review.',
                timestamp: c.resolvedAt!,
                type: NotificationType.taskResolved,
                icon: Icons.handyman_rounded,
                color: Colors.orange,
                associatedComplaintId: c.id,
              ));
           }
           if (c.reviewedAt != null) {
              bool isRejected = c.status == ComplaintStatus.rejected;
              items.add(NotificationItem(
                id: 'reviewed_${c.id}',
                title: isRejected ? 'Task Rejected: ${c.title}' : 'Task Approved: ${c.title}',
                description: isRejected ? 'The citizen rejected the work.' : 'The citizen approved the work.',
                timestamp: c.reviewedAt!,
                type: NotificationType.taskReviewed,
                icon: isRejected ? Icons.cancel_rounded : Icons.verified_rounded,
                color: isRejected ? Colors.red : Colors.teal,
                associatedComplaintId: c.id,
              ));
           }
        }

      } else {
        // Citizen Notifications
        for (var c in provider.myComplaints) {
          // Reported
          items.add(NotificationItem(
            id: 'reported_${c.id}',
            title: 'Issue Reported: ${c.title}',
            description: 'Your report was successfully submitted.',
            timestamp: c.timestamp,
            type: NotificationType.newReport,
            icon: Icons.report_problem_rounded,
            color: const Color(0xFF10B981), // Emerald
            associatedComplaintId: c.id,
          ));
          
          if (c.takenAt != null) {
              items.add(NotificationItem(
                id: 'taken_${c.id}',
                title: 'Contractor Assigned: ${c.title}',
                description: '${c.contractorName ?? "A contractor"} has taken your issue.',
                timestamp: c.takenAt!,
                type: NotificationType.taskTaken,
                icon: Icons.sync_rounded,
                color: const Color(0xFF4FC3F7),
                associatedComplaintId: c.id,
              ));
          }
          if (c.resolvedAt != null) {
              items.add(NotificationItem(
                id: 'resolved_${c.id}',
                title: 'Work Completed: ${c.title}',
                description: 'The contractor finished the work. Please review it.',
                timestamp: c.resolvedAt!,
                type: NotificationType.taskResolved,
                icon: Icons.handyman_rounded,
                color: Colors.orange,
                associatedComplaintId: c.id,
              ));
          }
           if (c.reviewedAt != null) {
              bool isRejected = c.status == ComplaintStatus.rejected;
              items.add(NotificationItem(
                id: 'reviewed_${c.id}',
                title: isRejected ? 'Review Submitted: Rejected' : 'Review Submitted: Approved',
                description: isRejected ? 'You rejected the contractor\'s work.' : 'You approved the contractor\'s work.',
                timestamp: c.reviewedAt!,
                type: NotificationType.taskReviewed,
                icon: isRejected ? Icons.cancel_rounded : Icons.verified_rounded,
                color: isRejected ? Colors.red : Colors.teal,
                associatedComplaintId: c.id,
              ));
           }
        }
      }

      // Sort newest first
      items.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      setState(() {
        _notifications = items;
      });

    } catch (e) {
      print('Error loading notifications: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToComplaint(String? complaintId) {
    if (complaintId == null) return;
    
    final provider = Provider.of<ComplaintsProvider>(context, listen: false);
    Complaint? targetComplaint;
    
    if (widget.isContractor) {
       targetComplaint = provider.takenComplaints.where((c) => c.id == complaintId).firstOrNull ?? 
                         provider.nearbyComplaints.where((c) => c.id == complaintId).firstOrNull;
    } else {
       targetComplaint = provider.myComplaints.where((c) => c.id == complaintId).firstOrNull;
    }

    if (targetComplaint != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => widget.isContractor 
              ? ContractorComplaintDetailsPage(complaint: targetComplaint!)
              : ComplaintDetailsPage(complaint: targetComplaint!),
        ),
      ).then((_) {
        // Reload in case status changed
        _loadNotifications();
      });
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inDays > 8) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } else if (difference.inDays >= 1) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours >= 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes >= 1) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF060D1F), Color(0xFF0A2744), Color(0xFF062038)],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: const Icon(
                      Icons.notifications_active_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'Notifications',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Color(0xFF4FC3F7)),
                    )
                  : _notifications.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          color: const Color(0xFF4FC3F7),
                          backgroundColor: const Color(0xFF060D1F),
                          onRefresh: _loadNotifications,
                          child: ListView.builder(
                            padding: const EdgeInsets.only(top: 8, bottom: 80, left: 20, right: 20),
                            itemCount: _notifications.length,
                            itemBuilder: (context, index) {
                              return _buildNotificationCard(_notifications[index]);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(NotificationItem item) {
    final bool isClickable = item.associatedComplaintId != null;

    return GestureDetector(
      onTap: () => _navigateToComplaint(item.associatedComplaintId),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: item.color.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: item.color.withOpacity(0.4),
                  width: 1.5,
                ),
              ),
              child: Icon(
                item.icon,
                color: item.color,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            
            // Text Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatTimeAgo(item.timestamp),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white54,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white70,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            
            // Chevron
            if (isClickable)
              Padding(
                padding: const EdgeInsets.only(left: 12, top: 18),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: Colors.white.withOpacity(0.3),
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
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_off_rounded,
              size: 64,
              color: Colors.white.withOpacity(0.2),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Notifications',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'You\'re all caught up.',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
