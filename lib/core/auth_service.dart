// lib/core/auth_service.dart
// Auth abstraction: mock provider by default; Supabase provider
// activates when --dart-define SUPABASE_URL/ANON_KEY are supplied
// (see backend_config.dart). UI talks ONLY to AuthService.
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../config/backend_config.dart';

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
  Future<AuthUser> register(String email, String password, {String? username});
  Future<AuthUser> signInWithGoogle();
  Future<void> sendPasswordReset(String email);
  Future<void> updatePassword(String newPassword);
  Future<void> logout();
}

/// Mock provider for UI development. Seeded test account:
/// user1@gmail.com / 1234. Registered accounts persist per device.
/// Passwords are stored as salted SHA-256 (never plaintext);
/// legacy plaintext entries auto-upgrade on next successful login.
/// OTP is always 123456 (clearly mock — Supabase Auth replaces this).
class MockAuthProvider implements AuthProvider {
  static const _usersKey = 'mock_auth_users';
  static const testEmail = 'user1@gmail.com';
  static const testPassword = '1234';

  static String _hash(String salt, String password) =>
      sha256.convert(utf8.encode('$salt:$password')).toString();

  static String _newEntry(String password) {
    final salt = List.generate(
      16,
      (_) => 'abcdefghijklmnopqrstuvwxyz0123456789'[
          Random.secure().nextInt(36)],
    ).join();
    return 'v1\$$salt\$${_hash(salt, password)}';
  }

  /// True when [stored] authorizes [password] (v1 hash or legacy plain).
  static bool _check(String stored, String password) {
    final parts = stored.split('\$');
    if (parts.length == 3 && parts[0] == 'v1') {
      return _hash(parts[1], password) == parts[2];
    }
    return stored == password; // legacy plaintext → upgraded on login
  }

  Future<Map<String, String>> _users() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_usersKey);
    final map = <String, String>{testEmail: _newEntry(testPassword)};
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
    if (!_check(stored, password)) {
      throw AuthException('Wrong password. Try again.');
    }
    // Silent upgrade: legacy plaintext → salted hash.
    if (!stored.contains('\$')) {
      users[email.trim().toLowerCase()] = _newEntry(password);
      await _saveUsers(users);
    }
    return AuthUser(
      email: email.trim().toLowerCase(),
      username: _defaultName(email),
    );
  }

  @override
  Future<AuthUser> register(String email, String password, {String? username}) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final users = await _users();
    final key = email.trim().toLowerCase();
    if (users.containsKey(key)) {
      throw AuthException('Account exists. Try Login.');
    }
    users[key] = _newEntry(password);
    await _saveUsers(users);
    final user = AuthUser(
      email: key,
      username: (username != null && username.trim().isNotEmpty)
          ? username.trim()
          : _defaultName(key),
    );
    return user;
  }

  @override
  Future<AuthUser> signInWithGoogle() async {
    await Future.delayed(const Duration(milliseconds: 500));
    const googleEmail = 'google_user@gmail.com';
    final users = await _users();
    if (!users.containsKey(googleEmail)) {
      users[googleEmail] = _newEntry('google_oauth_mock_pwd');
      await _saveUsers(users);
    }
    return const AuthUser(
      email: googleEmail,
      username: 'Google User',
    );
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final users = await _users();
    if (!users.containsKey(email.trim().toLowerCase())) {
      throw AuthException('No account found for this email.');
    }
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    await Future.delayed(const Duration(milliseconds: 400));
    if (newPassword.length < 4) {
      throw AuthException('Password must be at least 4 characters.');
    }
  }

  @override
  Future<void> logout() async {}

  String _defaultName(String email) {
    final local = email.split('@').first;
    if (local.isEmpty) return 'User';
    return local[0].toUpperCase() + local.substring(1);
  }
}

/// Real Supabase Auth. Active only when BackendConfig.hasSupabase;
/// otherwise every call fails cleanly with AuthException (mock stays).
class SupabaseAuthProvider implements AuthProvider {
  sb.SupabaseClient get _client {
    if (!BackendConfig.hasSupabase) {
      throw AuthException(
          'Cloud login not configured on this build. Use the demo account.');
    }
    return sb.Supabase.instance.client;
  }

  AuthUser _toUser(String email, [String? username]) => AuthUser(
        email: email.trim().toLowerCase(),
        username: (username != null && username.isNotEmpty)
            ? username
            : _defaultName(email),
      );

  Never _wrap(Object e) {
    if (e is AuthException) throw e;
    if (e is sb.AuthException) throw AuthException(e.message);
    throw AuthException('Operation failed. Check connection and retry.');
  }

  @override
  Future<AuthUser> login(String email, String password) async {
    try {
      final res = await _client.auth.signInWithPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );
      final userEmail = res.user?.email ?? email;
      final name = res.user?.userMetadata?['full_name'] as String?;
      return _toUser(userEmail, name);
    } catch (e) {
      _wrap(e);
    }
  }

  @override
  Future<AuthUser> register(String email, String password, {String? username}) async {
    if (password.length < 6) {
      throw AuthException(
          'Cloud accounts need at least 6 characters.');
    }
    try {
      final res = await _client.auth.signUp(
        email: email.trim().toLowerCase(),
        password: password,
        data: (username != null && username.isNotEmpty)
            ? {'full_name': username}
            : null,
      );
      final user = res.user;
      final userEmail = user?.email ?? email;
      final name = user?.userMetadata?['full_name'] as String? ?? username;
      return _toUser(userEmail, name);
    } catch (e) {
      _wrap(e);
    }
  }

  @override
  Future<AuthUser> signInWithGoogle() async {
    try {
      final launched = await _client.auth.signInWithOAuth(
        sb.OAuthProvider.google,
        redirectTo: 'io.supabase.hiw://login-callback',
      );
      if (!launched) {
        throw AuthException('Could not launch Google Sign-In.');
      }
      final user = _client.auth.currentUser;
      final userEmail = user?.email ?? 'google.user@hiw.app';
      final name = user?.userMetadata?['full_name'] as String?;
      return _toUser(userEmail, name);
    } catch (e) {
      _wrap(e);
    }
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(
        email.trim().toLowerCase(),
        redirectTo: 'io.supabase.hiw://reset-callback',
      );
    } catch (e) {
      _wrap(e);
    }
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    if (newPassword.length < 6) {
      throw AuthException('Password must be at least 6 characters.');
    }
    try {
      await _client.auth.updateUser(sb.UserAttributes(password: newPassword));
    } catch (e) {
      _wrap(e);
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _client.auth.signOut();
    } catch (_) {}
  }

  String _defaultName(String email) {
    final local = email.split('@').first;
    if (local.isEmpty) return 'User';
    return local[0].toUpperCase() + local.substring(1);
  }
}

class AuthService {
  static final AuthService _i = AuthService._internal();
  factory AuthService() => _i;
  AuthService._internal();

  AuthProvider _provider = MockAuthProvider();

  /// Swap to SupabaseAuthProvider() when BackendConfig.hasSupabase.
  /// UI never changes.
  void useProvider(AuthProvider p) => _provider = p;

  Future<AuthUser> login(String email, String password) =>
      _provider.login(email, password);

  Future<AuthUser> register(String email, String password, {String? username}) =>
      _provider.register(email, password, username: username);

  Future<AuthUser> signInWithGoogle() =>
      _provider.signInWithGoogle();

  Future<void> sendPasswordReset(String email) =>
      _provider.sendPasswordReset(email);

  Future<void> updatePassword(String newPassword) =>
      _provider.updatePassword(newPassword);

  Future<void> logout() => _provider.logout();

  static bool validEmail(String v) => RegExp(
        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
      ).hasMatch(v.trim());

  static String? passwordError(String v) {
    if (v.length < 4) return 'At least 4 characters.';
    return null;
  }
}

/// One-time Supabase init + provider swap. Safe to call unconfigured
/// (no-op, mock stays). Called from HIWBootApp._boot.
Future<void> ensureSupabaseAuth() async {
  if (!BackendConfig.hasSupabase) return;
  try {
    await sb.Supabase.initialize(
      url: BackendConfig.supabaseUrl,
      publishableKey: BackendConfig.supabaseAnonKey,
    );
    AuthService().useProvider(SupabaseAuthProvider());
  } catch (_) {
    // Cloud auth stays off; mock continues. Never crash boot.
  }
}
