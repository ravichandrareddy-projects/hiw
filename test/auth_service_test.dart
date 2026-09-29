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

  test('Register then OTP verify works', () async {
    final p = MockAuthProvider();
    await p.register('newuser@gmail.com', 'abcd');
    final u = await p.verifyOtp('newuser@gmail.com', '123456');
    expect(u.email, 'newuser@gmail.com');
    expect(
      () => p.verifyOtp('newuser@gmail.com', '000000'),
      throwsA(isA<AuthException>()),
    );
    expect(
      () => p.register('newuser@gmail.com', 'abcd'),
      throwsA(isA<AuthException>()),
    );
  });
}
