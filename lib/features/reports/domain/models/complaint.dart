import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

enum ComplaintStatus {
  registered,
  inProgress,
  resolved,
  rejected,
  reviewed,
}

class Complaint {
  final String id;
  final String title;
  final String description;
  final String category;
  final ComplaintStatus status;
  final LatLng location;
  final String address;
  final DateTime timestamp;
  final String? imagePath;
  final String? userEmail;
  final String? userName;
  final String? userMobile;
  final String priority;
  final DateTime? dueDate;
  final String? contractorEmail;
  final String? contractorName;
  final String? contractorMobile;
  final String? afterImagePath;
  final String? afterDescription;
  final String? reviewComment;
  
  // Timeline timestamps
  final DateTime? takenAt;
  final DateTime? resolvedAt;
  final DateTime? reviewedAt;

  Complaint({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.status,
    required this.location,
    required this.address,
    required this.timestamp,
    this.imagePath,
    this.userEmail,
    this.userName,
    this.userMobile,
    this.priority = 'Normal',
    this.dueDate,
    this.contractorEmail,
    this.contractorName,
    this.contractorMobile,
    this.afterImagePath,
    this.afterDescription,
    this.reviewComment,
    this.takenAt,
    this.resolvedAt,
    this.reviewedAt,
  });

  factory Complaint.fromJson(Map<String, dynamic> json) {
    return Complaint(
      id: json['id'].toString(),
      title: json['title'] ?? 'No Title',
      description: json['description'] ?? '',
      category: json['category'] ?? 'General',
      status: _mapStringToStatus(json['status'] ?? 'registered'),
      location: _parseLatLngSafe(json['latitude'], json['longitude']),
      address: json['address'] ?? '',
      timestamp: DateTime.tryParse(json['timestamp']?.toString() ?? '')?.toLocal() ?? DateTime.now(),
      imagePath: json['image_path'],
      userEmail: json['user_email'],
      userName: json['user_name'],
      userMobile: json['user_mobile'],
      priority: json['priority'] ?? 'Normal',
      dueDate: json['due_date'] != null ? DateTime.tryParse(json['due_date'].toString())?.toLocal() : null,
      contractorEmail: json['contractor_email'],
      contractorName: json['contractor_name'],
      contractorMobile: json['contractor_mobile'],
      afterImagePath: json['after_image_path'],
      afterDescription: json['after_description'],
      reviewComment: json['review_comment'],
      takenAt: json['taken_at'] != null ? DateTime.tryParse(json['taken_at'].toString())?.toLocal() : null,
      resolvedAt: json['resolved_at'] != null ? DateTime.tryParse(json['resolved_at'].toString())?.toLocal() : null,
      reviewedAt: json['reviewed_at'] != null ? DateTime.tryParse(json['reviewed_at'].toString())?.toLocal() : null,
    );
  }

  static LatLng _parseLatLngSafe(dynamic lat, dynamic lng) {
    try {
      final double latitude = double.parse(lat.toString());
      final double longitude = double.parse(lng.toString());
      return LatLng(latitude, longitude);
    } catch (e) {
      // Default fallback to 0,0 or a city center if parsing fails
      // This prevents the map from crashing
      return const LatLng(0, 0);
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'status': status.name, // The backend expects string for now
      'latitude': location.latitude,
      'longitude': location.longitude,
      'address': address,
      'image_path': imagePath,
      'timestamp': timestamp.toIso8601String(),
      'user_email': userEmail,
      'user_name': userName,
      'user_mobile': userMobile,
      'priority': priority,
      'due_date': dueDate?.toIso8601String(),
      'contractor_email': contractorEmail,
      'contractor_name': contractorName,
      'contractor_mobile': contractorMobile,
      'after_image_path': afterImagePath,
      'after_description': afterDescription,
      'review_comment': reviewComment,
      'taken_at': takenAt?.toIso8601String(),
      'resolved_at': resolvedAt?.toIso8601String(),
      'reviewed_at': reviewedAt?.toIso8601String(),
    };
  }

  static ComplaintStatus _mapStringToStatus(String status) {
    switch (status.toLowerCase()) {
      case 'registered':
        return ComplaintStatus.registered;
      case 'inprogress':
      case 'in progress':
        return ComplaintStatus.inProgress;
      case 'resolved':
        return ComplaintStatus.resolved;
      case 'rejected':
        return ComplaintStatus.rejected;
      case 'reviewed':
        return ComplaintStatus.reviewed;
      default:
        return ComplaintStatus.registered;
    }
  }

  Color get statusColor {
    switch (status) {
      case ComplaintStatus.registered:
        return Colors.orange;
      case ComplaintStatus.inProgress:
        return Colors.blue;
      case ComplaintStatus.resolved:
        return Colors.green;
      case ComplaintStatus.rejected:
        return Colors.red;
      case ComplaintStatus.reviewed:
        return Colors.teal;
    }
  }

  String get statusText {
    switch (status) {
      case ComplaintStatus.registered:
        return 'Registered';
      case ComplaintStatus.inProgress:
        return 'In Progress';
      case ComplaintStatus.resolved:
        return 'Resolved';
      case ComplaintStatus.rejected:
        return 'Rejected';
      case ComplaintStatus.reviewed:
        return 'Reviewed';
    }
  }
}
