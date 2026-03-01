import 'package:flutter/material.dart';

enum NotificationType {
  login,
  logout,
  newReport,
  taskTaken,
  taskResolved,
  taskReviewed,
  nearbyIssue,
}

class NotificationItem {
  final String id;
  final String title;
  final String description;
  final DateTime timestamp;
  final NotificationType type;
  final IconData icon;
  final Color color;
  final String? associatedComplaintId;

  NotificationItem({
    required this.id,
    required this.title,
    required this.description,
    required this.timestamp,
    required this.type,
    required this.icon,
    required this.color,
    this.associatedComplaintId,
  });
}
