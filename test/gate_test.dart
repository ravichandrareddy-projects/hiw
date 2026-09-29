import 'package:flutter_test/flutter_test.dart';
import 'package:hiw/config/ai_defaults.dart';
import 'package:hiw/core/tester_gate.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  test('model defaults are the verified switch', () {
    expect(AiDefaults.primaryModel, 'gemini-3.1-flash-lite');
    expect(AiDefaults.fallbackModels,
        ['gemini-3.6-flash', 'gemini-3.8-flash']);
    expect(
        AiDefaults.endpointFor('m', 'k'),
        'https://generativelanguage.googleapis.com/v1beta/models/m:generateContent?key=k');
  });

  test('tester gate open in debug builds', () async {
    // flutter test runs with kDebugMode == true.
    expect(await TesterGate.isTesterMode(), true);
  });
}
