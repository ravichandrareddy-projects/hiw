import 'package:flutter_test/flutter_test.dart';
import 'package:hiw/core/subscription/coupon_service.dart';

void main() {
  const valid = {'HIW-PRO-TEST-001'};

  test('normalize is case/space insensitive', () {
    expect(CouponService.normalize('  hiw-pro-test-001 '),
        'HIW-PRO-TEST-001');
  });

  test('empty code rejected', () {
    expect(CouponService.validate('   ', valid, {}),
        CouponResult.empty);
  });

  test('unknown code invalid', () {
    expect(CouponService.validate('NOPE-123', valid, {}),
        CouponResult.invalid);
  });

  test('valid code passes', () {
    expect(CouponService.validate('hiw-pro-test-001', valid, {}),
        CouponResult.ok);
  });

  test('double redeem blocked', () {
    expect(
        CouponService.validate(
            'HIW-PRO-TEST-001', valid, {'HIW-PRO-TEST-001'}),
        CouponResult.alreadyRedeemed);
  });
}
