// lib/core/ai/ai_provider.dart
// Unified abstraction for AI Chat and Chart/Health insights.
// Decoupled from single-vendor hardcoding. Supports Gemini, OpenRouter/Nemotron, and Local/Mock fallbacks.
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../config/ai_config.dart';

abstract class ChatProvider {
  String get name;
  Future<String> ask(
    String question, {
    String? customSystemPrompt,
    Map<String, dynamic>? context,
  });
}

abstract class ChartInsightProvider {
  String get name;
  Future<String> getInsight({
    required Map<String, dynamic> chartData,
    String? userGoal,
  });
}

/// Google Gemini Implementation of ChatProvider
class GeminiChatProvider implements ChatProvider {
  @override
  String get name => 'Google Gemini';

  static const String _defaultPrompt =
      "You are Foodity, a specialized Food, Nutrition, and Health AI assistant for the HIW (Health Is Wealth) app. "
      "Your task is to provide helpful, professional, and friendly advice ONLY regarding food, nutrition, diet, meal planning, healthy eating, and general health.\n\n"
      "CRITICAL GUARDRAIL RULES:\n"
      "1. You must ONLY answer questions directly related to food, nutrition, recipes, diet, ingredients, food safety, healthy habits, and health/wellness.\n"
      "2. If the user asks about ANY topic outside of food, health, nutrition, or diet (such as sports, coding, movies, politics, general history, math, tech, etc.), you MUST decline politely with EXACTLY this message:\n"
      "\"I am Foodity, I am a food assistant. Sorry, I can't help you with that.\"\n"
      "3. Keep all answers clear, concise, accurate, and motivating.";

  @override
  Future<String> ask(
    String question, {
    String? customSystemPrompt,
    Map<String, dynamic>? context,
  }) async {
    const apiKey = AIConfig.geminiApiKey;
    if (apiKey.isEmpty) {
      return "⚠️ ${AIConfig.missingKeyHint}";
    }

    final url = Uri.parse(AIConfig.geminiEndpoint);
    final systemPrompt = customSystemPrompt ?? _defaultPrompt;

    // Optional context injection
    String enrichedQuestion = question;
    if (context != null && context.isNotEmpty) {
      enrichedQuestion = "[User Context: ${jsonEncode(context)}]\n$question";
    }

    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
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
                    {"text": enrichedQuestion}
                  ]
                }
              ],
              "generationConfig": {
                "temperature": 0.7,
                "maxOutputTokens": 1024,
              }
            }),
          )
          .timeout(const Duration(seconds: 25));

      if (response.statusCode == 401 || response.statusCode == 403) {
        return "⚠️ Invalid Gemini API Key or permissions error.";
      }
      if (response.statusCode == 429) {
        return "⏳ Foodity is receiving many requests. Please wait a moment and try again.";
      }
      if (response.statusCode != 200) {
        debugPrint("GEMINI ERROR (${response.statusCode}): ${response.body}");
        return "⚠️ Foodity is temporarily unavailable (${response.statusCode}).";
      }

      final data = jsonDecode(response.body);
      final candidates = data['candidates'] as List?;
      if (candidates != null && candidates.isNotEmpty) {
        final parts = candidates[0]['content']?['parts'] as List?;
        if (parts != null && parts.isNotEmpty) {
          final text = parts[0]['text']?.toString().trim();
          if (text != null && text.isNotEmpty) return text;
        }
      }
      return "🤔 Foodity could not format a reply.";
    } catch (e) {
      debugPrint("GEMINI EXCEPTION: $e");
      return "⚠️ Network or connection error to AI service.";
    }
  }
}

/// Generic OpenAI-compatible Chat Provider (OpenRouter, Nemotron, Mistral, Local LLMs)
class OpenAiCompatibleChatProvider implements ChatProvider {
  final String endpoint;
  final String apiKey;
  final String model;
  final String _providerName;

  OpenAiCompatibleChatProvider({
    required this.endpoint,
    required this.apiKey,
    required this.model,
    String providerName = 'OpenAI-Compatible',
  }) : _providerName = providerName;

  @override
  String get name => _providerName;

  @override
  Future<String> ask(
    String question, {
    String? customSystemPrompt,
    Map<String, dynamic>? context,
  }) async {
    if (apiKey.isEmpty) {
      return "⚠️ API Key not configured for $name.";
    }

    final systemPrompt = customSystemPrompt ??
        "You are Foodity, a food and nutrition health assistant in HIW app. Answer concisely and professionally.";

    final messages = [
      {"role": "system", "content": systemPrompt},
      if (context != null && context.isNotEmpty)
        {"role": "system", "content": "Context: ${jsonEncode(context)}"},
      {"role": "user", "content": question}
    ];

    try {
      final response = await http
          .post(
            Uri.parse(endpoint),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $apiKey',
            },
            body: jsonEncode({
              'model': model,
              'messages': messages,
              'temperature': 0.7,
              'max_tokens': 1024,
            }),
          )
          .timeout(const Duration(seconds: 25));

      if (response.statusCode != 200) {
        debugPrint("$name ERROR (${response.statusCode}): ${response.body}");
        return "⚠️ $name is temporarily unavailable (${response.statusCode}).";
      }

      final data = jsonDecode(response.body);
      final choices = data['choices'] as List?;
      if (choices != null && choices.isNotEmpty) {
        final content = choices[0]['message']?['content']?.toString().trim();
        if (content != null && content.isNotEmpty) return content;
      }
      return "🤔 $name returned an empty response.";
    } catch (e) {
      debugPrint("$name EXCEPTION: $e");
      return "⚠️ Connection error to $name.";
    }
  }
}

/// Deterministic Offline / Fallback Provider
class FallbackChatProvider implements ChatProvider {
  @override
  String get name => 'Offline Assistant';

  @override
  Future<String> ask(
    String question, {
    String? customSystemPrompt,
    Map<String, dynamic>? context,
  }) async {
    final lower = question.toLowerCase();
    if (lower.contains('water') || lower.contains('hydration')) {
      return "Staying hydrated supports digestion, metabolism, and sustained energy! Aim for 2.5 - 3.5 liters daily.";
    }
    if (lower.contains('protein')) {
      return "Protein preserves lean muscle mass and boosts satiety. Good sources include paneer, dal, sprouts, tofu, eggs, and lean chicken.";
    }
    if (lower.contains('calorie') || lower.contains('deficit')) {
      return "A moderate calorie deficit of 300-500 kcal is generally recommended for steady, sustainable fat loss.";
    }
    return "I am Foodity, your nutrition companion! You can track your meals, log water, and monitor daily macro balance on your dashboard.";
  }
}

/// Chart Insight Provider Implementation
class DefaultChartInsightProvider implements ChartInsightProvider {
  final ChatProvider _chatProvider;
  DefaultChartInsightProvider(this._chatProvider);

  @override
  String get name => 'HIW Chart Insights (${_chatProvider.name})';

  @override
  Future<String> getInsight({
    required Map<String, dynamic> chartData,
    String? userGoal,
  }) async {
    final prompt =
        "Analyze the following nutritional intake data and provide a 2-3 sentence actionable takeaway for the user.\n"
        "User Goal: ${userGoal ?? 'Balanced Health'}\n"
        "Data: ${jsonEncode(chartData)}";

    return _chatProvider.ask(
      prompt,
      customSystemPrompt:
          "You are a clinical nutrition data analyst. Be concise, direct, and motivating.",
    );
  }
}

/// Central AI Manager / Registry
class AiManager {
  static final AiManager _instance = AiManager._internal();
  factory AiManager() => _instance;
  AiManager._internal();

  ChatProvider _chatProvider = GeminiChatProvider();
  late ChartInsightProvider _chartInsightProvider =
      DefaultChartInsightProvider(_chatProvider);

  ChatProvider get chatProvider => _chatProvider;
  ChartInsightProvider get chartInsightProvider => _chartInsightProvider;

  void configureChatProvider(ChatProvider provider) {
    _chatProvider = provider;
    _chartInsightProvider = DefaultChartInsightProvider(provider);
  }
}
