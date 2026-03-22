import 'package:flutter/material.dart';
import 'officer_dashboard_page.dart';
import 'officer_analytics_tab.dart';
import '../widgets/officer_map_page.dart';
import '../widgets/all_complaints_list.dart';
import 'officer_notifications_page.dart';

class MunicipalityOfficerMainPage extends StatefulWidget {
  const MunicipalityOfficerMainPage({super.key});

  @override
  State<MunicipalityOfficerMainPage> createState() => _MunicipalityOfficerMainPageState();
}

class _MunicipalityOfficerMainPageState extends State<MunicipalityOfficerMainPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const MunicipalityOfficerDashboardPage(isTab: true),
    const OfficerAnalyticsTab(),
    Scaffold(
      backgroundColor: const Color(0xFF060D1F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF060D1F),
        elevation: 0,
        title: const Text(
          'Urban Reports',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: false,
      ),
      body: const SafeArea(
        child: SingleChildScrollView(
          child: AllComplaintsList(),
        ),
      ),
    ),
    const OfficerNotificationsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF060D1F),
          border: Border(
            top: BorderSide(color: Colors.white.withOpacity(0.05), width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFF4FC3F7),
          unselectedItemColor: Colors.white.withOpacity(0.3),
          selectedLabelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_customize_rounded, size: 22),
              activeIcon: Icon(Icons.dashboard_customize_rounded, size: 24),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.analytics_outlined, size: 22),
              activeIcon: Icon(Icons.analytics_rounded, size: 24),
              label: 'Analytics',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.description_rounded, size: 22),
              activeIcon: Icon(Icons.description_rounded, size: 24),
              label: 'Issues',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.notifications_active_rounded, size: 22),
              activeIcon: Icon(Icons.notifications_active_rounded, size: 24),
              label: 'Alerts',
            ),
          ],
        ),
      ),
    );
  }
}
