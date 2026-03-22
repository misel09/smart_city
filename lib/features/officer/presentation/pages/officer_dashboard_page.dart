import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/config/api_config.dart';
import '../../../../features/reports/presentation/providers/complaints_provider.dart';
import '../widgets/officer_header.dart';
import '../widgets/officer_status_cards.dart';
import '../widgets/officer_district_map_preview.dart';

class MunicipalityOfficerDashboardPage extends StatefulWidget {
  final bool isTab;
  const MunicipalityOfficerDashboardPage({super.key, this.isTab = false});

  @override
  State<MunicipalityOfficerDashboardPage> createState() => _MunicipalityOfficerDashboardPageState();
}

class _MunicipalityOfficerDashboardPageState extends State<MunicipalityOfficerDashboardPage> {
  String _userName = '';
  String _userEmail = '';

  @override
  void initState() {
    super.initState();
    _fetchUserInfo();
    _fetchComplaints();
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
        
        if (data['district'] != null) {
          prefs.setString('officerDistrict', data['district']);
        }
      }
    } catch (_) {}
  }

  Future<void> _fetchComplaints() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token != null && mounted) {
      Provider.of<ComplaintsProvider>(context, listen: false).fetchAllComplaints(token);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isTab) {
      return _buildContent(context);
    }
    return Scaffold(
      backgroundColor: const Color(0xFF060D1F),
      body: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
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
        child: RefreshIndicator(
          onRefresh: _fetchComplaints,
          color: const Color(0xFF4FC3F7),
          backgroundColor: const Color(0xFF0D1B2A),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OfficerHeader(
                  userName: _userName,
                  userEmail: _userEmail,
                ),
                const SizedBox(height: 16),
                const OfficerStatusCards(),
                const SizedBox(height: 32),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.0),
                  child: Text(
                    'LIVE JURISDICTION',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                OfficerDistrictMapPreview(),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
