import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/config/api_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/home_header.dart';
import '../widgets/report_issue_hero.dart';
import '../widgets/nearby_complaints_list.dart';
import '../widgets/track_complaints_list.dart';
import '../../../../features/reports/presentation/providers/complaints_provider.dart';
import 'reviews_page.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../../../../features/notifications/presentation/pages/notifications_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  String _userName = '';
  String _userEmail = '';
  String? _mobileNumber;

  @override
  void initState() {
    super.initState();
    _fetchComplaints();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;

    try {
      final response = await http.get(
        Uri.parse(ApiConfig.meUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 && mounted) {
        final data = jsonDecode(response.body);
        setState(() {
          _userName = data['username'] ?? '';
          _userEmail = data['email'] ?? '';
          _mobileNumber = data['mobile_number'];
        });

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('role', data['role']?.toString().toLowerCase().trim() ?? '');
      }
    } catch (e) {
      print('Error fetching user profile: $e');
    }
  }

  Future<void> _fetchComplaints() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token != null && mounted) {
      final provider = Provider.of<ComplaintsProvider>(context, listen: false);
      provider.fetchComplaints(token);
      _fetchNearbyComplaints(provider, token);
    }
  }

  Future<void> _fetchNearbyComplaints(ComplaintsProvider provider, String token) async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 10),
      );

      provider.fetchNearbyComplaints(token, position.latitude, position.longitude);
    } catch (e) {
      print('Error fetching location for nearby complaints: $e');
    }
  }

  void _onItemTapped(int index) {
    if (index == 0 && _selectedIndex != 0) {
      _fetchUserProfile(); // Reload profile and mobile number when returning to Home
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _selectedIndex == 0
          ? Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF060D1F), Color(0xFF0A2744), Color(0xFF062038)],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
              child: SafeArea(
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      HomeHeader(
                        userName: _userName, 
                        userEmail: _userEmail,
                        onProfileReturned: _fetchUserProfile,
                      ),
                      const SizedBox(height: 10),
                      ReportIssueHero(mobileNumber: _mobileNumber),
                      const SizedBox(height: 24),
                      const NearbyComplaintsList(),
                      const SizedBox(height: 12),
                      const TrackComplaintsList(),
                      const SizedBox(height: 60), // padding for bottom nav
                    ],
                  ),
                ),
              ),
            )
          : (_selectedIndex == 1
              ? const ReviewsPage()
              : (_selectedIndex == 2
                  ? const NotificationsPage(isContractor: false)
                  : (_selectedIndex == 3
                      ? ProfilePage(userName: _userName, userEmail: _userEmail)
                      : Center(child: Text("Page $_selectedIndex Coming Soon"))))),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF060D1F),
          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.08), width: 1)),
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          selectedItemColor: const Color(0xFF4FC3F7),
          unselectedItemColor: Colors.white38,
          currentIndex: _selectedIndex,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          onTap: _onItemTapped,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.rate_review_rounded), label: 'Reviews'),
            BottomNavigationBarItem(icon: Icon(Icons.notifications_rounded), label: 'Alerts'),
            BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}
