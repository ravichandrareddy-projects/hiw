# HIW — Next Plan Handoff (nexthiwplan)

> Read this file first in a new session, then continue work. Context window in the old session is high.

## 1. Objective
Upgrade HIW into a personalized, freemium health app while preserving existing architecture:
- Camera/text food scanner converging to one `FoodRecognitionResult` pipeline.
- Onboarding + deterministic GoalEngine + Home personalization.
- Mandatory mock login now; Supabase auth + Firebase analytics at the end.
- Freemium quotas + Pro paywall + fasting/meal-plans/trends; ad-free.

## 2. Completed work
### Scanner + camera
- `lib/core/food_result.dart`: `FoodRecognitionResult`, `FoodCandidate`, `components[]`, `isCombo`, `copyWithPortion`, `toFoodItems`, `truncated(n)`, `kFoodConfidenceThreshold = 0.75`, `kMinScanDuration = 500ms`.
- `lib/core/food_search_service.dart`: normalize + regional aliases + contains/token/Levenshtein + cache; no duplicate Food records.
- `lib/widgets/rainbow_scan_overlay.dart`: square photo card + static gradient + rotation spinner; sweep line removed.
- `lib/screens/scanner_screen.dart`: Scan/Text toggle, Food/Barcode toggle, cream Scan pill, peach Food pill, white shutter, photo-first capture, isolate `_captureMetrics`, blur gate `kSevereBlurThreshold = 20` + `_askBlurry`, null-safe preview, SafeArea bottom controls, silent lifecycle (pause on inactive, no reload screen), `_analyzeShot` with RETRY.
- `lib/screens/food_result_screen.dart`: shared single/combo UI, hero image, meal pills, nutrition cards, portion sheet, add-ons, per-item combo steppers, dynamic CTA, `_isSaving` guard.
- `lib/screens/food_text_search_screen.dart`: DB-first search UI.
- Camera stack: `camera 0.10.6`, `camera_android 0.10.11+1` → `camera_android_camerax`; `ResolutionPreset.max`; preview `1280x720` → `1600x1200`; capture `2160x3840` / `3072x4096` full-sensor, original never resized.

### Vision + nutrition rule (LOCKED)
- Gemini vision names foods; ALL calories come from `assets/food_nutrition_db.json` (2621 entries).
- `lib/services/food_recognition_service.dart`: Gemini POST, 25s timeout, 400/401/403/404/429 handling, DB-first `_matchItem` + fuzzy fallback, quantity clamp `0.25–3.0`, 768px q80 upload copy.
- `lib/config/ai_config.dart`: primary `gemini-3.1-flash-lite`, fallbacks `gemini-3.6-flash`, `gemini-3.8-flash`. NOTE: this file is git-ignored/local-only.
- No offline TFLite model (user vetoed; `lib/ml/food_ml_service.dart` deleted).

### Startup + onboarding + Home
- `lib/main.dart`: `HIWBootApp`/`_BootScreen` (fast first frame) → `AppGate`: Splash liquid H+I+W → tester gate → login → onboarding → `MainShell`.
- `lib/core/health_profile.dart`: `UserProfile`, `GoalModel`, `ReminderPreferences`, `RegionalPreferences`, `OnboardingState`.
- `lib/core/goal_engine.dart`: Mifflin-St Jeor, Katch-McArdle (valid bf only), TDEE factors `1.20/1.375/1.55/1.725/1.90`, deficit 400 / surplus 300, clamp 1200–5000, protein `0.8/1.4/1.6 g/kg`, fat 28% with rebalance, fiber 25g, hydration 60% of 3.7L/2.7L.
- `lib/core/app_state.dart`: `onboardingV1Done` + profile/goal/diet/region/custom-target keys + `resetPersonalization`; logout preserves personalization.
- `lib/core/nutrition_store.dart`: added `proteinTargetG`, `fiberTargetG`, `hydrationTargetMl` in `metaBox`.
- `lib/screens/onboarding/`: 10-page flow (welcome→summary), progress `1/9–9/9`, Back-safe drafts, validation, editable plan, reminders (channels 101–104, water 200–215, streak 300), region manual + location rationale.
- `lib/screens/profile_edit_screen.dart`: edit all onboarding values, custom-target flags respected.
- Home (`lib/screens/food_screen.dart`): live target getters (no 2000 backfill), protein `x/y`, hydration target line, `HabitCard` inserted.
- Theme: `DEFAULT = Plain` in `AppTheme.getTheme`; `PlainBackground` `#FBF7EF`; tokens-only UI.

### Habits + auth + P2 (partial)
- `lib/core/habit_engine.dart`: freezes (1 per 14 streak days), protected streak, rotating weekly challenges, HIW Score `40/25/20/15`, 7-day sparkline data.
- `lib/widgets/habit_card.dart`: score ring, sparkline, challenge bar, freeze row, share via `share_plus`.
- Auth P0: `lib/core/auth_service.dart` (`MockAuthProvider` seeded `user1@gmail.com` / `1234`, OTP `123456`; `SupabaseAuthProvider` stub), `lib/auth/` welcome/login/register/OTP, mandatory gate in `_decide`.
- P2 created (wiring incomplete): `lib/core/subscription/plan.dart` (₹119/₹899, trial 7d, quotas 40/20/5/3), `entitlement.dart`, `usage_store.dart` (`quotas` box), `billing_service.dart` (`in_app_purchase`), `lib/core/fasting_engine.dart` + `lib/screens/fasting_screen.dart`, `lib/core/mealplan_engine.dart` + `lib/screens/mealplan_screen.dart`, `lib/screens/trends_screen.dart`, `lib/screens/paywall_screen.dart`, `lib/widgets/limit_sheet.dart`.
- Tests: `test/goal_engine_test.dart`, `test/food_upgrade_verify_test.dart`, `test/auth_service_test.dart`, `test/habit_engine_test.dart` — all passing at last check.
- `flutter analyze` clean on new files; pre-existing warnings elsewhere untouched.

## 3. Active / unfinished (do next)
1. ~~P2 wiring~~ DONE (committed 5a6ea7a, mobile-verified): unified chat quota + limit sheets, scan burn-after-success, in-screen Pro guards, mealplan diet fix, paywall trial/buy/restore, coupons, analytics stub + opt-out. 33 tests green, debug APK built.
2. ~~Coupon system~~ DONE (same commit).
3. ~~Analytics stub~~ DONE (counts-only + opt-out; Firebase needs `google-services.json` from user — TODO in `analytics_service.dart`).
4. ~~Verify~~ DONE for P2 (analyze/test/build/device matrix passed per user).
5. P3 next: (a) push blocked — repo `hiw-health-wellness` returns "not found" despite `gh` login; user must create it or grant access, then push local commits; (b) ~~Firebase full wiring~~ DONE (deps + guarded init + mirror; works without json, mirrors when configured); (c) ~~Supabase swap~~ DONE (real provider behind dart-defines, mock default); (d) ~~Barcode~~ DONE (OFF lookup → DB-strict match → text-search, quota-gated); (e) Play Console SKUs (`hiw_pro_monthly/annual`) + review remain external.

## 4. Blockers / risks
- Git push STILL fails (2026-09-29): `remote: Repository not found` for `https://github.com/ravichandrareddy2712-bit/hiw-health-wellness.git` even though `gh auth status` shows logged in. 2 local commits ahead. User must create the repo (or fix access) before push.
- `ai_config.dart` clone risk FIXED (2026-09-29): tracked `lib/config/ai_defaults.dart` (models) + `ai_config_template.dart` (setup); ignored `ai_config.dart` now delegates to defaults. Fresh clone = copy template → builds.
- Launch safety DONE (2026-09-29): `lib/core/tester_gate.dart` (`kDebugMode || tester-verified`); dev chat commands (Foodity + Mood Support), update-log prompt overlay, avatar Update-Log + DevThemeTools buttons, profile Test-Mood-Check tile all gated.
- Device flaky: `ZN4223RV26` USB + wireless (`192.168.0.166:35163`, `192.168.1.170:35015`); IPs expire; keep screen awake for screenshots/taps.
- Gemini free-tier: intermittent HTTP 503 overload + ~1 photo/min rate limit observed; key default lives in git-ignored `ai_config.dart`.
- `ai_config.dart` is git-ignored: model switch (`gemini-3.1-flash-lite`) will NOT survive fresh clones — document or move model name to tracked config later.
- Do not regress: Plain default theme, camera/scan UI, offline-first Hive, ad-free, no hardcoded theme colors.

## 5. Key commands
- `flutter analyze <files>`; `flutter test test/`; `flutter build apk --debug`
- `adb devices`; `adb connect <ip>:<port>`; `adb -s <id> install -r build/app/outputs/flutter-apk/app-debug.apk`
- `adb -s <id> shell am start -n com.valtooy.hiw/.MainActivity`
- `adb -s <id> shell am force-stop com.valtooy.hiw` (must cold-start after install; Android reuses old process otherwise)
- `adb -s <id> logcat -d | grep HIW` (look for `HIW ANALYZE FAILED`, `HIW VISION`, `HIW CAPTURE`, `HIW PREVIEW`)
- `git status --short`; commit carefully; verify `git remote -v` + `gh auth status` before push.

## 6. Resume instruction for new session
1. Read this file fully.
2. Run `git status --short` and `flutter analyze` on touched files.
3. Continue from Section 3 in order; mark todos as you go.
4. Before finishing: `flutter analyze`, `flutter test`, build APK, install on device, verify matrix.
5. Do not push unless remote + auth are fixed and user approves.
