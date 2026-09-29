// lib/core/auth_service.dart
// Auth abstraction: mock provider today (Supabase swap at the end).
// UI talks ONLY to AuthService — providers are interchangeable.
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AuthUser {
  final String email;
  final String username;
  const AuthUser({required this.email, required this.username});
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}

abstract class AuthProvider {
  Future<AuthUser> login(String email, String password);
  Future<void> register(String email, String password);
  Future<AuthUser> verifyOtp(String email, String code);
  Future<void> logout();
}

/// Mock provider for UI development. Seeded test account:
/// user1@gmail.com / 1234. Registered accounts persist per device.
/// OTP is always 123456 (clearly mock — Supabase Auth replaces this).
class MockAuthProvider implements AuthProvider {
  static const _usersKey = 'mock_auth_users';
  static const _otpKey = 'mock_auth_otp';
  static const testEmail = 'user1@gmail.com';
  static const testPassword = '1234';
  static const mockOtp = '123456';

  Future<Map<String, String>> _users() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_usersKey);
    final map = <String, String>{testEmail: testPassword};
    if (raw != null) {
      try {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        for (final e in decoded.entries) {
          if (e.value is String) map[e.key] = e.value as String;
        }
      } catch (_) {}
    }
    return map;
  }

  Future<void> _saveUsers(Map<String, String> users) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_usersKey, jsonEncode(users));
  }

  @override
  Future<AuthUser> login(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final users = await _users();
    final stored = users[email.trim().toLowerCase()];
    if (stored == null) {
      throw AuthException('No account for this email. Try Register.');
    }
    if (stored != password) {
      throw AuthException('Wrong password. Try again.');
    }
    return AuthUser(
      email: email.trim().toLowerCase(),
      username: _defaultName(email),
    );
  }

  @override
  Future<void> register(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final users = await _users();
    final key = email.trim().toLowerCase();
    if (users.containsKey(key)) {
      throw AuthException('Account exists. Try Login.');
    }
    users[key] = password;
    await _saveUsers(users);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_otpKey, mockOtp);
  }

  @override
  Future<AuthUser> verifyOtp(String email, String code) async {
    await Future.delayed(const Duration(milliseconds: 400));
    if (code.trim() != mockOtp) {
      throw AuthException('Wrong code. Hint: 123456 (demo).');
    }
    return AuthUser(
      email: email.trim().toLowerCase(),
      username: _defaultName(email),
    );
  }

  @override
  Future<void> logout() async {}

  String _defaultName(String email) {
    final local = email.split('@').first;
    if (local.isEmpty) return 'User';
    return local[0].toUpperCase() + local.substring(1);
  }
}

/// Supabase Auth plugs in here at the end (same interface, zero UI churn).
class SupabaseAuthProvider implements AuthProvider {
  @override
  Future<AuthUser> login(String email, String password) =>
      throw UnimplementedError('Supabase wiring lands at the end.');

  @override
  Future<void> register(String email, String password) =>
      throw UnimplementedError('Supabase wiring lands at the end.');

  @override
  Future<AuthUser> verifyOtp(String email, String code) =>
      throw UnimplementedError('Supabase wiring lands at the end.');

  @override
  Future<void> logout() async {}
}

class AuthService {
  static final AuthService _i = AuthService._internal();
  factory AuthService() => _i;
  AuthService._internal();

  AuthProvider _provider = MockAuthProvider();

  /// Swap to SupabaseAuthProvider() at the end. UI never changes.
  void useProvider(AuthProvider p) => _provider = p;

  Future<AuthUser> login(String email, String password) =>
      _provider.login(email, password);

  Future<void> register(String email, String password) =>
      _provider.register(email, password);

  Future<AuthUser> verifyOtp(String email, String code) =>
      _provider.verifyOtp(email, code);

  Future<void> logout() => _provider.logout();

  static bool validEmail(String v) => RegExp(
        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
      ).hasMatch(v.trim());

  static String? passwordError(String v) {
    if (v.length < 4) return 'At least 4 characters.';
    return null;
  }
}
