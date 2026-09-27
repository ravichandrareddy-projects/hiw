import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import '../config/ai_config.dart';
import '../core/food_nutrition_database.dart';

String get _geminiEndpoint => AIConfig.geminiEndpoint;

class ScannedItem {
  final String name;
  final double quantity;
  final bool isEdible;
  final double healthyScore;
  final FoodNutritionRecord? record;

  bool get isInDataset => record != null;

  ScannedItem({
    required this.name,
    this.quantity = 1.0,
    this.isEdible = true,
    this.healthyScore = 85.0,
    this.record,
  });
}

class RecognitionResult {
  final bool isFood;
  final String itemName;
  final double healthyScore;
  final bool isInDataset;
  final bool isNotFood;
  final double estimatedQuantity; // e.g. 1.0 (1 serving), 1.5, 2.0
  final String? servingUnit;
  final FoodNutritionRecord? nutritionRecord;

  /// Every distinct item the AI saw (foods + non-food objects).
  final List<ScannedItem> items;

  /// Only the edible ones.
  List<ScannedItem> get edibleItems =>
      items.where((i) => i.isEdible).toList();

  RecognitionResult({
    required this.isFood,
    required this.itemName,
    this.healthyScore = 85.0,
    required this.isInDataset,
    this.isNotFood = false,
    this.estimatedQuantity = 1.0,
    this.servingUnit,
    this.nutritionRecord,
    this.items = const [],
  });
}

class FoodRecognitionService {
  /// Shared HTTP client so TLS/connection setup is reused (keep-alive).
  static final http.Client _client = http.Client();

  // ─── HIW Food Dataset (expandable index) ───
  static final Map<String, double> _foodDataset = {
    'apple': 95.0,
    'banana': 90.0,
    'salad': 98.0,
    'green salad': 98.0,
    'pizza': 45.0,
    'burger': 40.0,
    'hamburger': 40.0,
    'rice': 80.0,
    'fried rice': 72.0,
    'chicken': 88.0,
    'grilled chicken': 92.0,
    'soup': 92.0,
    'orange': 94.0,
    'bread': 75.0,
    'sandwich': 70.0,
    'pasta': 72.0,
    'noodles': 68.0,
    'egg': 85.0,
    'omelette': 83.0,
    'mango': 88.0,
    'watermelon': 92.0,
    'grapes': 90.0,
    'strawberry': 93.0,
    'carrot': 96.0,
    'broccoli': 97.0,
    'tomato': 91.0,
    'onion': 85.0,
    'potato': 78.0,
    'fish': 89.0,
    'milk': 82.0,
    'yogurt': 88.0,
    'cheese': 65.0,
    'cake': 30.0,
    'chocolate': 35.0,
    'ice cream': 28.0,
    'donut': 25.0,
    'cookie': 32.0,
    'idli': 85.0,
    'dosa': 78.0,
    'biryani': 55.0,
    'dal': 88.0,
    'paneer': 72.0,
    'samosa': 38.0,
    'parotta': 45.0,
    'chapati': 80.0,
    'roti': 80.0,
    'upma': 82.0,
    'poha': 84.0,
  };

  /// Sends image to Gemini Vision API in background to detect food vs non-food, item name & quantity
  static Future<RecognitionResult> analyzeImage(File imageFile) async {
    if (!AIConfig.hasGeminiKey) {
      throw Exception(AIConfig.missingKeyHint);
    }

    final bytes = await _prepareImageBytes(imageFile);
    final base64Image = base64Encode(bytes);

    final promptJson = {
      "contents": [
        {
          "parts": [
            {
              "text": "You are a food-scanning assistant. Look at this photo. List EVERY distinct edible food item visible (examples: Dosa, Coconut Chutney, Sambar, Rice, Chicken Curry, Apple). Ignore plates, cutlery, glasses, tables and packaging — only edible foods. If the photo contains no food at all, identify the single main non-food object instead (examples: Computer Mouse, Laptop, Book). For each food item estimate its portion quantity relative to its standard single serving (1.0 = standard single serving, 0.5 = half portion, 1.5 = generous portion, 2.0 = double); use 0 for non-food objects. Always give concrete names, never null, never 'unknown'. Respond strictly in valid JSON with exactly this shape: {\"items\": [{\"name\": \"Masala Dosa\", \"is_edible\": true, \"quantity\": 1.0}]}"
            },
            {
              "inlineData": {
                "mimeType": "image/jpeg",
                "data": base64Image
              }
            }
          ]
        }
      ],
      "generationConfig": {
        "temperature": 0.1,
        "responseMimeType": "application/json"
      }
    };

    // Single attempt, shared keep-alive client. No silent retry loop:
    // on slow networks a retry only doubles the wait. Manual RETRY
    // button in the UI reuses the warm connection instead.
    late http.Response response;
    try {
      response = await _client
          .post(
            Uri.parse(_geminiEndpoint),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(promptJson),
          )
          .timeout(const Duration(seconds: 25));
    } on Exception catch (e) {
      throw Exception(
          'Vision service unreachable (check internet and retry): $e');
    }

    if (response.statusCode == 400) {
      throw Exception('Vision request rejected (400). ${response.body}');
    } else if (response.statusCode == 401 || response.statusCode == 403) {
      throw Exception(
          'Vision API key invalid or lacks access (HTTP ${response.statusCode}). Create a fresh key at aistudio.google.com/apikey and re-run with --dart-define=GEMINI_API_KEY=YOUR_KEY.');
    } else if (response.statusCode == 404) {
      throw Exception(
          'Vision model "${AIConfig.geminiModel}" not found (404). Update AIConfig.geminiModel to a current model.');
    } else if (response.statusCode == 429) {
      throw Exception(
          'Vision quota exceeded (429). Wait a minute and retry, or enable billing on your API key.');
    } else if (response.statusCode != 200) {
      throw Exception('API ${response.statusCode}: ${response.body}');
    }

    final data = jsonDecode(response.body);
    final candidates = data['candidates'] as List?;
    String? textResponse;
    if (candidates != null && candidates.isNotEmpty) {
      final content = candidates[0]['content'] as Map?;
      final parts = content?['parts'] as List?;
      if (parts != null && parts.isNotEmpty) {
        final first = parts[0] as Map?;
        textResponse = first?['text']?.toString();
      }
    }
    if (textResponse == null || textResponse.isEmpty) {
      throw Exception(
          'Vision returned no result (safety block or empty response): ${response.body}');
    }
    final parsed = jsonDecode(textResponse);

    // ── Parse the items array (new format), legacy single-object fallback ──
    final rawItems = parsed['items'] as List?;
    final List<Map<String, dynamic>> itemMaps;
    if (rawItems != null && rawItems.isNotEmpty) {
      itemMaps = rawItems
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .toList();
    } else {
      itemMaps = [
        {
          'name': parsed['item_name'] ?? 'Unknown Item',
          'is_edible': parsed['is_food'] ?? false,
          'quantity': parsed['estimated_quantity'] ?? 1.0,
        }
      ];
    }

    final scanned = itemMaps.map((m) {
      final rawName = (m['name']?.toString() ?? '').trim();
      // Clamp wild AI quantities (e.g. "5 plates" → max 3) so one scan
      // can never log absurd calories. Fine-tune with the portion stepper.
      final qty =
          ((m['quantity'] as num?)?.toDouble() ?? 1.0).clamp(0.25, 3.0);
      return _matchItem(
        rawName.isEmpty ? 'Unknown Item' : rawName,
        qty,
        m['is_edible'] is bool ? m['is_edible'] as bool : true,
      );
    }).toList();

    final edible = scanned.where((i) => i.isEdible).toList();
    if (edible.isEmpty) {
      // Nothing edible — show the detected object (mouse, book, …).
      return RecognitionResult(
        isFood: false,
        isNotFood: true,
        itemName: _formatName(scanned.first.name),
        isInDataset: false,
        items: scanned,
      );
    }

    // One or more foods (dosa + chutney + sambar …). Primary = first edible.
    final primary = edible.first;
    FoodNutritionRecord? primaryRecord;
    for (final e in edible) {
      if (e.record != null) {
        primaryRecord = e.record;
        break;
      }
    }

    return RecognitionResult(
      isFood: true,
      itemName: _formatName(primary.name),
      healthyScore: primary.healthyScore,
      isInDataset: edible.any((e) => e.isInDataset),
      estimatedQuantity: primary.quantity,
      servingUnit: primaryRecord?.servingUnit,
      nutritionRecord: primaryRecord,
      items: scanned,
    );
  }

  /// Matches one detected name against the 2.6k nutrition database,
  /// then the legacy dataset, else returns it as a custom/new food.
  static ScannedItem _matchItem(String name, double quantity, bool isEdible) {
    if (!isEdible) {
      return ScannedItem(name: name, quantity: 0, isEdible: false);
    }

    // 1. Check against the comprehensive 2.6k food nutrition database
    final dbMatch = FoodNutritionDatabase().findMatch(name);
    if (dbMatch != null) {
      return ScannedItem(
        name: dbMatch.name,
        quantity: quantity,
        healthyScore: dbMatch.healthyScore,
        record: dbMatch,
      );
    }

    // 2. Check fallback legacy dataset
    final nameLower = name.toLowerCase();
    for (final foodKey in _foodDataset.keys) {
      if (nameLower.contains(foodKey) || foodKey.contains(nameLower)) {
        return ScannedItem(
          name: _formatName(foodKey),
          quantity: quantity,
          healthyScore: _foodDataset[foodKey]!,
        );
      }
    }

    // 3. Food recognized but custom/new
    return ScannedItem(name: _formatName(name), quantity: quantity);
  }

  /// Downscales camera photos (often 12MP+) to max 768px JPEG so uploads
  /// stay small and fast on slow mobile networks (~70KB vs ~300KB).
  /// Plenty of detail for food recognition; original is never touched.
  /// Heavy decode/resize runs in an isolate — never on the UI thread.
  static Future<List<int>> _prepareImageBytes(File imageFile) async {
    try {
      final original = await imageFile.readAsBytes();
      return await compute(_encodeUploadBytes, original);
    } catch (_) {
      return imageFile.readAsBytes();
    }
  }

  static String _formatName(String raw) {
    return raw
        .split(' ')
        .map((w) => w.isEmpty ? '' : w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }
}

/// Isolate entry: decode + downscale + JPEG-encode the upload copy.
/// Top-level so [compute] can run it off the UI thread.
List<int> _encodeUploadBytes(Uint8List original) {
  try {
    final decoded = img.decodeImage(original);
    if (decoded == null) return original;
    const maxSide = 768;
    final largest = decoded.width > decoded.height
        ? decoded.width
        : decoded.height;
    if (largest <= maxSide) return original;
    final resized = img.copyResize(
      decoded,
      width: decoded.width >= decoded.height ? maxSide : null,
      height: decoded.height > decoded.width ? maxSide : null,
    );
    final out = img.encodeJpg(resized, quality: 80);
    debugPrint(
        'HIW VISION: captured ${decoded.width}x${decoded.height} (${original.length ~/ 1024}KB) upload ${out.length ~/ 1024}KB');
    return out;
  } catch (_) {
    return original;
  }
}
