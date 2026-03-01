import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConfig {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:8000';
    } else if (Platform.isAndroid) {
      // Use LAN IP for specific device testing (update as needed)
      // Emulator: 10.0.2.2, Physical: 192.168.0.103
      return 'http://192.168.0.103:8000';
    } else {
      // For iOS simulator, macOS, or Windows
      return 'http://127.0.0.1:8000';
    }
  }

  static String get loginUrl => '$baseUrl/auth/login';
  static String get meUrl => '$baseUrl/auth/me';
  static String get deleteAccountUrl => '$baseUrl/auth/delete-account';
  static String get contractorsUrl => '$baseUrl/auth/contractors';
  static String get mobileOtpSendUrl => '$baseUrl/auth/mobile/send-otp';
  static String get mobileOtpVerifyUrl => '$baseUrl/auth/mobile/verify-otp';
  static String get registerUrl => '$baseUrl/auth/register';
  static String get googleLoginUrl => '$baseUrl/auth/google';
  static String get googleInitiateUrl => '$baseUrl/auth/google/initiate';
  static String get googleSelectRoleUrl => '$baseUrl/auth/google/select-role';
  static String get googleSendOtpUrl => '$baseUrl/auth/google/send-otp';
  static String get googleVerifyOtpUrl => '$baseUrl/auth/google/verify-otp';
  static String get forgotPasswordSendOtpUrl => '$baseUrl/auth/forgot-password/send-otp';
  static String get forgotPasswordVerifyOtpUrl => '$baseUrl/auth/forgot-password/verify-otp';
  static String get forgotPasswordResetUrl => '$baseUrl/auth/forgot-password/reset-password';
  static String get complaintsUrl => '$baseUrl/complaints';
  static String get myComplaintsUrl => '$baseUrl/complaints/my';
  static String get takenComplaintsUrl => '$baseUrl/complaints/taken';
  static String get nearbyComplaintsUrl => '$baseUrl/complaints/nearby';
  static String userInfoUrl(String email) => '$baseUrl/auth/user-info?email=${Uri.encodeComponent(email)}';
}
