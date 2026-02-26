import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../features/reports/domain/models/complaint.dart';
import '../../../../features/reports/presentation/providers/complaints_provider.dart';

class ReportIssuePage extends StatefulWidget {
  final File initialImage;
  const ReportIssuePage({super.key, required this.initialImage});

  @override
  State<ReportIssuePage> createState() => _ReportIssuePageState();
}

class _ReportIssuePageState extends State<ReportIssuePage> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedCategory;
  String _selectedPriority = 'Normal';
  DateTime? _selectedDueDate;
  File? _imageFile;
  String? _locationAddress;
  latlong.LatLng? _currentLatLng;
  bool _isLoadingLocation = false;
  bool _isSubmitting = false;
  final TextEditingController _descriptionController = TextEditingController();

  final List<String> _categories = [
    'Damaged concrete structures',
    'Damaged Electrical Poles',
    'Damaged Road Signs',
    'Dead Animals / Pollution',
    'Fallen Trees',
    'Garbage',
    'Graffiti',
    'Illegal Parking',
    'Potholes and Road Cracks',
  ];

  final List<String> _priorities = ['Low', 'Normal', 'High', 'Urgent'];

  final Map<String, Color> _priorityColors = {
    'Low': const Color(0xFF10B981),
    'Normal': const Color(0xFF4FC3F7),
    'High': const Color(0xFFF59E0B),
    'Urgent': const Color(0xFFEF4444),
  };

  @override
  void initState() {
    super.initState();
    _imageFile = widget.initialImage;
    _fetchLocation();
  }

  /// Robust location fetch — no reverse geocoding to avoid errors.
  /// Uses lat/lng directly and shows a human-readable coordinate string.
  Future<void> _fetchLocation() async {
    if (!mounted) return;
    setState(() {
      _isLoadingLocation = true;
      _locationAddress = null;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _setLocationError('Location services are disabled');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _setLocationError('Location permission denied');
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        _setLocationError('Location permission permanently denied');
        return;
      }

      // Try high accuracy first, fall back to low accuracy
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 8),
        );
      } catch (_) {
        try {
          position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.low,
            timeLimit: const Duration(seconds: 5),
          );
        } catch (_) {
          // Last resort: get last known position
          position = await Geolocator.getLastKnownPosition();
        }
      }

      if (position == null) {
        _setLocationError('Could not get location');
        return;
      }

      if (!mounted) return;
      setState(() {
        _currentLatLng = latlong.LatLng(position!.latitude, position.longitude);
        _locationAddress =
            'Lat: ${position.latitude.toStringAsFixed(5)}, Lng: ${position.longitude.toStringAsFixed(5)}';
        _isLoadingLocation = false;
      });

      // Try reverse geocoding in background (optional, non-blocking)
      _tryReverseGeocode(position);
    } catch (e) {
      _setLocationError('Error: ${e.toString().split(':').first}');
    }
  }

  /// Optional background reverse geocoding via Nominatim.
  /// Updates the address display silently — never breaks the main flow.
  Future<void> _tryReverseGeocode(Position position) async {
    try {
      final url = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?format=jsonv2'
          '&lat=${position.latitude}&lon=${position.longitude}');
      final res = await http
          .get(url, headers: {'User-Agent': 'SmartCityApp/1.0'})
          .timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        final displayName = json['display_name'] as String?;
        if (displayName != null && displayName.isNotEmpty && mounted) {
          // Trim to first 2 components for readability
          final parts = displayName.split(',');
          final short = parts
              .take(3)
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .join(', ');
          setState(() => _locationAddress = short);
        }
      }
    } catch (_) {
      // Keep the coordinate string already shown — silent fail
    }
  }

  void _setLocationError(String message) {
    if (!mounted) return;
    setState(() {
      _locationAddress = message;
      _isLoadingLocation = false;
    });
  }

  Future<void> _pickImage() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camera permission is required')),
        );
      }
      return;
    }

    // Fetch location in parallel with camera
    _fetchLocation();

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile == null) return;

    final dir = await getTemporaryDirectory();
    final targetPath =
        '${dir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
    final compressedFile = await FlutterImageCompress.compressAndGetFile(
      pickedFile.path,
      targetPath,
      quality: 70,
      minWidth: 1080,
      minHeight: 1080,
    );

    if (mounted) {
      setState(() {
        _imageFile =
            File(compressedFile?.path ?? pickedFile.path);
      });
    }
  }

  /// Show a custom styled bottom-sheet picker instead of DropdownButtonFormField
  Future<void> _showPicker({
    required String title,
    required List<String> options,
    required String? selected,
    Map<String, Color>? colorMap,
    required ValueChanged<String> onSelect,
  }) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          decoration: BoxDecoration(
            color: const Color(0xFF0D1F3C),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white12, height: 1),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.5,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: options.length,
                  itemBuilder: (_, i) {
                    final opt = options[i];
                    final isSelected = opt == selected;
                    final color = colorMap?[opt] ?? const Color(0xFF4FC3F7);
                    return InkWell(
                      onTap: () {
                        onSelect(opt);
                        Navigator.pop(ctx);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 14),
                        child: Row(
                          children: [
                            if (colorMap != null)
                              Container(
                                width: 10,
                                height: 10,
                                margin: const EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            Expanded(
                              child: Text(
                                opt,
                                style: TextStyle(
                                  color: isSelected
                                      ? const Color(0xFF4FC3F7)
                                      : Colors.white70,
                                  fontSize: 15,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                            if (isSelected)
                              const Icon(Icons.check_circle_rounded,
                                  color: Color(0xFF4FC3F7), size: 20),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  // ------- Build -------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060D1F),
      body: Container(
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
              _buildAppBar(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Image Section ────────────────────────────────
                        _buildImageSection(),
                        const SizedBox(height: 24),

                        // ── Category ─────────────────────────────────────
                        _sectionLabel('Issue Type'),
                        const SizedBox(height: 8),
                        _buildSelectorTile(
                          icon: Icons.category_rounded,
                          label: _selectedCategory ?? 'Select issue type',
                          isEmpty: _selectedCategory == null,
                          accentColor: const Color(0xFF4FC3F7),
                          onTap: () => _showPicker(
                            title: 'Select Issue Type',
                            options: _categories,
                            selected: _selectedCategory,
                            onSelect: (v) =>
                                setState(() => _selectedCategory = v),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // ── Priority ──────────────────────────────────────
                        _sectionLabel('Priority'),
                        const SizedBox(height: 8),
                        _buildPriorityRow(),
                        const SizedBox(height: 16),

                        // ── Due Date ──────────────────────────────────────
                        _sectionLabel('Due Date'),
                        const SizedBox(height: 8),
                        _buildSelectorTile(
                          icon: Icons.calendar_today_rounded,
                          label: _selectedDueDate == null
                              ? 'Select due date (optional)'
                              : '${_selectedDueDate!.day}/${_selectedDueDate!.month}/${_selectedDueDate!.year}',
                          isEmpty: _selectedDueDate == null,
                          accentColor: const Color(0xFF818CF8),
                          onTap: _pickDate,
                        ),
                        const SizedBox(height: 16),

                        // ── Description ──────────────────────────────────
                        _sectionLabel('Description'),
                        const SizedBox(height: 8),
                        _buildDescriptionField(),
                        const SizedBox(height: 16),

                        // ── Location ─────────────────────────────────────
                        _buildLocationCard(),
                        const SizedBox(height: 28),

                        // ── Submit ────────────────────────────────────────
                        _buildSubmitButton(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.09),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: const Icon(Icons.arrow_back_ios_new,
                  color: Colors.white70, size: 18),
            ),
          ),
          const Expanded(
            child: Text(
              'Report New Issue',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildImageSection() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 220,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _imageFile != null
                ? const Color(0xFF4FC3F7).withOpacity(0.4)
                : Colors.white.withOpacity(0.1),
            width: 1.5,
          ),
          image: _imageFile != null
              ? DecorationImage(
                  image: FileImage(_imageFile!),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: _imageFile == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4FC3F7).withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt_rounded,
                        color: Color(0xFF4FC3F7), size: 28),
                  ),
                  const SizedBox(height: 12),
                  const Text('Tap to capture photo',
                      style: TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                          fontSize: 15)),
                  const SizedBox(height: 4),
                  Text('Visual proof of the issue',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.35), fontSize: 12)),
                ],
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(_imageFile!, fit: BoxFit.cover),
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.camera_alt_rounded,
                                color: Colors.white70, size: 14),
                            SizedBox(width: 6),
                            Text('Change',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style: const TextStyle(
          color: Colors.white54,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      );

  Widget _buildSelectorTile({
    required IconData icon,
    required String label,
    required bool isEmpty,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isEmpty
                ? Colors.white.withOpacity(0.1)
                : accentColor.withOpacity(0.4),
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: isEmpty ? Colors.white38 : accentColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isEmpty ? Colors.white38 : Colors.white,
                  fontSize: 15,
                ),
              ),
            ),
            Icon(Icons.keyboard_arrow_down_rounded,
                color: Colors.white38, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityRow() {
    return Row(
      children: _priorities.map((p) {
        final isSelected = _selectedPriority == p;
        final color =
            _priorityColors[p] ?? const Color(0xFF4FC3F7);
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedPriority = p),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.only(right: p == _priorities.last ? 0 : 8),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? color.withOpacity(0.18)
                    : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? color.withOpacity(0.6)
                      : Colors.white.withOpacity(0.08),
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isSelected ? color : Colors.white24,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    p,
                    style: TextStyle(
                      color: isSelected ? color : Colors.white38,
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF4FC3F7),
              onPrimary: Colors.white,
              surface: Color(0xFF0A2744),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (date != null && mounted) {
      setState(() => _selectedDueDate = date);
    }
  }

  Widget _buildDescriptionField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: TextFormField(
        controller: _descriptionController,
        maxLines: 4,
        style: const TextStyle(color: Colors.white, fontSize: 15),
        decoration: InputDecoration(
          hintText: 'Describe the issue in detail...',
          hintStyle:
              TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 15),
          border: InputBorder.none,
          filled: true,
          fillColor: Colors.transparent,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        ),
        validator: (v) =>
            (v == null || v.isEmpty) ? 'Please enter a description' : null,
      ),
    );
  }

  Widget _buildLocationCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: const Color(0xFF4FC3F7).withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.my_location_rounded,
                color: Color(0xFF4FC3F7), size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Current Location',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                if (_isLoadingLocation)
                  Row(
                    children: [
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white.withOpacity(0.4),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('Detecting location...',
                          style:
                              TextStyle(color: Colors.white54, fontSize: 13)),
                    ],
                  )
                else
                  Text(
                    _locationAddress ?? 'Location not detected',
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                  ),
              ],
            ),
          ),
          if (!_isLoadingLocation)
            GestureDetector(
              onTap: _fetchLocation,
              child: Container(
                padding: const EdgeInsets.all(6),
                child: const Icon(Icons.refresh_rounded,
                    color: Color(0xFF4FC3F7), size: 20),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00B4DB), Color(0xFF0083B0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00B4DB).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: _isSubmitting ? null : _submitReport,
        child: _isSubmitting
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: Colors.white))
            : const Text(
                'Submit Report',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an issue type')),
      );
      return;
    }
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please capture a photo of the issue')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final newComplaint = Complaint(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: '$_selectedCategory - Reported Issue',
        description: _descriptionController.text,
        category: _selectedCategory!,
        status: ComplaintStatus.registered,
        priority: _selectedPriority,
        dueDate: _selectedDueDate,
        location: _currentLatLng ??
            const latlong.LatLng(20.5937, 78.9629),
        address: _locationAddress ?? 'Unknown Location',
        timestamp: DateTime.now(),
        imagePath: _imageFile?.path,
      );

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Authentication error. Please login again.')),
          );
        }
        return;
      }

      if (!mounted) return;
      await Provider.of<ComplaintsProvider>(context, listen: false)
          .addComplaint(newComplaint, token);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report submitted successfully!'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
