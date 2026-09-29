/// SETUP: copy this file to `ai_config.dart` (same folder) and
/// put your key in. `ai_config.dart` is git-ignored — never commit it.
///
///   cp lib/config/ai_config_template.dart lib/config/ai_config.dart
///
/// Get a free key at https://aistudio.google.com/apikey
/// Run with: flutter run --dart-define=GEMINI_API_KEY=AIza...
import 'ai_defaults.dart';

class AIConfig {
  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: 'PASTE_YOUR_KEY_HERE',
  );

  static String get geminiModel => AiDefaults.primaryModel;

  static List<String> get geminiFallbackModels =>
      AiDefaults.fallbackModels;

  static String get geminiEndpoint => AiDefaults.endpointFor(
        geminiModel,
        geminiApiKey,
      );

  static String endpointFor(String model) =>
      AiDefaults.endpointFor(model, geminiApiKey);

  static String get geminiFallbackEndpoint =>
      endpointFor(geminiFallbackModels.first);

  static bool get hasGeminiKey =>
      geminiApiKey.isNotEmpty &&
      geminiApiKey != 'PASTE_YOUR_KEY_HERE';

  static const String missingKeyHint =
      'Gemini API key missing. Copy ai_config_template.dart to ai_config.dart, or re-run with --dart-define=GEMINI_API_KEY=YOUR_KEY (get one free at aistudio.google.com/apikey).';
}
