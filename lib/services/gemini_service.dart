import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/ai_config.dart';

class GeminiService {
  static const String _defaultSystemPrompt = 
      "You are Foodity, a specialized Food, Nutrition, and Health AI assistant for the HIW (Health Is Wealth) app. "
      "Your task is to provide helpful, professional, and friendly advice ONLY regarding food, nutrition, diet, meal planning, healthy eating, and general health.\n\n"
      "CRITICAL GUARDRAIL RULES:\n"
      "1. You must ONLY answer questions directly related to food, nutrition, recipes, diet, ingredients, food safety, healthy habits, and health/wellness.\n"
      "2. If the user asks about ANY topic outside of food, health, nutrition, or diet (such as sports, coding, movies, politics, general history, math, tech, etc.), you MUST decline politely with EXACTLY this message:\n"
      "\"I am Foodity, I am a food assistant. Sorry, I can't help you with that.\"\n"
      "3. Keep all answers clear, concise, accurate, and motivating.";

  /// Send prompt to Gemini API for Foodity chat answers
  static Future<String> ask(String question, {String? customSystemPrompt}) async {
    final apiKey = AIConfig.geminiApiKey;
    if (apiKey.isEmpty) {
      return "⚠️ Gemini API Key not found! Please configure it in AIConfig.dart";
    }

    final url = Uri.parse(AIConfig.geminiEndpoint);
    final String systemPrompt = customSystemPrompt ?? _defaultSystemPrompt;

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "system_instruction": {
            "parts": [
              {"text": systemPrompt}
            ]
          },
          "contents": [
            {
              "role": "user",
              "parts": [
                {"text": question}
              ]
            }
          ],
          "generationConfig": {
            "temperature": 0.7,
            "maxOutputTokens": 1024,
          }
        }),
      ).timeout(
        const Duration(seconds: 25),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      if (response.statusCode == 401 || response.statusCode == 403) {
        return "⚠️ Invalid Gemini API Key or permissions error. Check key in settings.";
      }

      if (response.statusCode != 200) {
        print("GEMINI ERROR (${response.statusCode}): ${response.body}");
        return "⚠️ Foodity is temporarily unavailable. Error ${response.statusCode}.";
      }

      final data = jsonDecode(response.body);
      final candidates = data['candidates'] as List?;
      if (candidates != null && candidates.isNotEmpty) {
        final parts = candidates[0]['content']?['parts'] as List?;
        if (parts != null && parts.isNotEmpty) {
          final text = parts[0]['text']?.toString().trim();
          if (text != null && text.isNotEmpty) {
            return text;
          }
        }
      }

      return "🤔 Foodity is thinking, but couldn't process the response.";

    } catch (e) {
      print("GEMINI EXCEPTION: $e");
      return "⚠️ Connection error to Gemini Cloud.";
    }
  }
}
