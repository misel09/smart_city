import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';

class PasswordStrengthIndicator extends StatelessWidget {
  final String password;

  const PasswordStrengthIndicator({super.key, required this.password});

  @override
  Widget build(BuildContext context) {
    int strength = _calculateStrength(password);

    return Row(
      children: [
        ...List.generate(5, (index) {
          return Expanded(
            child: Container(
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: index < strength ? AppColors.success : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
        const SizedBox(width: 12),
        Text(
          _getStrengthText(strength),
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  int _calculateStrength(String password) {
    if (password.isEmpty) return 0;
    int score = 0;
    if (password.length > 6) score++;
    if (password.length > 8) score++;
    if (password.contains(RegExp(r'[A-Z]'))) score++;
    if (password.contains(RegExp(r'[0-9]'))) score++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>Ĩ]'))) score++;
    return score; // Max 5
  }

  String _getStrengthText(int strength) {
    if (strength == 0) return '';
    if (strength <= 2) return 'Weak';
    if (strength <= 4) return 'Good';
    return 'Strong';
  }
}
