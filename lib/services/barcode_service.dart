// lib/services/barcode_service.dart
// Packaged-food lookup via Open Food Facts (name/brand only).
// Nutrition ALWAYS comes from our local DB (DB-strict rule):
// the OFF name is fuzzy-matched to a DB record, and logging
// happens through the normal text-search flow.
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/food_search_service.dart';

class BarcodeProduct {
  final String code;
  final String name;
  final String brand;
  const BarcodeProduct({
    required this.code,
    required this.name,
    required this.brand,
  });

  String get displayName =>
      brand.isEmpty ? name : '$name ($brand)';
}

class BarcodeService {
  static const _timeout = Duration(seconds: 15);

  /// Pure parser (unit-testable). Returns null when the payload
  /// has no usable product (status != 1 or blank name).
  static BarcodeProduct? parse(String code, Map<String, dynamic> json) {
    if (json['status'] != 1) return null;
    final p = json['product'];
    if (p is! Map<String, dynamic>) return null;
    final name = (p['product_name'] ?? '').toString().trim();
    if (name.isEmpty) return null;
    final brand = (p['brands'] ?? '').toString().trim();
    return BarcodeProduct(code: code, name: name, brand: brand);
  }

  /// Best local-DB hit for an OFF product name (null = no match).
  static FoodSearchHit? matchToDb(BarcodeProduct product) {
    final hits = FoodSearchService().search(product.name, limit: 1);
    return hits.isEmpty ? null : hits.first;
  }

  static Future<BarcodeProduct?> fetchProduct(String rawCode) async {
    final code = rawCode.trim().replaceAll(RegExp(r'\s+'), '');
    if (code.isEmpty) return null;
    try {
      final res = await http
          .get(
            Uri.parse(
                'https://world.openfoodfacts.org/api/v2/product/$code.json'),
            headers: {'User-Agent': 'HIW/1.0 (Health Is Wealth)'},
          )
          .timeout(_timeout);
      if (res.statusCode != 200) return null;
      final json = jsonDecode(res.body);
      if (json is! Map<String, dynamic>) return null;
      return parse(code, json);
    } catch (_) {
      return null;
    }
  }
}
