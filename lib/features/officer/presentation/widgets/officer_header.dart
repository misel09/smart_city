import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../auth/login/presentation/pages/login_page.dart';

class OfficerHeader extends StatelessWidget {
  final String userName;
  final String userEmail;

  const OfficerHeader({
    super.key,
    this.userName = '',
    this.userEmail = '',
  });

  String get _initial {
    if (userName.isNotEmpty) return userName[0].toUpperCase();
    if (userEmail.isNotEmpty) return userEmail[0].toUpperCase();
    return 'O';
  }

  void _handleLogout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('role');
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
    final now = DateTime.now();
    final dateString = DateFormat('MMM d, yyyy').format(now);
    final timeString = DateFormat('hh:mm a').format(now);

    final String displayUserName = userName.isNotEmpty ? userName : 'Officer';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome Back,',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  displayUserName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.8,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4FC3F7).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF4FC3F7).withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.verified_user_rounded, color: Color(0xFF4FC3F7), size: 12),
                      const SizedBox(width: 6),
                      const Text(
                        'Municipality Officer',
                        style: TextStyle(
                          color: Color(0xFF4FC3F7),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Profile Avatar with Dropdown
          PopupMenuButton<String>(
            color: const Color(0xFF18181B),
            offset: const Offset(0, 60),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            onSelected: (value) async {
              if (value == 'logout') {
                _handleLogout(context);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: const [
                    Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
                    SizedBox(width: 12),
                    Text('Sign Out', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4FC3F7).withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: CircleAvatar(
                radius: 28,
                backgroundColor: const Color(0xFF1E293B),
                child: Text(
                  _initial,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
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
