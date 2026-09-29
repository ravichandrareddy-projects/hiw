import 'package:flutter_test/flutter_test.dart';
import 'package:hiw/services/barcode_service.dart';

void main() {
  test('parse returns null when product missing', () {
    expect(BarcodeService.parse('123', {'status': 0}), isNull);
    expect(BarcodeService.parse('123', {'status': 1}), isNull);
    expect(
        BarcodeService.parse('123', {
          'status': 1,
          'product': {'product_name': '  ', 'brands': 'X'}
        }),
        isNull);
  });

  test('parse extracts name + brand', () {
    final p = BarcodeService.parse('890123', {
      'status': 1,
      'product': {'product_name': 'Mango Juice', 'brands': 'Acme'}
    });
    expect(p, isNotNull);
    expect(p!.code, '890123');
    expect(p.name, 'Mango Juice');
    expect(p.displayName, 'Mango Juice (Acme)');
  });

  test('parse tolerates missing brand', () {
    final p = BarcodeService.parse('890123', {
      'status': 1,
      'product': {'product_name': 'Oats'}
    });
    expect(p, isNotNull);
    expect(p!.displayName, 'Oats');
  });

  test('fetch rejects blank codes without network', () async {
    expect(await BarcodeService.fetchProduct('   '), isNull);
  });
}
