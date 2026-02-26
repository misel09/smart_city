import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math';

import '../../../reports/domain/models/complaint.dart';
import '../providers/complaints_provider.dart';

class TaskResolutionPage extends StatefulWidget {
  final Complaint complaint;

  const TaskResolutionPage({super.key, required this.complaint});

  @override
  State<TaskResolutionPage> createState() => _TaskResolutionPageState();
}

class _TaskResolutionPageState extends State<TaskResolutionPage> {
  final _descriptionController = TextEditingController();
  File? _imageFile;
  bool _isSubmitting = false;
  bool _isLocating = false;
  LatLng? _currentLocation;
  String? _locationError;
  double? _distanceToComplaint;
  
  // Acceptable distance to resolve task (in meters)
  static const double maxAcceptableDistance = 300.0; 

  Future<void> _takePicture() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera, imageQuality: 70);
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLocating = true;
      _locationError = null;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied.');
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied.');
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      final currentLatLng = LatLng(position.latitude, position.longitude);
      
      // Calculate distance using Haversine formula built into Geolocator
      double distanceInMeters = Geolocator.distanceBetween(
        currentLatLng.latitude, currentLatLng.longitude,
        widget.complaint.location.latitude, widget.complaint.location.longitude,
      );

      setState(() {
        _currentLocation = currentLatLng;
        _distanceToComplaint = distanceInMeters;
        _isLocating = false;
      });
      
    } catch (e) {
      setState(() {
        _locationError = e.toString().replaceAll('Exception: ', '');
        _isLocating = false;
      });
    }
  }

  bool _isEligibleToComplete() {
    if (_imageFile == null) return false;
    if (_descriptionController.text.trim().isEmpty) return false;
    if (_distanceToComplaint == null || _distanceToComplaint! > maxAcceptableDistance) return false;
    return true;
  }

  Future<void> _submitResolution() async {
    if (!_isEligibleToComplete() || _isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token == null) {
        throw Exception('Not authenticated. Please log in again.');
      }

      await context.read<ComplaintsProvider>().resolveComplaint(
        widget.complaint.id,
        token,
        _descriptionController.text.trim(),
        _imageFile!.path,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task resolved successfully!'), backgroundColor: Colors.green),
        );
        // Pop back
        Navigator.pop(context, true); // returns true to indicate resolution
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to resolve task: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060D1F),
      appBar: AppBar(
        title: const Text('Resolve Task', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18, color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Task context
            Text('Completing: ${widget.complaint.title}', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            
            // Image Picker
            const Text('Resolution Photo', style: TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _takePicture,
              child: Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: _imageFile != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(_imageFile!, fit: BoxFit.cover),
                      )
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt_outlined, color: Colors.white38, size: 40),
                          SizedBox(height: 8),
                          Text('Tap to take photo', style: TextStyle(color: Colors.white38)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 24),

            // Description
            const Text('Resolution Details', style: TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              style: const TextStyle(color: Colors.white),
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Describe what was done to fix the issue...',
                hintStyle: const TextStyle(color: Colors.white30),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 24),

            // Location Verification
            const Text('Location Verification', style: TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _distanceToComplaint != null && _distanceToComplaint! <= maxAcceptableDistance
                      ? Colors.green.withOpacity(0.5) 
                      : Colors.white.withOpacity(0.1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_currentLocation == null && _locationError == null) 
                    const Text('You must verify you are near the task location.', style: TextStyle(color: Colors.white60, fontSize: 13)),
                  if (_locationError != null)
                    Text(_locationError!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
                  if (_distanceToComplaint != null) ...[
                    Row(
                      children: [
                        Icon(
                          _distanceToComplaint! <= maxAcceptableDistance ? Icons.check_circle_rounded : Icons.cancel_rounded,
                          color: _distanceToComplaint! <= maxAcceptableDistance ? Colors.green : Colors.redAccent,
                          size: 20
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Distance: ${_distanceToComplaint!.toStringAsFixed(0)} meters',
                            style: TextStyle(
                              color: _distanceToComplaint! <= maxAcceptableDistance ? Colors.greenAccent : Colors.white,
                              fontWeight: FontWeight.bold
                            )
                          ),
                        )
                      ],
                    ),
                    if (_distanceToComplaint! > maxAcceptableDistance)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text('You are too far from the reported location to complete this task.', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                        ),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _isLocating ? null : _getCurrentLocation,
                      icon: _isLocating 
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue))
                          : const Icon(Icons.my_location_rounded, size: 18),
                      label: Text(_currentLocation != null ? 'Refresh Location' : 'Fetch Current Location'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.withOpacity(0.2),
                        foregroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                  )
                ],
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isEligibleToComplete() ? _submitResolution : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  disabledBackgroundColor: Colors.white.withOpacity(0.1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: _isEligibleToComplete() ? 4 : 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                    : const Text(
                        'Submit Resolution',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
