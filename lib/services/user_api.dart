import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class UserApi {
  // 🔗 Render backend base URL
  static const String _baseUrl =
      "https://hiw-backend.onrender.com";

  /// Register / update user profile
  static Future<void> registerUser({
    required String email,
    required String password, // 🔐 NEW
    required String username, // 👤 NEW
    required int age,
    required String gender,
    required double height,
    required double weight,
    required String activityLevel,
    required int targetCalories,
  }) async {
    final uri = Uri.parse("$_baseUrl/register");

    final response = await http.post(
      uri,
      headers: const {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "email": email,
        "password": password,
        "username": username,
        "age": age,
        "gender": gender,
        "height": height,
        "weight": weight,
        "activityLevel": activityLevel,
        "targetCalories": targetCalories,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception(
        "User registration failed: ${response.body}",
      );
    }
  }

  /// 🔓 Login User
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse("$_baseUrl/login");

    final response = await http.post(
      uri,
      headers: const {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": email,
        "password": password,
      }),
    ).timeout(const Duration(seconds: 20)); // ⏱️ Added timeout

    if (response.statusCode == 200) {
      // Return user data (expecting { "username": "...", ... })
      return jsonDecode(response.body);
    } else {
      throw Exception("Login failed: ${response.body}");
    }
  }

  /// Health check (optional, for debug)
  static Future<bool> healthCheck() async {
    try {
      final res = await http.get(
        Uri.parse("$_baseUrl/health"),
      ).timeout(const Duration(seconds: 5));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// 🧪 Verify Tester Code (Backend logic)
  static Future<void> verifyTesterCode(String code, String email) async {
    final uri = Uri.parse("$_baseUrl/verify_tester_code");
    final response = await http.post(
      uri,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"code": code, "email": email}),
    ).timeout(const Duration(seconds: 30)); // ⏱️ Longer timeout for slow wakeups

    if (response.statusCode == 200) {
      return;
    } else if (response.statusCode == 403) {
      throw Exception("Code already in use by another person. Don't try to copy!");
    } else {
      final data = jsonDecode(response.body);
      throw Exception(data['error'] ?? "Validation failed");
    }
  }

  /// 🔓 Reset Password
  static Future<void> resetPassword({
    required String email,
    required String newPassword,
  }) async {
    final uri = Uri.parse("$_baseUrl/reset_password");
    final response = await http.post(
      uri,
      headers: const {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": email,
        "new_password": newPassword,
      }),
    );

    if (response.statusCode != 200) {
      debugPrint("❌ Password Reset Error [${response.statusCode}]: ${response.body}");
      throw Exception("Password reset failed (${response.statusCode}): ${response.body}");
    }
  }

  /// 🧪 Release Tester Code (on logout)
  static Future<void> releaseTesterCode(String code) async {
    final uri = Uri.parse("$_baseUrl/release_tester_code");
    await http.post(
      uri,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"code": code}),
    ).timeout(const Duration(seconds: 10));
  }
}
