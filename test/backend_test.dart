import 'package:flutter_test/flutter_test.dart';
import 'package:hiw/config/backend_config.dart';
import 'package:hiw/core/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  test('cloud auth off by default (no dart-defines)', () {
    expect(BackendConfig.hasSupabase, false);
  });

  test('supabase provider fails cleanly when unconfigured', () async {
    final p = SupabaseAuthProvider();
    expect(() => p.login('a@b.io', '1234'),
        throwsA(isA<AuthException>()));
    expect(() => p.register('a@b.io', '1234'),
        throwsA(isA<AuthException>()));
    expect(() => p.signInWithGoogle(),
        throwsA(isA<AuthException>()));
  });

  test('ensureSupabaseAuth is a safe no-op unconfigured', () async {
    await ensureSupabaseAuth();
    // Mock still active: unknown email fails with mock message.
    expect(() => AuthService().login('nobody@x.io', '1234'),
        throwsA(predicate((e) =>
            e is AuthException &&
            e.message.contains('No account'))));
  });
}
