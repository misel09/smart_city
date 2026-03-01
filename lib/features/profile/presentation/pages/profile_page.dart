import 'package:flutter/material.dart';
import 'dart:convert';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/login/presentation/pages/login_page.dart';
import '../../../auth/forgot_password_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../../../features/reports/presentation/providers/complaints_provider.dart';
import 'package:http/http.dart' as http;
import '../../../../core/config/api_config.dart';
import '../../../../features/reports/domain/models/complaint.dart';
import 'filtered_complaints_page.dart';

class ProfilePage extends StatefulWidget {
  final String userName;
  final String userEmail;

  const ProfilePage({
    super.key,
    required this.userName,
    required this.userEmail,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _mobileNumber = 'Not Set';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;
    
    try {
      if (mounted) {
        context.read<ComplaintsProvider>().fetchComplaints(token);
      }
      final res = await http.get(Uri.parse(ApiConfig.meUrl), headers: {'Authorization': 'Bearer $token'});
      if (res.statusCode == 200 && mounted) {
        final data = jsonDecode(res.body);
        setState(() {
          _mobileNumber = data['mobile_number'] ?? 'Not Set';
        });
      }
    } catch (_) {}
  }

  void _startMobileVerificationFlow(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _MobileVerificationDialog(
        currentEmail: widget.userEmail,
        onVerified: (newNumber) {
          setState(() {
            _mobileNumber = newNumber;
          });
        },
      ),
    );
  }

  void _handleLogout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('currentUserEmail') ?? widget.userEmail.toLowerCase();
    final role = prefs.getString('role') ?? 'user';
    
    // Log this logout using scoped key
    final historyKey = 'logout_history_${email.toLowerCase()}_$role';
    final logoutHistory = prefs.getString(historyKey);
    List<dynamic> logs = logoutHistory != null ? jsonDecode(logoutHistory) : [];
    logs.add(DateTime.now().toIso8601String());
    await prefs.setString(historyKey, jsonEncode(logs));
    
    await prefs.remove('token');
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }
  }

  void _confirmDeleteAccount(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF18181B),
        title: const Text('Delete Account', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone and will delete all your registered complaints.',
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
              _deleteAccount(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;

    try {
      final response = await http.delete(
        Uri.parse(ApiConfig.deleteAccountUrl),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 && context.mounted) {
        // Successfully deleted
        final email = prefs.getString('currentUserEmail') ?? widget.userEmail.toLowerCase();
        final role = prefs.getString('role') ?? 'user';
        await prefs.remove('login_history_${email.toLowerCase()}_$role');
        await prefs.remove('logout_history_${email.toLowerCase()}_$role');
        await prefs.remove('token');
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete account: ${response.statusCode}'), backgroundColor: Colors.redAccent),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Widget build(BuildContext context) {
    final provider = Provider.of<ComplaintsProvider>(context);
    final myComplaints = provider.myComplaints;
    
    final total = myComplaints.length;
    final inProgress = myComplaints.where((c) => c.status == ComplaintStatus.inProgress).length;
    final resolved = myComplaints.where((c) => c.status == ComplaintStatus.resolved).length;
    final reviewed = myComplaints.where((c) => c.status == ComplaintStatus.reviewed).length;

    return Scaffold(
      backgroundColor: const Color(0xFF060D1F), // Dark ocean theme
      appBar: AppBar(
        title: const Text('Profile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: Navigator.of(context).canPop(), // Only show back button if pushed onto stack
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Section: Avatar, Name, Email
                Center(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF4FC3F7).withOpacity(0.5), width: 3),
                        ),
                        child: CircleAvatar(
                          backgroundColor: const Color(0xFF1565C0),
                          radius: 50,
                          child: Text(
                            widget.userName.isNotEmpty 
                                ? widget.userName[0].toUpperCase() 
                                : (widget.userEmail.isNotEmpty ? widget.userEmail[0].toUpperCase() : '?'),
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
                        widget.userName.isNotEmpty ? widget.userName : 'User',
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
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                const Text('Statistics of Complaints', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),

                // Statistics Cards equal-width in a 2x2 grid
                Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _buildStatCard('Total', total.toString(), Icons.format_list_bulleted, Colors.blueAccent, onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => FilteredComplaintsPage(
                            title: 'Total Complaints', isContractor: false, filterStatuses: null, // All
                          )));
                        })),
                        const SizedBox(width: 10),
                        Expanded(child: _buildStatCard('In Progress', inProgress.toString(), Icons.sync, Colors.orangeAccent, onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => FilteredComplaintsPage(
                            title: 'In Progress Complaints', isContractor: false, filterStatuses: const [ComplaintStatus.inProgress],
                          )));
                        })),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: _buildStatCard('Resolved', resolved.toString(), Icons.check_circle_outline, Colors.greenAccent, onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => FilteredComplaintsPage(
                            title: 'Resolved Complaints', isContractor: false, filterStatuses: const [ComplaintStatus.resolved],
                          )));
                        })),
                        const SizedBox(width: 10),
                        Expanded(child: _buildStatCard('Reviewed', reviewed.toString(), Icons.verified, Colors.tealAccent, onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => FilteredComplaintsPage(
                            title: 'Reviewed Complaints', isContractor: false, filterStatuses: const [ComplaintStatus.reviewed],
                          )));
                        })),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 32),
                const Text('Personal Details', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),

                // Personal Details Container
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF18181B).withOpacity(0.8),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Column(
                    children: [
                      _buildInfoRow(Icons.person, 'Username', widget.userName.isNotEmpty ? widget.userName : 'Not Set'),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(color: Colors.white24, height: 1),
                      ),
                      _buildInfoRow(Icons.email, 'Email', widget.userEmail),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(color: Colors.white24, height: 1),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.phone, color: Color(0xFF4FC3F7), size: 24),
                          const SizedBox(width: 16),
                          Text('Mobile Number', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14)),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              _mobileNumber, 
                              textAlign: TextAlign.right, 
                              overflow: TextOverflow.ellipsis, 
                              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => _startMobileVerificationFlow(context),
                            child: const Icon(Icons.edit, color: Color(0xFF4FC3F7), size: 20),
                          ),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(color: Colors.white24, height: 1),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.lock_reset, color: Color(0xFF4FC3F7), size: 24),
                          const SizedBox(width: 16),
                          Text(
                            'Password',
                            style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => ForgotPasswordPage(prefillEmail: widget.userEmail)));
                            },
                            child: const Text('Reset', style: TextStyle(color: Color(0xFF4FC3F7), fontWeight: FontWeight.bold)),
                          )
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 48),

                // Action Buttons
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _handleLogout(context),
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
                    onPressed: () => _confirmDeleteAccount(context),
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

  Widget _buildStatCard(String title, String count, IconData icon, Color color, {VoidCallback? onTap}) {
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

class _MobileVerificationDialog extends StatefulWidget {
  final String currentEmail;
  final Function(String) onVerified;

  const _MobileVerificationDialog({
    required this.currentEmail,
    required this.onVerified,
  });

  @override
  State<_MobileVerificationDialog> createState() => _MobileVerificationDialogState();
}

class _MobileVerificationDialogState extends State<_MobileVerificationDialog> {
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
        _showError('Failed to send OTP. Try again.');
      }
    } catch (_) {
      _showError('Network error.');
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
        body: jsonEncode({
          'new_mobile_number': phone,
          'otp': otp
        }),
      );

      if (res.statusCode == 200) {
        widget.onVerified(phone);
        if (mounted) Navigator.pop(context);
        _showSuccess('Mobile number verified successfully!');
      } else {
        _showError('Invalid OTP.');
      }
    } catch (_) {
      _showError('Network error.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.redAccent));
    }
  }

  void _showSuccess(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.green));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF18181B),
      title: Text(_step == 1 ? 'Verify Mobile Number' : 'Enter OTP', style: const TextStyle(color: Colors.white)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_step == 1) ...[
            const Text('An OTP will be sent to your registered email to verify the change.', style: TextStyle(color: Colors.white70, fontSize: 13)),
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
            Text('We sent a 6-digit code to\n${widget.currentEmail}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 16),
            TextField(
              controller: _otpCtrl,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 24, letterSpacing: 8),
              decoration: InputDecoration(
                counterText: '',
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ]
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : (_step == 1 ? _sendOtp : _verifyOtp),
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4FC3F7)),
          child: _isLoading 
            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Text(_step == 1 ? 'Send OTP' : 'Verify', style: const TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
