/// Tracked model defaults for all Gemini AI calls.
///
/// This file is the clone-safe source of MODEL NAMES + endpoint builders.
/// The API KEY lives only in the git-ignored `ai_config.dart`
/// (see `ai_config_template.dart` for setup). Copying this file to a
/// fresh clone preserves the verified model switch without leaking keys.
///
/// Verified live 2026-09-15: primary `gemini-3.1-flash-lite`,
/// fallbacks `gemini-3.6-flash`, `gemini-3.8-flash`
/// (1.5-flash retired; 2.5-flash-lite closed to new keys).
class AiDefaults {
  static const String primaryModel = 'gemini-3.1-flash-lite';

  static const List<String> fallbackModels = [
    'gemini-3.6-flash',
    'gemini-3.8-flash',
  ];

  static String endpointFor(String model, String apiKey) =>
      'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey';
}
