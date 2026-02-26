import 'package:flutter/material.dart';


class SocialIconsRow extends StatelessWidget {
  const SocialIconsRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildSocialIcon(Icons.g_mobiledata, Colors.red), // Placeholder for G
        const SizedBox(width: 24),
        _buildSocialIcon(Icons.apple, Colors.black),
        const SizedBox(width: 24),
        _buildSocialIcon(Icons.facebook, Colors.blue),
      ],
    );
  }

  Widget _buildSocialIcon(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(icon, color: color, size: 28),
    );
  }
}
