import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_city/core/config/api_config.dart';
import 'package:smart_city/features/home/presentation/pages/home_page.dart';
import 'package:smart_city/features/contractor/presentation/pages/contractor_dashboard_page.dart';

/// Multi-step forgot password page:
///  Step 1: Enter email → send OTP
///  Step 2: Enter OTP → verify → show options
///  Step 3a: Reset password → update DB → log in
///  Step 3b: Continue → log in directly with the OTP token
class ForgotPasswordPage extends StatefulWidget {
  /// Pre-filled from the login page (if user already typed email)
  final String prefillEmail;

  const ForgotPasswordPage({super.key, this.prefillEmail = ''});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

enum _Step { email, otp, choose, resetPassword }

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  // Controllers
  late final TextEditingController _emailCtrl;
  final _otpCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  _Step _step = _Step.email;
  bool _isLoading = false;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _resending = false;

  // Stored after OTP verify — used for "Continue" direct login
  String? _pendingToken;
  String? _pendingRole;

  @override
  void initState() {
    super.initState();
    _emailCtrl = TextEditingController(text: widget.prefillEmail);
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _otpCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  // ─── Step 1: Send OTP ───────────────────────────────────────────────────────
  Future<void> _sendOtp() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      _show('Please enter your email', isError: true);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final res = await http.post(
        Uri.parse(ApiConfig.forgotPasswordSendOtpUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );
      if (res.statusCode == 200) {
        setState(() => _step = _Step.otp);
        _show('Code sent to $email');
      } else {
        _show(jsonDecode(res.body)['detail'] ?? 'Failed to send code', isError: true);
      }
    } catch (e) {
      _show('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─── Resend OTP ─────────────────────────────────────────────────────────────
  Future<void> _resendOtp() async {
    setState(() => _resending = true);
    try {
      final res = await http.post(
        Uri.parse(ApiConfig.forgotPasswordSendOtpUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': _emailCtrl.text.trim()}),
      );
      _show(res.statusCode == 200 ? 'New code sent!' : jsonDecode(res.body)['detail'] ?? 'Failed',
          isError: res.statusCode != 200);
    } catch (e) {
      _show('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  // ─── Step 2: Verify OTP ─────────────────────────────────────────────────────
  Future<void> _verifyOtp() async {
    final otp = _otpCtrl.text.trim();
    if (otp.length != 6) {
      _show('Enter the 6-digit code', isError: true);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final res = await http.post(
        Uri.parse(ApiConfig.forgotPasswordVerifyOtpUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': _emailCtrl.text.trim(), 'otp': otp}),
      );
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        _pendingToken = body['access_token'];
        _pendingRole = body['role'];
        setState(() => _step = _Step.choose);
      } else {
        _show(jsonDecode(res.body)['detail'] ?? 'Invalid code', isError: true);
      }
    } catch (e) {
      _show('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─── Step 3a: Reset password ────────────────────────────────────────────────
  Future<void> _resetPassword() async {
    final newPass = _newPassCtrl.text;
    final confirmPass = _confirmPassCtrl.text;
    if (newPass.length < 6) {
      _show('Password must be at least 6 characters', isError: true);
      return;
    }
    if (newPass != confirmPass) {
      _show('Passwords do not match', isError: true);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final res = await http.post(
        Uri.parse(ApiConfig.forgotPasswordResetUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailCtrl.text.trim(),
          'otp': _otpCtrl.text.trim(),
          'new_password': newPass,
        }),
      );
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        await _loginWithToken(body['access_token'], body['role']);
      } else {
        _show(jsonDecode(res.body)['detail'] ?? 'Reset failed', isError: true);
      }
    } catch (e) {
      _show('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─── Step 3b: Continue (login directly) ─────────────────────────────────────
  Future<void> _continueDirect() async {
    if (_pendingToken == null) return;
    await _loginWithToken(_pendingToken!, _pendingRole);
  }

  Future<void> _loginWithToken(String token, String? role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    
    // Log this login
    final loginHistory = prefs.getString('login_history');
    List<dynamic> logs = loginHistory != null ? jsonDecode(loginHistory) : [];
    logs.add(DateTime.now().toIso8601String());
    await prefs.setString('login_history', jsonEncode(logs));
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
  }

  void _show(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
    ));
  }

  // ─── Build ──────────────────────────────────────────────────────────────────
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
            colors: [Color(0xFF060D1F), Color(0xFF0A2744), Color(0xFF072038)],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back button
                GestureDetector(
                  onTap: () => _step == _Step.email
                      ? Navigator.pop(context)
                      : setState(() => _step = _step == _Step.resetPassword ||
                              _step == _Step.choose
                          ? _Step.otp
                          : _Step.email),
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
                const SizedBox(height: 40),

                // Step indicator dots
                Row(
                  children: [_Step.email, _Step.otp, _Step.choose]
                      .map((s) => Container(
                            margin: const EdgeInsets.only(right: 8),
                            width: _step == s ? 24 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _step == s
                                  ? const Color(0xFFEF5350)
                                  : Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 24),

                // ── Step 1: Email ────────────────────────────────────────────
                if (_step == _Step.email) ..._emailStep(),

                // ── Step 2: OTP ──────────────────────────────────────────────
                if (_step == _Step.otp) ..._otpStep(),

                // ── Step 3: Choose ───────────────────────────────────────────
                if (_step == _Step.choose) ..._chooseStep(),

                // ── Step 4: Reset password ───────────────────────────────────
                if (_step == _Step.resetPassword) ..._resetStep(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Step widgets ─────────────────────────────────────────────────────────────

  List<Widget> _emailStep() => [
        const Text('Forgot Password?',
            style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.5)),
        const SizedBox(height: 10),
        const Text('Enter your email and we\'ll send a verification code.',
            style: TextStyle(fontSize: 15, color: Colors.white60, height: 1.5)),
        const SizedBox(height: 40),
        _label('EMAIL ADDRESS'),
        const SizedBox(height: 10),
        _inputField(
          controller: _emailCtrl,
          hint: 'citizen@smartcity.gov',
          prefix: Icons.email_rounded,
          keyboard: TextInputType.emailAddress,
        ),
        const SizedBox(height: 36),
        _primaryButton('Send Verification Code', _isLoading ? null : _sendOtp,
            color: const Color(0xFFEF5350)),
      ];

  List<Widget> _otpStep() => [
        const Text('Enter Code',
            style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.5)),
        const SizedBox(height: 10),
        Text('We sent a 6-digit code to\n${_emailCtrl.text.trim()}',
            style: const TextStyle(
                fontSize: 15, color: Colors.white60, height: 1.5)),
        const SizedBox(height: 40),
        _label('VERIFICATION CODE'),
        const SizedBox(height: 10),
        TextField(
          controller: _otpCtrl,
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
                borderSide:
                    BorderSide(color: Colors.white.withOpacity(0.15))),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide:
                    BorderSide(color: Colors.white.withOpacity(0.15))),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide:
                    const BorderSide(color: Color(0xFFEF5350), width: 2)),
            hintText: '_ _ _ _ _ _',
            hintStyle: TextStyle(
                color: Colors.white.withOpacity(0.15),
                fontSize: 28,
                letterSpacing: 12),
            contentPadding: const EdgeInsets.symmetric(vertical: 20),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: _resending ? null : _resendOtp,
            child: Text(_resending ? 'Sending...' : 'Resend Code',
                style: const TextStyle(color: Color(0xFFEF5350), fontSize: 13)),
          ),
        ),
        const SizedBox(height: 20),
        _primaryButton('Verify Code', _isLoading ? null : _verifyOtp,
            color: const Color(0xFFEF5350)),
      ];

  List<Widget> _chooseStep() => [
        const Text('Code Verified ✓',
            style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.5)),
        const SizedBox(height: 10),
        const Text('What would you like to do?',
            style: TextStyle(fontSize: 15, color: Colors.white60, height: 1.5)),
        const SizedBox(height: 48),

        // Reset password option
        _choiceCard(
          icon: Icons.lock_reset_rounded,
          color: const Color(0xFFEF5350),
          title: 'Reset Password',
          subtitle: 'Create a new password for your account',
          onTap: () => setState(() => _step = _Step.resetPassword),
        ),
        const SizedBox(height: 16),

        // Continue option
        _choiceCard(
          icon: Icons.login_rounded,
          color: const Color(0xFF4FC3F7),
          title: 'Continue to App',
          subtitle: 'Log in directly without resetting your password',
          onTap: _continueDirect,
        ),
      ];

  List<Widget> _resetStep() => [
        const Text('Reset Password',
            style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.5)),
        const SizedBox(height: 10),
        const Text('Choose a new password for your account.',
            style: TextStyle(fontSize: 15, color: Colors.white60, height: 1.5)),
        const SizedBox(height: 40),
        _label('NEW PASSWORD'),
        const SizedBox(height: 10),
        _passwordField(_newPassCtrl, 'Minimum 6 characters', _obscureNew,
            () => setState(() => _obscureNew = !_obscureNew)),
        const SizedBox(height: 20),
        _label('CONFIRM PASSWORD'),
        const SizedBox(height: 10),
        _passwordField(_confirmPassCtrl, 'Re-enter new password', _obscureConfirm,
            () => setState(() => _obscureConfirm = !_obscureConfirm)),
        const SizedBox(height: 36),
        _primaryButton(
            'Update Password', _isLoading ? null : _resetPassword,
            color: const Color(0xFFEF5350)),
      ];

  // ── Shared small widgets ──────────────────────────────────────────────────────

  Widget _label(String text) => Text(text,
      style: const TextStyle(
          color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1));

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData prefix,
    TextInputType keyboard = TextInputType.text,
  }) =>
      TextField(
        controller: controller,
        keyboardType: keyboard,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
          prefixIcon: Icon(prefix, color: Colors.white38, size: 20),
          filled: true,
          fillColor: Colors.white.withOpacity(0.07),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.12))),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.12))),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFEF5350), width: 2)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
      );

  Widget _passwordField(TextEditingController ctrl, String hint, bool obscure, VoidCallback toggle) =>
      TextField(
        controller: ctrl,
        obscureText: obscure,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
          prefixIcon: const Icon(Icons.lock_rounded, color: Colors.white38, size: 20),
          suffixIcon: IconButton(
            icon: Icon(obscure ? Icons.visibility_off : Icons.visibility,
                color: Colors.white38, size: 20),
            onPressed: toggle,
          ),
          filled: true,
          fillColor: Colors.white.withOpacity(0.07),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.12))),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.12))),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFEF5350), width: 2)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
      );

  Widget _primaryButton(String label, VoidCallback? onTap, {required Color color}) =>
      SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: onTap == null ? Colors.white12 : color,
            foregroundColor: Colors.white,
            elevation: onTap == null ? 0 : 6,
            shadowColor: color.withOpacity(0.4),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
              : Text(label,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      );

  Widget _choiceCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.3), width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            color: color,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 13, height: 1.4)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, color: color, size: 16),
            ],
          ),
        ),
      );
}
