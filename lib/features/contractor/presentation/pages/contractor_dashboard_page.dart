import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import '../widgets/contractor_header.dart';
import '../widgets/status_cards.dart';
import '../widgets/work_queue_list.dart';
import '../../../home/presentation/widgets/nearby_complaints_list.dart';
import '../../../../features/reports/presentation/providers/complaints_provider.dart';
import '../../../../core/config/api_config.dart';
import 'contractor_profile_page.dart';
import 'contractor_tasks_page.dart';
import '../../../../features/notifications/presentation/pages/notifications_page.dart';
class ContractorDashboardPage extends StatefulWidget {
  const ContractorDashboardPage({super.key});

  @override
  State<ContractorDashboardPage> createState() =>
      _ContractorDashboardPageState();
}

class _ContractorDashboardPageState extends State<ContractorDashboardPage> {
  int _selectedIndex = 0;
  String _userName = '';
  String _userEmail = '';

  @override
  void initState() {
    super.initState();
    _fetchComplaints();
    _fetchUserInfo();
  }

  Future<void> _fetchUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;
    try {
      final res = await http.get(
        Uri.parse(ApiConfig.meUrl),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode == 200 && mounted) {
        final data = jsonDecode(res.body);
        setState(() {
          _userName = data['username'] ?? '';
          _userEmail = data['email'] ?? '';
        });
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('role', data['role']?.toString().toLowerCase().trim() ?? '');
      }
    } catch (_) {}
  }

  Future<void> _fetchComplaints() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token != null && mounted) {
      final provider = Provider.of<ComplaintsProvider>(context, listen: false);
      provider.fetchComplaints(token);
      provider.fetchTakenComplaints(token);
      _fetchNearbyComplaints(provider, token);
    }
  }

  Future<void> _fetchNearbyComplaints(
      ComplaintsProvider provider, String token) async {
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

      provider.fetchNearbyComplaints(
          token, position.latitude, position.longitude);
    } catch (e) {
      debugPrint('Error fetching location for nearby complaints: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          // ── 0: Dashboard ──────────────────────────────────────────────────
          _buildDashboard(),

          // ── 1: Tasks ──────────────────────────────────────────────────────
          const ContractorTasksPage(),

          // ── 2: Notifications ────────────────────────────────────
          const NotificationsPage(isContractor: true),

          // ── 3: Profile ────────────────────────────────────────────────────
          ContractorProfilePage(
            userName: _userName,
            userEmail: _userEmail,
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF060D1F),
          border: Border(
            top: BorderSide(color: Colors.white.withOpacity(0.08), width: 1),
          ),
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          selectedItemColor: const Color(0xFF4FC3F7),
          unselectedItemColor: Colors.white38,
          currentIndex: _selectedIndex,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          onTap: (i) => setState(() => _selectedIndex = i),
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
            BottomNavigationBarItem(
                icon: Icon(Icons.assignment_rounded), label: 'Tasks'),
            BottomNavigationBarItem(
                icon: Icon(Icons.notifications_active_rounded), label: 'Notifications'),
            BottomNavigationBarItem(
                icon: Icon(Icons.person_rounded), label: 'Profile'),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard() {
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
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ContractorHeader(
                userName: _userName,
                userEmail: _userEmail,
                onProfileReturned: _fetchUserInfo,
              ),
              const SizedBox(height: 8),
              const StatusCards(),
              const SizedBox(height: 24),
              const NearbyComplaintsList(),
              const SizedBox(height: 24),

              // ── Work Queue ────────────────────────────────────────────
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                  border: Border(
                    top: BorderSide(
                        color: Colors.white.withOpacity(0.1), width: 1),
                  ),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 24),
                    WorkQueueList(),
                    SizedBox(height: 80),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(IconData icon, String title, String subtitle) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF060D1F), Color(0xFF0A2744), Color(0xFF062038)],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Icon(icon, color: Colors.white38, size: 48),
            ),
            const SizedBox(height: 20),
            Text(title,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(subtitle,
                style: const TextStyle(color: Colors.white38, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
