import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:smart_city/core/theme/app_colors.dart';
import 'package:smart_city/features/auth/login/presentation/pages/login_page.dart';
import '../widgets/password_strength_indicator.dart';
import 'package:smart_city/core/config/api_config.dart';
import 'package:smart_city/features/auth/google_auth_helper.dart';
import 'package:smart_city/features/auth/google_otp_role_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_city/features/home/presentation/pages/home_page.dart';
import 'package:smart_city/features/contractor/presentation/pages/contractor_dashboard_page.dart';

import 'package:flutter/foundation.dart' show kIsWeb;


class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _agreedToTerms = false;
  bool _isLoading = false;

  String _selectedRole = 'User';
  String? _selectedContractorType;

  final List<String> _roles = ['User', 'Contractor'];
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1D37), // Dark blue background
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
          child: Stack(
            children: [
              // 1. Top Section - Background & Title
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
                        Colors.black54, // Dark overlay
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
                            'Join Smart City',
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
                            'Become a part of the solution for\na better urban life',
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
              Column(
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.38),
                  Container(
                    width: double.infinity,
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
                          'Create Account',
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
                          value: _selectedRole,
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

                        // Username
                        const Text("Username", style: TextStyle(color: Colors.white70, fontSize: 12)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _nameController,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                          decoration: InputDecoration(
                            hintText: "Your Name",
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

                        // Email
                        const Text("Email Address", style: TextStyle(color: Colors.white70, fontSize: 12)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                          decoration: InputDecoration(
                            hintText: "citizen@smartcity.gov",
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

                        // Password
                        const Text("Password", style: TextStyle(color: Colors.white70, fontSize: 12)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _passwordController,
                          obscureText: !_isPasswordVisible,
                          onChanged: (val) => setState(() {}),
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

                        const SizedBox(height: 12),
                        
                        // Password Strength
                        PasswordStrengthIndicator(password: _passwordController.text),
                        
                        const SizedBox(height: 16),

                        // Terms
                        Row(
                          children: [
                            SizedBox(
                              height: 24,
                              width: 24,
                              child: Checkbox(
                                value: _agreedToTerms,
                                activeColor: AppColors.primary,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                onChanged: (val) {
                                  setState(() {
                                     _agreedToTerms = val ?? false;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text('I agree to Terms & Conditions', style: TextStyle(color: Colors.white70, fontSize: 13)),
                          ],
                        ),

                        const SizedBox(height: 32),

                        // Create Account Button
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: _agreedToTerms && !_isLoading
                              ? _register
                              : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2196F3),
                              disabledBackgroundColor: Colors.grey.shade300,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(27),
                              ),
                            ),
                            child: _isLoading 
                              ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text(
                                "Create Account", 
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16
                                )
                              ),
                          ),
                        ),

                        const SizedBox(height: 16),
                        
                        // Google Sign Up Button
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: OutlinedButton(
                            onPressed: _isLoading ? null : _registerWithGoogle,
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
                                  "Sign up with Google",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Login Link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                             const Text("Already have an account? ", style: TextStyle(color: Colors.white70)),
                             GestureDetector(
                               onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage())),
                               child: const Text(
                                 'Login',
                                 style: TextStyle(
                                   color: Colors.white,
                                   fontWeight: FontWeight.bold,
                                 ),
                               ),
                             )
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


  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    setState(() => _isLoading = true);
    
    // Quick validation
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      setState(() => _isLoading = false);
      return;
    }

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.registerUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': _nameController.text, // Optional but good to send
          'email': _emailController.text,
          'password': _passwordController.text,
          'role': _selectedRole.toLowerCase(),
          'contractor_type': _selectedContractorType,
        }),
      );

      if (response.statusCode == 200) {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Registration Successful! Please Login.')),
          );
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
        }
      } else {
        if (mounted) {
          final error = jsonDecode(response.body)['detail'] ?? 'Registration failed';
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

  Future<void> _registerWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final accountData = await signInWithGoogle();
      if (accountData == null) return; // User cancelled

      // Step 1: Send OTP to the Google email
      final sendRes = await http.post(
        Uri.parse(ApiConfig.googleSendOtpUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': accountData['email'],
          'name': accountData['name'],
          'google_id': accountData['google_id'],
        }),
      );

      if (sendRes.statusCode == 200) {
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => GoogleOtpRolePage(
                email: accountData['email']!,
                name: accountData['name']!,
                googleId: accountData['google_id']!,
              ),
            ),
          );
        }
      } else {
        final error = jsonDecode(sendRes.body)['detail'] ?? 'Failed to send OTP';
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
}
