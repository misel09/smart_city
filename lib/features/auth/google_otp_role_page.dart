import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_city/core/config/api_config.dart';
import 'package:smart_city/features/home/presentation/pages/home_page.dart';
import 'package:smart_city/features/contractor/presentation/pages/contractor_dashboard_page.dart';

class GoogleOtpRolePage extends StatefulWidget {
  final String email;
  final String name;
  final String googleId;

  /// If true: email already known — skip OTP, just pick role
  final bool skipOtp;

  const GoogleOtpRolePage({
    super.key,
    required this.email,
    required this.name,
    required this.googleId,
    this.skipOtp = false,
  });

  @override
  State<GoogleOtpRolePage> createState() => _GoogleOtpRolePageState();
}

class _GoogleOtpRolePageState extends State<GoogleOtpRolePage>
    with SingleTickerProviderStateMixin {
  final _otpController = TextEditingController();
  String? _selectedRole;          // 'user' or 'contractor'
  String? _selectedContractorType;
  bool _isLoading = false;
  bool _resending = false;
  bool _otpVerified = false;      // for new users: once OTP step done, show role picker

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  final List<String> _contractorTypes = [
    'Civil / Structural Repair Contractor',
    'Electrical Contractor',
    'Traffic Management & Road Safety Contractor',
    'Municipal Sanitation & Waste Management Contractor',
    'Animal Control Services Contractor',
    'Tree Removal / Arborist Contractor',
    'Urban Surface Cleaning & Maintenance Contractor',
    'Traffic Enforcement Authority',
    'Road Construction'
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _animController.forward();
  }

  @override
  void dispose() {
    _otpController.dispose();
    _animController.dispose();
    super.dispose();
  }

  // ─── Resend OTP ─────────────────────────────────────────────────────────────
  Future<void> _resendOtp() async {
    setState(() => _resending = true);
    try {
      final res = await http.post(
        Uri.parse(ApiConfig.googleSendOtpUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': widget.email,
          'name': widget.name,
          'google_id': widget.googleId,
        }),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(res.statusCode == 200
              ? 'New code sent to ${widget.email}'
              : jsonDecode(res.body)['detail'] ?? 'Failed to resend'),
          backgroundColor: res.statusCode == 200 ? Colors.green : Colors.red,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  // ─── Confirm ────────────────────────────────────────────────────────────────
  Future<void> _confirm() async {
    if (_selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a role'), backgroundColor: Colors.orange),
      );
      return;
    }
    if (_selectedRole == 'contractor' && _selectedContractorType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select contractor type'), backgroundColor: Colors.orange),
      );
      return;
    }

    final otp = _otpController.text.trim();
    if (!widget.skipOtp && otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the 6-digit code'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final http.Response res;

      if (widget.skipOtp) {
        // Email already verified — just find/create with chosen role
        res = await http.post(
          Uri.parse(ApiConfig.googleSelectRoleUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': widget.email,
            'name': widget.name,
            'google_id': widget.googleId,
            'role': _selectedRole,
            'contractor_type': _selectedContractorType,
          }),
        );
      } else {
        // New email — verify OTP and create account
        res = await http.post(
          Uri.parse(ApiConfig.googleVerifyOtpUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': widget.email,
            'name': widget.name,
            'google_id': widget.googleId,
            'otp': otp,
            'role': _selectedRole,
            'contractor_type': _selectedContractorType,
          }),
        );
      }

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final token = body['access_token'];
        final role = body['role'] ?? _selectedRole;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);

        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => role == 'contractor'
                  ? const ContractorDashboardPage()
                  : const HomePage(),
            ),
            (route) => false,
          );
        }
      } else {
        final error = jsonDecode(res.body)['detail'] ?? 'Verification failed';
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─── Role card widget ────────────────────────────────────────────────────────
  Widget _roleCard({
    required String role,
    required String label,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _selectedRole == role;
    return GestureDetector(
      onTap: () => setState(() {
        _selectedRole = role;
        _selectedContractorType = null;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(colors: [color.withOpacity(0.35), color.withOpacity(0.15)])
              : null,
          color: isSelected ? null : Colors.white.withOpacity(0.07),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.white.withOpacity(0.15),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 4))]
              : null,
        ),
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isSelected ? color.withOpacity(0.2) : Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: isSelected ? color : Colors.white54, size: 28),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      )),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: const TextStyle(color: Colors.white54, fontSize: 13)),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: color, size: 24),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF060D1F), Color(0xFF0A2744), Color(0xFF062038)],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: CustomScrollView(
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Back button ──────────────────────────────────
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.arrow_back_ios_new,
                                color: Colors.white70, size: 18),
                          ),
                        ),
                        const SizedBox(height: 36),

                        // ── Header ──────────────────────────────────────
                        Text(
                          widget.skipOtp ? 'Choose Your Role' : 'Verify & Choose Role',
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.skipOtp
                              ? 'Hi ${widget.name}! Select how you want to sign in.'
                              : 'Check ${widget.email} for your verification code.',
                          style: const TextStyle(
                              fontSize: 15, color: Colors.white60, height: 1.5),
                        ),

                        const SizedBox(height: 36),

                        // ── OTP field (new users only) ───────────────────
                        if (!widget.skipOtp) ...[
                          const Text('Verification Code',
                              style: TextStyle(
                                  color: Colors.white60,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1)),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _otpController,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 34,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 18,
                            ),
                            decoration: InputDecoration(
                              counterText: '',
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.07),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide(
                                    color: Colors.white.withOpacity(0.15)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide(
                                    color: Colors.white.withOpacity(0.15)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: const BorderSide(
                                    color: Color(0xFF4FC3F7), width: 2),
                              ),
                              hintText: '_ _ _ _ _ _',
                              hintStyle: TextStyle(
                                color: Colors.white.withOpacity(0.15),
                                fontSize: 28,
                                letterSpacing: 14,
                              ),
                              contentPadding: const EdgeInsets.symmetric(vertical: 20),
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _resending ? null : _resendOtp,
                              child: Text(
                                _resending ? 'Sending...' : 'Resend Code',
                                style: const TextStyle(
                                    color: Color(0xFF4FC3F7), fontSize: 13),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // ── Role label ───────────────────────────────────
                        const Text('SELECT ROLE',
                            style: TextStyle(
                                color: Colors.white60,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1)),
                        const SizedBox(height: 12),

                        // ── User card ────────────────────────────────────
                        _roleCard(
                          role: 'user',
                          label: 'user',
                          subtitle: 'Report issues & track complaints',
                          icon: Icons.person_rounded,
                          color: const Color(0xFF4FC3F7),
                        ),
                        const SizedBox(height: 14),

                        // ── Contractor card ──────────────────────────────
                        _roleCard(
                          role: 'contractor',
                          label: 'Contractor',
                          subtitle: 'Manage and resolve assigned tasks',
                          icon: Icons.engineering_rounded,
                          color: const Color(0xFF66BB6A),
                        ),

                        // ── Contractor type (new users only) ─────────────
                        if (_selectedRole == 'contractor') ...[
                          const SizedBox(height: 20),
                          const Text('CONTRACTOR TYPE',
                              style: TextStyle(
                                  color: Colors.white60,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1)),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: _contractorTypes.map((type) {
                              final selected = _selectedContractorType == type;
                              return GestureDetector(
                                onTap: () =>
                                    setState(() => _selectedContractorType = type),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 18, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? const Color(0xFF66BB6A).withOpacity(0.2)
                                        : Colors.white.withOpacity(0.07),
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: selected
                                          ? const Color(0xFF66BB6A)
                                          : Colors.white.withOpacity(0.15),
                                      width: selected ? 2 : 1,
                                    ),
                                  ),
                                  child: Text(type,
                                      style: TextStyle(
                                        color: selected
                                            ? const Color(0xFF66BB6A)
                                            : Colors.white60,
                                        fontWeight: selected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      )),
                                ),
                              );
                            }).toList(),
                          ),
                        ],

                        const Spacer(),
                        const SizedBox(height: 24),

                        // ── Confirm button ───────────────────────────────
                        SizedBox(
                          width: double.infinity,
                          height: 58,
                          child: ElevatedButton(
                            onPressed: (_isLoading || _selectedRole == null)
                                ? null
                                : _confirm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _selectedRole == null
                                  ? Colors.white.withOpacity(0.12)
                                  : _selectedRole == 'contractor'
                                      ? const Color(0xFF388E3C)
                                      : const Color(0xFF1565C0),
                              foregroundColor: Colors.white,
                              elevation: _selectedRole == null ? 0 : 6,
                              shadowColor: (_selectedRole == 'contractor'
                                      ? const Color(0xFF66BB6A)
                                      : const Color(0xFF4FC3F7))
                                  .withOpacity(0.4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2.5, color: Colors.white),
                                  )
                                : Text(
                                    widget.skipOtp
                                        ? 'Sign In as ${_selectedRole == null ? "..." : _selectedRole == "contractor" ? "Contractor" : "Citizen"}'
                                        : 'Verify & Sign In',
                                    style: const TextStyle(
                                        fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
