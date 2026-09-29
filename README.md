# HIW – Health Is Wealth

Freemium health app (Flutter): food scanner, onboarding + goals, habits, fasting, meal plans, trends, HIW Pro.

## Setup

```sh
flutter pub get
cp lib/config/ai_config_template.dart lib/config/ai_config.dart
# paste your Gemini key (https://aistudio.google.com/apikey)
flutter run --dart-define=GEMINI_API_KEY=AIza...
```

Cloud backends (optional, off by default):

```sh
flutter run \
  --dart-define=SUPABASE_URL=https://xyz.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=sb_publishable_...
```

Without the defines, auth stays on the mock provider and analytics stays
counts-only local (Firebase mirrors automatically once configured —
no `google-services.json` needed to build).

## Verify

```sh
flutter analyze
flutter test test/
flutter build apk --debug
```
