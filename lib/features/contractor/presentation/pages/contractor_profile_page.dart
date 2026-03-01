import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/config/api_config.dart';
import '../../../auth/login/presentation/pages/login_page.dart';
import '../../../auth/forgot_password_page.dart';
import '../../../reports/presentation/providers/complaints_provider.dart';
import '../../../reports/domain/models/complaint.dart';
import '../../../../features/profile/presentation/pages/filtered_complaints_page.dart';

class ContractorProfilePage extends StatefulWidget {
  final String userName;
  final String userEmail;

  const ContractorProfilePage({
    super.key,
    required this.userName,
    required this.userEmail,
  });

  @override
  State<ContractorProfilePage> createState() => _ContractorProfilePageState();
}

class _ContractorProfilePageState extends State<ContractorProfilePage> {
  String _mobileNumber = 'Not Set';
  String _contractorType = '';
  bool _isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) {
      if (mounted) setState(() => _isLoadingProfile = false);
      return;
    }
    try {
      final res = await http.get(
        Uri.parse(ApiConfig.meUrl),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode == 200 && mounted) {
        final data = jsonDecode(res.body);
        setState(() {
          _mobileNumber = data['mobile_number'] ?? 'Not Set';
          _contractorType = data['contractor_type'] ?? '';
          _isLoadingProfile = false;
        });
        
        // Also fetch the tasks taken by this contractor
        if (mounted) {
          context.read<ComplaintsProvider>().fetchTakenComplaints(token);
        }
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingProfile = false);
    }
  }

  void _startMobileVerificationFlow() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _MobileVerificationDialog(
        currentEmail: widget.userEmail,
        onVerified: (newNumber) {
          if (mounted) setState(() => _mobileNumber = newNumber);
        },
      ),
    );
  }

  Future<void> _handleLogout() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('currentUserEmail') ?? widget.userEmail.toLowerCase();
    final role = prefs.getString('role') ?? 'contractor';
    
    // Log this logout using scoped key
    final historyKey = 'logout_history_${email.toLowerCase()}_$role';
    final logoutHistory = prefs.getString(historyKey);
    List<dynamic> logs = logoutHistory != null ? jsonDecode(logoutHistory) : [];
    logs.add(DateTime.now().toIso8601String());
    await prefs.setString(historyKey, jsonEncode(logs));

    await prefs.remove('token');
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }
  }

  void _confirmDeleteAccount() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF18181B),
        title: const Text('Delete Account', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to delete your contractor account? This action cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteAccount();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;

    try {
      final res = await http.delete(
        Uri.parse(ApiConfig.deleteAccountUrl),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode == 200 && mounted) {
        final email = prefs.getString('currentUserEmail') ?? widget.userEmail.toLowerCase();
        final role = prefs.getString('role') ?? 'contractor';
        await prefs.remove('login_history_${email.toLowerCase()}_$role');
        await prefs.remove('logout_history_${email.toLowerCase()}_$role');
        await prefs.remove('token');
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete: ${res.statusCode}'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red.shade700),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ComplaintsProvider>(context);
    final takenComplaints = provider.takenComplaints;

    // Contractor work stats
    final taken = takenComplaints.length;
    final completed = takenComplaints
        .where((c) => c.status == ComplaintStatus.resolved)
        .length;
    final inProgress = takenComplaints
        .where((c) => c.status == ComplaintStatus.inProgress || c.status == ComplaintStatus.rejected)
        .length;
    final reviewed = takenComplaints
        .where((c) => c.status == ComplaintStatus.reviewed)
        .length;

    return Scaffold(
      backgroundColor: const Color(0xFF060D1F),
      appBar: AppBar(
        title: const Text('My Profile',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: Navigator.of(context).canPop(),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Avatar & Identity ──────────────────────────────────────
                Center(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: const Color(0xFF4FC3F7).withOpacity(0.5),
                              width: 3),
                        ),
                        child: CircleAvatar(
                          backgroundColor: const Color(0xFF1565C0),
                          radius: 50,
                          child: Text(
                            widget.userName.isNotEmpty
                                ? widget.userName[0].toUpperCase()
                                : (widget.userEmail.isNotEmpty
                                    ? widget.userEmail[0].toUpperCase()
                                    : '?'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 40,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.userName.isNotEmpty
                            ? widget.userName
                            : 'Contractor',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.userEmail,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Contractor badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: const Color(0xFF10B981).withOpacity(0.4)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.handyman_rounded,
                                color: Color(0xFF10B981), size: 13),
                            SizedBox(width: 6),
                            Text(
                              'Verified Contractor',
                              style: TextStyle(
                                color: Color(0xFF10B981),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_contractorType.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          _contractorType,
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 13),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 32),
                const Text('Work Statistics',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),

                // ── Work stat cards (equal-width) in a 2x2 grid ────────────────
                Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _buildStatCard('Tasks\nTaken', taken.toString(),
                            Icons.assignment_rounded, Colors.blueAccent, onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => FilteredComplaintsPage(
                                title: 'Tasks Taken', isContractor: true, filterStatuses: null, // All taken
                              )));
                            })),
                        const SizedBox(width: 10),
                        Expanded(child: _buildStatCard('In\nProgress', inProgress.toString(),
                            Icons.sync_rounded, Colors.orangeAccent, onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => FilteredComplaintsPage(
                                title: 'In Progress Tasks', isContractor: true, filterStatuses: const [ComplaintStatus.inProgress, ComplaintStatus.rejected],
                              )));
                            })),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: _buildStatCard('Completed\nTasks', completed.toString(),
                            Icons.check_circle_outline, Colors.greenAccent, onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => FilteredComplaintsPage(
                                title: 'Completed Tasks', isContractor: true, filterStatuses: const [ComplaintStatus.resolved],
                              )));
                            })),
                        const SizedBox(width: 10),
                        Expanded(child: _buildStatCard('Reviewed\nTasks', reviewed.toString(),
                            Icons.verified, Colors.tealAccent, onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => FilteredComplaintsPage(
                                title: 'Reviewed Tasks', isContractor: true, filterStatuses: const [ComplaintStatus.reviewed],
                              )));
                            })),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 32),
                const Text('Personal Details',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),

                // ── Personal Details Container ──────────────────────────────
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF18181B).withOpacity(0.8),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Column(
                    children: [
                      _buildInfoRow(Icons.person, 'Username',
                          widget.userName.isNotEmpty ? widget.userName : 'Not Set'),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(color: Colors.white24, height: 1),
                      ),
                      _buildInfoRow(Icons.email, 'Email', widget.userEmail),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(color: Colors.white24, height: 1),
                      ),
                      // Editable mobile
                      Row(
                        children: [
                          const Icon(Icons.phone,
                              color: Color(0xFF4FC3F7), size: 24),
                          const SizedBox(width: 16),
                          Text('Mobile Number',
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: 14)),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _isLoadingProfile
                                ? const Align(
                                    alignment: Alignment.centerRight,
                                    child: SizedBox(
                                        height: 12,
                                        width: 80,
                                        child: LinearProgressIndicator(
                                            color: Color(0xFF4FC3F7),
                                            backgroundColor: Colors.white12)),
                                  )
                                : Text(_mobileNumber,
                                    textAlign: TextAlign.right,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600)),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: _startMobileVerificationFlow,
                            child: const Icon(Icons.edit,
                                color: Color(0xFF4FC3F7), size: 20),
                          ),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(color: Colors.white24, height: 1),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.lock_reset,
                              color: Color(0xFF4FC3F7), size: 24),
                          const SizedBox(width: 16),
                          Text('Password',
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: 14)),
                          const Spacer(),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ForgotPasswordPage(
                                      prefillEmail: widget.userEmail),
                                ),
                              );
                            },
                            child: const Text('Reset',
                                style: TextStyle(
                                    color: Color(0xFF4FC3F7),
                                    fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── Contractor specialisation card ─────────────────────────
                if (_contractorType.isNotEmpty) ...[
                  const SizedBox(height: 32),
                  const Text('Contractor Details',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF18181B).withOpacity(0.8),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: const Color(0xFF10B981).withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.handyman_rounded,
                            color: Color(0xFF10B981), size: 24),
                        const SizedBox(width: 16),
                        Text('Specialisation',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 14)),
                        Expanded(
                          child: Text(
                            _contractorType,
                            textAlign: TextAlign.end,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 48),

                // ── Action Buttons ─────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _handleLogout,
                    icon: const Icon(Icons.logout, color: Colors.white),
                    label: const Text(
                      'Log Out',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      side: const BorderSide(color: Colors.white54),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _confirmDeleteAccount,
                    icon: const Icon(Icons.delete_forever, color: Colors.white),
                    label: const Text(
                      'Delete Account',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent.withOpacity(0.8),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String title, String count, IconData icon, Color color, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF18181B).withOpacity(0.8),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.5), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 2,
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon + number on the same line
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 6),
                Text(
                  count,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                color: Colors.white.withOpacity(0.65),
                fontSize: 11,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF4FC3F7), size: 24),
        const SizedBox(width: 16),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Mobile Verification Dialog (reused from ProfilePage)
// ──────────────────────────────────────────────────────────────────────────────

class _MobileVerificationDialog extends StatefulWidget {
  final String currentEmail;
  final Function(String) onVerified;

  const _MobileVerificationDialog({
    required this.currentEmail,
    required this.onVerified,
  });

  @override
  State<_MobileVerificationDialog> createState() =>
      _MobileVerificationDialogState();
}

class _MobileVerificationDialogState
    extends State<_MobileVerificationDialog> {
  int _step = 1;
  bool _isLoading = false;

  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();

  Future<void> _sendOtp() async {
    final phone = _phoneCtrl.text.trim();
    if (phone.isEmpty) return;

    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final res = await http.post(
        Uri.parse(ApiConfig.mobileOtpSendUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'new_mobile_number': phone}),
      );

      if (res.statusCode == 200) {
        setState(() => _step = 2);
      } else {
        _showSnack('Failed to send OTP. Try again.', isError: true);
      }
    } catch (_) {
      _showSnack('Network error.', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyOtp() async {
    final phone = _phoneCtrl.text.trim();
    final otp = _otpCtrl.text.trim();
    if (otp.length != 6) return;

    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final res = await http.post(
        Uri.parse(ApiConfig.mobileOtpVerifyUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'new_mobile_number': phone, 'otp': otp}),
      );

      if (res.statusCode == 200) {
        widget.onVerified(phone);
        if (mounted) Navigator.pop(context);
        _showSnack('Mobile number verified!', isError: false);
      } else {
        _showSnack('Invalid OTP.', isError: true);
      }
    } catch (_) {
      _showSnack('Network error.', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg, {required bool isError}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: isError ? Colors.red.shade700 : Colors.green,
        ),
      );
    }
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF18181B),
      title: Text(
        _step == 1 ? 'Verify Mobile Number' : 'Enter OTP',
        style: const TextStyle(color: Colors.white),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_step == 1) ...[
            const Text(
              'Enter your new mobile number.\nAn OTP will be sent to your registered email.',
              style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'e.g. +1234567890',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ] else ...[
            Text(
              'A 6-digit code was sent to\n${widget.currentEmail}',
              style: const TextStyle(
                  color: Colors.white70, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _otpCtrl,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white, fontSize: 24, letterSpacing: 8),
              decoration: InputDecoration(
                counterText: '',
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : (_step == 1 ? _sendOtp : _verifyOtp),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4FC3F7),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 16, height: 16,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text(
                  _step == 1 ? 'Send OTP' : 'Verify',
                  style: const TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
