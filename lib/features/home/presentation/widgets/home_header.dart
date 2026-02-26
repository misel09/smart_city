import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../shared/urban_fix_logo.dart';
import '../../../auth/login/presentation/pages/login_page.dart';
import '../../../profile/presentation/pages/profile_page.dart';

class HomeHeader extends StatelessWidget {
  final String userName;
  final String userEmail;
  final VoidCallback? onProfileReturned;

  const HomeHeader({
    super.key,
    this.userName = '',
    this.userEmail = '',
    this.onProfileReturned,
  });

  String get _initial {
    if (userName.isNotEmpty) return userName[0].toUpperCase();
    if (userEmail.isNotEmpty) return userEmail[0].toUpperCase();
    return '?';
  }

  void _handleLogout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: const UrbanFixLogo(size: 24),
              ),
              const SizedBox(width: 12),
              const Text(
                'UrbanFix',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          PopupMenuButton<String>(
            color: const Color(0xFF18181B), // Dark theme for the dropdown
            offset: const Offset(0, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            onSelected: (value) async {
              if (value == 'profile') {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProfilePage(
                      userName: userName.isNotEmpty ? userName : 'User',
                      userEmail: userEmail,
                    ),
                  ),
                );
                if (onProfileReturned != null) {
                  onProfileReturned!();
                }
              } else if (value == 'logout') {
                _handleLogout(context);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: const [
                    Icon(Icons.person, color: Colors.white, size: 20),
                    SizedBox(width: 12),
                    Text('View Profile', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: const [
                    Icon(Icons.logout, color: Colors.redAccent, size: 20),
                    SizedBox(width: 12),
                    Text('Log Out', style: TextStyle(color: Colors.redAccent)),
                  ],
                ),
              ),
            ],
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF4FC3F7).withOpacity(0.5), width: 2),
              ),
              child: CircleAvatar(
                backgroundColor: const Color(0xFF1565C0),
                radius: 20,
                child: Text(
                  _initial,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
