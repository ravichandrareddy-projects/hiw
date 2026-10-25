import 'package:flutter_test/flutter_test.dart';
import 'package:hiw/core/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  test('Email validation', () {
    expect(AuthService.validEmail('user1@gmail.com'), true);
    expect(AuthService.validEmail('bad'), false);
    expect(AuthService.validEmail('a@b'), false);
    expect(AuthService.validEmail('  user@x.io  '), true);
  });

  test('Password rules', () {
    expect(AuthService.passwordError('123'), isNotNull);
    expect(AuthService.passwordError('1234'), isNull);
  });

  test('Seeded test user logs in', () async {
    final u = await MockAuthProvider()
        .login('user1@gmail.com', '1234');
    expect(u.email, 'user1@gmail.com');
  });

  test('Wrong password + unknown email fail cleanly', () async {
    expect(
      () => MockAuthProvider().login('user1@gmail.com', 'nope'),
      throwsA(isA<AuthException>()),
    );
    expect(
      () => MockAuthProvider().login('nobody@x.io', '1234'),
      throwsA(isA<AuthException>()),
    );
  });

  test('Register directly returns AuthUser without OTP', () async {
    final p = MockAuthProvider();
    final u = await p.register('newuser@gmail.com', 'abcd', username: 'Alex');
    expect(u.email, 'newuser@gmail.com');
    expect(u.username, 'Alex');
    // Can login directly
    final loggedIn = await p.login('newuser@gmail.com', 'abcd');
    expect(loggedIn.email, 'newuser@gmail.com');
    expect(
      () => p.register('newuser@gmail.com', 'abcd'),
      throwsA(isA<AuthException>()),
    );
  });

  test('Google sign-in works cleanly', () async {
    final p = MockAuthProvider();
    final u = await p.signInWithGoogle();
    expect(u.email, 'google_user@gmail.com');
    expect(u.username, 'Google User');
  });

  test('Passwords stored hashed, never plaintext', () async {
    final p = MockAuthProvider();
    await p.register('hashme@gmail.com', 'secret123');
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('mock_auth_users') ?? '';
    expect(raw.contains('secret123'), false);
    expect(raw.contains('v1\$'), true);
    // Login still works against the hash.
    final u = await p.login('hashme@gmail.com', 'secret123');
    expect(u.email, 'hashme@gmail.com');
    expect(
      () => p.login('hashme@gmail.com', 'wrong'),
      throwsA(isA<AuthException>()),
    );
  });

  test('Legacy plaintext entries upgrade on login', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'mock_auth_users', '{"legacy@gmail.com":"plainpw"}');
    final u =
        await MockAuthProvider().login('legacy@gmail.com', 'plainpw');
    expect(u.email, 'legacy@gmail.com');
    final raw = prefs.getString('mock_auth_users') ?? '';
    expect(raw.contains('plainpw'), false);
  });
}
