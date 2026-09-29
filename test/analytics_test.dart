import 'package:flutter_test/flutter_test.dart';
import 'package:hiw/services/analytics_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  test('allowlist holds counts-only events', () {
    for (final e in [
      'scan_success',
      'chat_sent',
      'paywall_open',
      'trial_start',
      'coupon_redeem'
    ]) {
      expect(AnalyticsService.allowed.contains(e), true);
    }
  });

  test('opt-out toggle persists', () async {
    final a = AnalyticsService();
    await a.setOptOut(true);
    expect(await a.isOptedOut(), true);
    await a.setOptOut(false);
    expect(await a.isOptedOut(), false);
  });

  test('unknown events are ignored', () async {
    final a = AnalyticsService();
    await a.setOptOut(false);
    await a.log('not_a_real_event');
    expect(await a.count('not_a_real_event'), 0);
  });
}
