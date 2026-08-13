import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/ai_config.dart';

String get _geminiEndpoint => AIConfig.geminiEndpoint;


class RecognitionResult {
  final bool isFood;
  final String itemName;
  final double healthyScore;
  final bool isInDataset;
  final bool isNotFood;

  RecognitionResult({
    required this.isFood,
    required this.itemName,
    this.healthyScore = 85.0,
    required this.isInDataset,
    this.isNotFood = false,
  });
}

class FoodRecognitionService {
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

  /// Sends image to Gemini Vision API in background to detect food vs non-food & item name
  static Future<RecognitionResult> analyzeImage(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);

    final promptJson = {
      "contents": [
        {
          "parts": [
            {
              "text": "Analyze this image. First determine if the object is an edible food item or non-food (like a phone, laptop, book, pen, car, etc). Respond strictly in valid JSON format: {\"is_food\": true/false, \"item_name\": \"Simple concise name of item\"}"
            },
            {
              "inline_data": {
                "mime_type": "image/jpeg",
                "data": base64Image
              }
            }
          ]
        }
      ],
      "generationConfig": {
        "temperature": 0.1,
        "response_mime_type": "application/json"
      }
    };

    final response = await http.post(
      Uri.parse(_geminiEndpoint),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(promptJson),
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('API ${response.statusCode}: ${response.body}');
    }

    final data = jsonDecode(response.body);
    final String textResponse = data['candidates'][0]['content']['parts'][0]['text'];
    final parsed = jsonDecode(textResponse);

    final bool isFood = parsed['is_food'] ?? false;
    final String itemName = parsed['item_name'] ?? 'Unknown Item';
    final String nameLower = itemName.toLowerCase();

    if (!isFood) {
      return RecognitionResult(
        isFood: false,
        isNotFood: true,
        itemName: _formatName(itemName),
        isInDataset: false,
      );
    }

    // Check if food item matches local HIW dataset
    for (final foodKey in _foodDataset.keys) {
      if (nameLower.contains(foodKey) || foodKey.contains(nameLower)) {
        return RecognitionResult(
          isFood: true,
          itemName: _formatName(foodKey),
          healthyScore: _foodDataset[foodKey]!,
          isInDataset: true,
        );
      }
    }

    // Food recognized but not in dataset
    return RecognitionResult(
      isFood: true,
      itemName: _formatName(itemName),
      isInDataset: false,
    );
  }

  static String _formatName(String raw) {
    return raw
        .split(' ')
        .map((w) => w.isEmpty ? '' : w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }
}
