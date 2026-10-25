// lib/config/backend_config.dart
// Tracked backend wiring. Secrets come ONLY from --dart-define
// (never hardcoded), so this file is clone-safe:
//
//   flutter run \
//     --dart-define=SUPABASE_URL=https://xyz.supabase.co \
//     --dart-define=SUPABASE_ANON_KEY=sb_publishable_... (publishable key)
//
// Until those are supplied, [hasSupabase] is false and the app
// stays on MockAuthProvider (zero UI churn — see auth_service.dart).
class BackendConfig {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  static bool get hasSupabase =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  /// Feature flag: Temporarily disable Mood Checker entry points & auto-scheduler.
  static const bool moodCheckerEnabled = false;
}
