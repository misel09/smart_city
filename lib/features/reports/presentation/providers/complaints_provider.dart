import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/config/api_config.dart';
import '../../domain/models/complaint.dart';

class ComplaintsProvider extends ChangeNotifier {
  List<Complaint> _myComplaints = [];
  List<Complaint> _nearbyComplaints = [];
  List<Complaint> _takenComplaints = [];

  List<Complaint> get myComplaints => _myComplaints;
  List<Complaint> get nearbyComplaints => _nearbyComplaints;
  List<Complaint> get takenComplaints => _takenComplaints;
  
  // Keep an alias for backwards compatibility if needed during refactor, though we'll update widgets soon.
  List<Complaint> get complaints => _myComplaints;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> fetchComplaints(String token) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse(ApiConfig.myComplaintsUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _myComplaints = data.map((json) => Complaint.fromJson(json)).toList();
        _myComplaints.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      } else {
        print('Failed to load my complaints: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading my complaints: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchTakenComplaints(String token) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse(ApiConfig.takenComplaintsUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _takenComplaints = data.map((json) => Complaint.fromJson(json)).toList();
        _takenComplaints.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      } else {
        print('Failed to load taken complaints: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading taken complaints: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchNearbyComplaints(String token, double lat, double lng) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.nearbyComplaintsUrl}?lat=$lat&lng=$lng'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _nearbyComplaints = data.map((json) => Complaint.fromJson(json)).toList();
        notifyListeners();
      } else {
        print('Failed to load nearby complaints: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading nearby complaints: $e');
    }
  }

  Future<void> addComplaint(Complaint complaint, String token) async {
    _myComplaints.insert(0, complaint);
    // Optimistically add to nearby complaints since the user is presumably at that location
    _nearbyComplaints.insert(0, complaint);
    notifyListeners();

    try {
      var request = http.MultipartRequest('POST', Uri.parse('${ApiConfig.complaintsUrl}/'));
      request.headers['Authorization'] = 'Bearer $token';
      
      request.fields['title'] = complaint.title;
      request.fields['description'] = complaint.description;
      request.fields['category'] = complaint.category;
      request.fields['latitude'] = complaint.location.latitude.toString();
      request.fields['longitude'] = complaint.location.longitude.toString();
      request.fields['address'] = complaint.address;
      request.fields['priority'] = complaint.priority;
      if (complaint.dueDate != null) {
        request.fields['due_date'] = complaint.dueDate!.toIso8601String();
      }
      
      if (complaint.imagePath != null && complaint.imagePath!.isNotEmpty) {
        request.files.add(await http.MultipartFile.fromPath('image', complaint.imagePath!));
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final newComplaint = Complaint.fromJson(json.decode(response.body));
        _myComplaints[0] = newComplaint;
        _myComplaints.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        _nearbyComplaints[0] = newComplaint;
      } else {
        _myComplaints.removeAt(0);
        _nearbyComplaints.removeAt(0);
        print('Failed to add complaint: ${response.statusCode}, ${response.body}');
      }
    } catch (e) {
       _myComplaints.removeAt(0);
       _nearbyComplaints.removeAt(0);
      print('Error adding complaint: $e');
    }
    notifyListeners();
  }

  Future<void> deleteComplaint(String id, String token) async {
    final index = _myComplaints.indexWhere((c) => c.id == id);
    if (index == -1) return;

    final deletedComplaint = _myComplaints[index];
    _myComplaints.removeAt(index);
    
    // Also remove from nearby if present
    _nearbyComplaints.removeWhere((c) => c.id == id);
    
    notifyListeners();

    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.complaintsUrl}/$id'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 404) {
         return;
      }

      if (response.statusCode != 204 && response.statusCode != 200) {
        _myComplaints.insert(index, deletedComplaint);
        notifyListeners();
        throw Exception('Failed to delete complaint: ${response.statusCode}');
      }
    } catch (e) {
      _myComplaints.insert(index, deletedComplaint);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> takeComplaint(String complaintId, String token) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.complaintsUrl}/$complaintId/take'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final updatedComplaint = Complaint.fromJson(json.decode(response.body));
        
        // Update in my complaints if it's there
        final myIndex = _myComplaints.indexWhere((c) => c.id == complaintId);
        if (myIndex != -1) {
          _myComplaints[myIndex] = updatedComplaint;
        }

        // Update in nearby complaints if it's there
        final nearbyIndex = _nearbyComplaints.indexWhere((c) => c.id == complaintId);
        if (nearbyIndex != -1) {
          _nearbyComplaints[nearbyIndex] = updatedComplaint;
        }

        // Add to taken complaints
        final takenIndex = _takenComplaints.indexWhere((c) => c.id == complaintId);
        if (takenIndex != -1) {
          _takenComplaints[takenIndex] = updatedComplaint;
        } else {
          _takenComplaints.insert(0, updatedComplaint);
        }

        notifyListeners();
      } else {
        throw Exception('Failed to take complaint: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error taking complaint: $e');
    }
  }

  Future<void> resolveComplaint(String complaintId, String token, String description, String imagePath) async {
    try {
      var request = http.MultipartRequest('PUT', Uri.parse('${ApiConfig.complaintsUrl}/$complaintId/resolve'));
      request.headers['Authorization'] = 'Bearer $token';

      request.fields['description'] = description;

      if (imagePath.isNotEmpty) {
        request.files.add(await http.MultipartFile.fromPath('image', imagePath));
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final updatedComplaint = Complaint.fromJson(json.decode(response.body));
        
        // Update in my complaints if it's there
        final myIndex = _myComplaints.indexWhere((c) => c.id == complaintId);
        if (myIndex != -1) {
          _myComplaints[myIndex] = updatedComplaint;
        }

        // Update in nearby complaints if it's there
        final nearbyIndex = _nearbyComplaints.indexWhere((c) => c.id == complaintId);
        if (nearbyIndex != -1) {
          _nearbyComplaints[nearbyIndex] = updatedComplaint;
        }

        // Update in taken complaints if it's there
        final takenIndex = _takenComplaints.indexWhere((c) => c.id == complaintId);
        if (takenIndex != -1) {
          _takenComplaints[takenIndex] = updatedComplaint;
        }

        notifyListeners();
      } else {
        throw Exception('Failed to resolve complaint: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error resolving complaint: $e');
    }
  }

  Future<void> reviewComplaint(String complaintId, String token, String status, {String? comment}) async {
    try {
      var request = http.MultipartRequest('PUT', Uri.parse('${ApiConfig.complaintsUrl}/$complaintId/review'));
      request.headers['Authorization'] = 'Bearer $token';

      request.fields['status'] = status;
      if (comment != null && comment.isNotEmpty) {
        request.fields['comment'] = comment;
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final updatedComplaint = Complaint.fromJson(json.decode(response.body));
        
        // Update in my complaints if it's there
        final myIndex = _myComplaints.indexWhere((c) => c.id == complaintId);
        if (myIndex != -1) {
          _myComplaints[myIndex] = updatedComplaint;
        }

        // Update in nearby complaints if it's there
        final nearbyIndex = _nearbyComplaints.indexWhere((c) => c.id == complaintId);
        if (nearbyIndex != -1) {
          _nearbyComplaints[nearbyIndex] = updatedComplaint;
        }

        // Update in taken complaints if it's there
        final takenIndex = _takenComplaints.indexWhere((c) => c.id == complaintId);
        if (takenIndex != -1) {
          _takenComplaints[takenIndex] = updatedComplaint;
        }

        notifyListeners();
      } else {
        throw Exception('Failed to review complaint: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error reviewing complaint: $e');
    }
  }
}
