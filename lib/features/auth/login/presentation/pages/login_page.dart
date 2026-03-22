import 'package:flutter/material.dart';
import 'package:smart_city/core/theme/app_colors.dart';
import 'package:smart_city/features/home/presentation/pages/home_page.dart';
import 'package:smart_city/features/auth/register/presentation/pages/register_page.dart';
import 'package:smart_city/features/contractor/presentation/pages/contractor_dashboard_page.dart';
import 'package:smart_city/features/officer/presentation/pages/officer_dashboard_page.dart';
import 'package:smart_city/features/officer/presentation/pages/officer_main_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_city/core/config/api_config.dart';
import 'package:smart_city/features/auth/google_auth_helper.dart';
import 'package:smart_city/features/auth/forgot_password_page.dart';
import 'package:smart_city/features/auth/google_otp_verify_page.dart';

import 'package:flutter/foundation.dart' show kIsWeb;

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _rememberMe = false;

  String? _selectedRole;
  String? _selectedContractorType;

  final List<String> _roles = ['Citizen', 'Contractor', 'Municipality Officer'];
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

  String? _lastSavedEmail;
  String? _lastSavedPassword;
  String? _lastSavedRole;
  String? _lastSavedName;

  @override
  void initState() {
    super.initState();
    _loadSavedAccount();
  }

  Future<void> _loadSavedAccount() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _lastSavedEmail = prefs.getString('saved_email');
      _lastSavedPassword = prefs.getString('saved_password');
      _lastSavedRole = prefs.getString('saved_role');
      _lastSavedName = prefs.getString('saved_name');
    });
  }

  Future<void> _saveSavedAccount(String email, String password, String role, String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_email', email);
    await prefs.setString('saved_password', password);
    await prefs.setString('saved_role', role);
    await prefs.setString('saved_name', name);
  }

  Future<void> _clearSavedAccount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('saved_email');
    await prefs.remove('saved_password');
    await prefs.remove('saved_role');
    await prefs.remove('saved_name');
    setState(() {
      _lastSavedEmail = null;
      _lastSavedPassword = null;
      _lastSavedRole = null;
      _lastSavedName = null;
    });
  }

  Future<void> _quickLogin() async {
    if (_lastSavedEmail == null || _lastSavedPassword == null || _lastSavedRole == null) return;
    
    _emailController.text = _lastSavedEmail!;
    _passwordController.text = _lastSavedPassword!;
    
    // Map role string back to display name for dropdown
    final roleDisplayName = _roles.firstWhere(
      (r) => r.toLowerCase().replaceAll(' ', '_').trim() == _lastSavedRole,
      orElse: () => _roles[0]
    );
    
    setState(() {
      _selectedRole = roleDisplayName;
      _isLoading = true;
    });
    
    await _login();
  }

  Future<void> _login() async {
    setState(() => _isLoading = true);

    if (_selectedRole == null || _selectedRole!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a role')),
      );
      setState(() => _isLoading = false);
      return;
    }
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      setState(() => _isLoading = false);
      return;
    }

    try {
      // Use ApiConfig for dynamic URL handling
      final uri = Uri.parse(ApiConfig.loginUrl); 
      
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailController.text,
          'password': _passwordController.text,
          'role': _selectedRole!.toLowerCase().replaceAll(' ', '_'),
          'contractor_type': _selectedContractorType,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['access_token'];
        
          final prefs = await SharedPreferences.getInstance();
          final roleKey = _selectedRole!.toLowerCase().replaceAll(' ', '_').trim();
          await prefs.setString('token', token);
          await prefs.setString('role', roleKey);
          await prefs.setString('currentUserEmail', _emailController.text.trim().toLowerCase());
          
          // Save for Remember Me if enabled
          if (_rememberMe) {
            // In a real app, you might get the user's name from data['user']['name']
            final userName = data['name'] ?? data['fullname'] ?? _emailController.text.split('@')[0];
            await _saveSavedAccount(
              _emailController.text.trim(), 
              _passwordController.text, 
              roleKey, 
              userName
            );
          }
        
        // Log this login using scoped key
        final historyKey = 'login_history_${_emailController.text.trim().toLowerCase()}_$roleKey';
        final loginHistory = prefs.getString(historyKey);
        List<dynamic> logs = loginHistory != null ? jsonDecode(loginHistory) : [];
        logs.add(DateTime.now().toIso8601String());
        await prefs.setString(historyKey, jsonEncode(logs));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Login Successful!')),
          );
          
          if (_selectedRole == 'Contractor') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const ContractorDashboardPage()),
            );
          } else if (_selectedRole == 'Municipality Officer') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const MunicipalityOfficerMainPage()),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomePage()),
            );
          }
        }
      } else {
        if (mounted) {
           final error = jsonDecode(response.body)['detail'] ?? 'Login failed';
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

  Future<void> _loginWithGoogle() async {
    if (_selectedRole == null || _selectedRole!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your role (Citizen or Contractor)')),
      );
      return;
    }

    if (_selectedRole == 'Municipality Officer') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Google Login is not allowed for Municipality Officers. Please use your officer credentials.')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final accountData = await signInWithGoogle();
      if (accountData == null) {
        setState(() => _isLoading = false);
        return; // User cancelled
      }

      // We directly pass the selected role and contractor type to the backend.
      // If the email doesn't have an account with this role, the backend creates it.
      // If it does, it simply logs them in.
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/google/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': accountData['email'],
          'name': accountData['name'],
          'google_id': accountData['google_id'],
          'role': _selectedRole!.toLowerCase().replaceAll(' ', '_'),
          'contractor_type': _selectedContractorType,
        }),
      );

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);

        if (body['action'] == 'require_otp') {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(body['message'] ?? 'OTP sent to email.')),
            );
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => GoogleOtpVerifyPage(
                  email: accountData['email']!,
                  name: accountData['name']!,
                  googleId: accountData['google_id']!,
                   role: _selectedRole!,
                  contractorType: _selectedContractorType,
                ),
              ),
            );
          }
          return;
        }

        final prefs = await SharedPreferences.getInstance();
        final roleKey = _selectedRole!.toLowerCase().replaceAll(' ', '_').trim();
        await prefs.setString('token', body['access_token']);
        await prefs.setString('role', roleKey);
        final email = accountData['email']!.toLowerCase();
        await prefs.setString('currentUserEmail', email);

        // Log this login using scoped key
        final historyKey = 'login_history_${email}_$roleKey';
        final loginHistory = prefs.getString(historyKey);
        List<dynamic> logs = loginHistory != null ? jsonDecode(loginHistory) : [];
        logs.add(DateTime.now().toIso8601String());
        await prefs.setString(historyKey, jsonEncode(logs));

        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Google Login Successful!')),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => _selectedRole == 'Contractor'
                  ? const ContractorDashboardPage()
                  : _selectedRole == 'Municipality Officer'
                      ? const MunicipalityOfficerMainPage()
                      : const HomePage(),
            ),
          );
        }
      } else {
        final error = jsonDecode(res.body)['detail'] ?? 'Failed to login with Google';
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error), backgroundColor: Colors.red),
          );
        }
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $error'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1D37), // Dark blue background for safety
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
          // Actually, SingleChildScrollView with Column allows infinite height. 
          // We don't want to constrain height. We just want the Stack to be big enough.
          // Let's just use the Stack directly.
          child: Stack(
            children: [
              // 1. Top Section - Background & Title
              // We keep this Positioned so it stays at the top of the SCROLLABLE area.
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: MediaQuery.of(context).size.height * 0.45,
                child: Container(
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/images/login_bg.jpg'),
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(
                        Colors.black54, // Dark overlay for text readability
                        BlendMode.darken,
                      ),
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Smart City',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'A powerful tool to manage and solve\nthe urban issue',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 40), // Push text up a bit
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // 2. Bottom Section - White Card form
              // We use a Column with a top spacer to position the card relative to the top.
              // This makes it part of the flow, so looking at it pushes the scroll view bounds.
              Column(
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.38),
                  Container(
                    width: double.infinity, // Ensure full width
                    constraints: BoxConstraints(
                      minHeight: MediaQuery.of(context).size.height * 0.62,
                    ),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFF002244), // Darker ocean blue
                          Color(0xFF0077BE), // Lighter ocean blue
                        ],
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        
                        const Text(
                          'Welcome Back',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Role Selection
                        const Text("Select Role", style: TextStyle(color: Colors.white70, fontSize: 12)),
                        const SizedBox(height: 8),
                         DropdownButtonFormField<String>(
                          isExpanded: true,
                          value: _selectedRole,
                          hint: const Text("Select Role (e.g., Citizen)"),
                          items: _roles.map((role) {
                            return DropdownMenuItem(value: role, child: Text(role));
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedRole = val!;
                              if (_selectedRole != 'Contractor') {
                                _selectedContractorType = null;
                              } else {
                                _selectedContractorType = _contractorTypes[0]; // Default
                              }
                            });
                          },
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFFF1F5F9),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Contractor Type Selection (Conditional)
                        if (_selectedRole == 'Contractor') ...[
                          const Text("Contractor Type", style: TextStyle(color: Colors.white70, fontSize: 12)),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            isExpanded: true,
                            value: _selectedContractorType,
                            items: _contractorTypes.map((type) {
                              return DropdownMenuItem(value: type, child: Text(type, overflow: TextOverflow.ellipsis));
                            }).toList(),
                            onChanged: (val) => setState(() => _selectedContractorType = val),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: const Color(0xFFF1F5F9),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],

                        // Email
                        const Text("Email Address", style: TextStyle(color: Colors.white70, fontSize: 12)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _emailController,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                          decoration: InputDecoration(
                            hintText: "citizen@smartcity.gov",
                            filled: true,
                            fillColor: const Color(0xFFF1F5F9), // Light grey
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          ),
                        ),
                        
                        const SizedBox(height: 20),

                        // Password
                        const Text("Password", style: TextStyle(color: Colors.white70, fontSize: 12)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _passwordController,
                          obscureText: !_isPasswordVisible,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFFF1F5F9),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                color: Colors.grey,
                              ),
                              onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Remember Me & Forgot PW
                        Row(
                          children: [
                            SizedBox(
                              height: 24,
                              width: 24,
                              child: Checkbox(
                                value: _rememberMe,
                                activeColor: AppColors.primary,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                onChanged: (val) => setState(() => _rememberMe = val ?? false),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text("Remember me", style: TextStyle(color: Colors.white70, fontSize: 13)),
                            const Spacer(),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ForgotPasswordPage(
                                      prefillEmail: _emailController.text.trim(),
                                    ),
                                  ),
                                );
                              },
                              child: const Text(
                                "Forgot password?",
                                style: TextStyle(
                                  color: Color(0xFF4FC3F7),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),

                        // Sign In Button
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2196F3), // Bright Blue
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(27), // Fully rounded caps
                                ),
                              ),
                              child: _isLoading 
                                ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Text(
                                  "Sign In",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),
                        // Google Sign In Button - Hidden for Municipality Officer
                        if (_selectedRole != 'Municipality Officer') ...[
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: OutlinedButton(
                              onPressed: _isLoading ? null : _loginWithGoogle,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                  side: const BorderSide(color: Colors.white54, width: 1),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(27),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Image.asset('assets/images/google_logo.png', height: 24, width: 24, errorBuilder: (context, error, stackTrace) => const Icon(Icons.g_mobiledata, color: Colors.white, size: 30)),
                                    const SizedBox(width: 12),
                                    const Text(
                                      "Sign in with Google",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],

                        if (_lastSavedEmail != null) ...[
                          const SizedBox(height: 24),
                          const Divider(color: Colors.white24, height: 1),
                          const SizedBox(height: 24),
                          const Center(
                            child: Text(
                              "Saved Account",
                              style: TextStyle(color: Colors.white60, fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withOpacity(0.1)),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4FC3F7).withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.person_outline_rounded, color: Color(0xFF4FC3F7)),
                              ),
                              title: Text(
                                _lastSavedName ?? 'User',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                _lastSavedEmail!,
                                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.close_rounded, color: Colors.white38, size: 20),
                                onPressed: _clearSavedAccount,
                                tooltip: "Forget Account",
                              ),
                              onTap: _isLoading ? null : _quickLogin,
                            ),
                          ),
                        ],

                        const SizedBox(height: 32),
                        
                        // Register Link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("Don't have an account? ", style: TextStyle(color: Colors.white70)),
                            GestureDetector(
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterPage())),
                              child: const Text(
                                "Register here",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 40), // Bottom safe area
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
            ),
          );
        },
      ),
    );
  }
}

