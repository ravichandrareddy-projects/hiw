import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/ai_config.dart';

/// Dedicated service for mood check interactions with empathetic responses using Gemini API
class MoodService {
  /// Ask mood check question with empathetic, supportive responses
  static Future<String> askMoodCheck(String userMessage) async {
    const apiKey = AIConfig.geminiApiKey;

    if (apiKey.isEmpty) {
      return "⚠️ ${AIConfig.missingKeyHint}";
    }

    return _makeRequest(userMessage);
  }

  static Future<String> _makeRequest(String message) async {
    final url = Uri.parse(AIConfig.geminiEndpoint);

    try {
      final response = await http
          .post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "system_instruction": {
            "parts": [
              {
                "text": "You are a wise and comforting emotional support AI for the HIW (Health Is Wealth) app. "
                    "Your goal is to provide immediate, simple comfort and practical remedies.\n\n"
                    "Guidelines:\n"
                    "1. Warmly validate the user's feelings.\n"
                    "2. Ask a gentle, empathetic question to understand WHY they are feeling this way or what exactly is bothering them.\n"
                    "3. Do NOT just jump straight into giving suggestions or remedies without first understanding their situation and the context.\n"
                    "4. Keep the entire response empathetic, conversational, and concise.\n"
                    "5. Once you understand the specific situation from their replies, you can then suggest 1-2 small, practical steps."
              }
            ]
          },
          "contents": [
            {
              "role": "user",
              "parts": [
                {"text": message}
              ]
            }
          ],
          "generationConfig": {
            "temperature": 0.8,
            "maxOutputTokens": 512,
          }
        }),
      )
          .timeout(
        const Duration(seconds: 25),
        onTimeout: () {
          debugPrint('⚠️ MOOD SERVICE: HTTP request timeout');
          throw Exception('Request timeout');
        },
      );

      if (response.statusCode == 401 || response.statusCode == 403) {
        return "⚠️ Invalid Mood Check API Key. Please check your key in AIConfig.dart";
      }

      if (response.statusCode != 200) {
        debugPrint("MOOD SERVICE ERROR: ${response.statusCode}");
        debugPrint("BODY: ${response.body}");
        return "⚠️ Mood support is temporarily unavailable. Error ${response.statusCode}.";
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

      return "I'm here for you. How can I help? 💙";
    } catch (e) {
      debugPrint("MOOD SERVICE EXCEPTION: $e");
      return "⚠️ Connection error. Please try again.";
    }
  }
}
