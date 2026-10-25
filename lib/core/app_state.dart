import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/user_api.dart';

class AppState {
  static const _loggedInKey = 'loggedIn';
  static const _userInfoKey = 'userInfoDone';

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_loggedInKey) ?? false;
  }

  static Future<bool> hasUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_userInfoKey) ?? false;
  }

  static Future<void> setLoggedIn(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_loggedInKey, v);
  }

  static Future<void> setUserInfoDone(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_userInfoKey, v);
  }

  static const _usernameKey = 'username';

  // 🧪 TESTER VERIFICATION (PERSISTED)
  static const _testerVerifiedKey = 'testerVerified';
  static const _lastVerifiedCodeKey = 'lastVerifiedCode';

  static Future<bool> isTesterVerified() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_testerVerifiedKey) ?? false;
  }

  static Future<void> setTesterVerified(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_testerVerifiedKey, v);
  }

  static Future<String?> getLastVerifiedCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastVerifiedCodeKey);
  }

  static Future<void> setLastVerifiedCode(String? code) async {
    final prefs = await SharedPreferences.getInstance();
    if (code == null) {
      await prefs.remove(_lastVerifiedCodeKey);
    } else {
      await prefs.setString(_lastVerifiedCodeKey, code);
    }
  }

  // 👤 USERNAME
  static Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_usernameKey);
  }

  static Future<void> setUsername(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_usernameKey, name);
  }

  // 📧 EMAIL
  static const _emailKey = 'email';
  static Future<void> setEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_emailKey, email);
  }

  static Future<String?> getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_emailKey);
  }

  // 🔔 REMINDERS
  static const _reminderPrefix = 'reminder_';
  
  static Future<String?> getReminderTime(String mealKey) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('$_reminderPrefix$mealKey');
  }

  static Future<void> setReminderTime(String mealKey, String time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_reminderPrefix$mealKey', time);
  }

  static Future<bool> isReminderEnabled(String mealKey) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('${_reminderPrefix}enabled_$mealKey') ?? false;
  }

  static Future<void> setReminderEnabled(String mealKey, bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('${_reminderPrefix}enabled_$mealKey', enabled);
  }

  // 🎨 THEME
  static const _themeKey = 'currentTheme';

  static Future<String> getTheme() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_themeKey) ?? 'default';
  }

  static Future<void> setTheme(String theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, theme);
  }

  // ⏱️ INTRO TIMING (TEMPORARY setting for testing 1-10s, remove after final)
  static const _splashSecondsKey = 'splashSeconds';

  static Future<int> getSplashSeconds() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getInt(_splashSecondsKey) ?? 5;
    return v.clamp(1, 10);
  }

  static Future<void> setSplashSeconds(int seconds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_splashSecondsKey, seconds.clamp(1, 10));
  }

  // 🎨 CUSTOMIZE THEME PALETTE (user-picked, survives logout)
  static const _customBgKey = 'customBg';
  static const _customCardKey = 'customCard';
  static const _customPrimaryKey = 'customPrimary';
  static const _bottomNavBgKey = 'bottomNavBgColor';
  static const _bottomNavSelectionKey = 'bottomNavSelectionColor';

  static Future<int?> getCustomColor(String which) async {
    final prefs = await SharedPreferences.getInstance();
    int? val;
    switch (which) {
      case 'bg':
        val = prefs.getInt(_customBgKey);
        break;
      case 'card':
        val = prefs.getInt(_customCardKey);
        break;
      case 'primary':
        val = prefs.getInt(_customPrimaryKey);
        break;
      case 'bottomNavBg':
        val = prefs.getInt(_bottomNavBgKey);
        break;
      case 'bottomNavSelection':
        val = prefs.getInt(_bottomNavSelectionKey);
        break;
      default:
        return null;
    }
    if (val == null || val == -1) return null;
    return val;
  }

  static Future<void> setCustomColor(String which, int argb) async {
    final prefs = await SharedPreferences.getInstance();
    if (argb == -1) {
      switch (which) {
        case 'bg':
          await prefs.remove(_customBgKey);
          break;
        case 'card':
          await prefs.remove(_customCardKey);
          break;
        case 'primary':
          await prefs.remove(_customPrimaryKey);
          break;
        case 'bottomNavBg':
          await prefs.remove(_bottomNavBgKey);
          break;
        case 'bottomNavSelection':
          await prefs.remove(_bottomNavSelectionKey);
          break;
      }
      return;
    }
    switch (which) {
      case 'bg':
        await prefs.setInt(_customBgKey, argb);
        break;
      case 'card':
        await prefs.setInt(_customCardKey, argb);
        break;
      case 'primary':
        await prefs.setInt(_customPrimaryKey, argb);
        break;
      case 'bottomNavBg':
        await prefs.setInt(_bottomNavBgKey, argb);
        break;
      case 'bottomNavSelection':
        await prefs.setInt(_bottomNavSelectionKey, argb);
        break;
    }
  }

  static Future<void> clearCustomColors() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_customBgKey);
    await prefs.remove(_customCardKey);
    await prefs.remove(_customPrimaryKey);
    await prefs.remove(_bottomNavBgKey);
    await prefs.remove(_bottomNavSelectionKey);
  }

  // 🌱 ONBOARDING / PERSONALIZATION (v1, survives logout like theme)
  static const _onboardingV1Key = 'onboardingV1Done';
  static const _ageKey = 'profile_age';
  static const _sexKey = 'profile_sex';
  static const _heightKey = 'profile_height_cm';
  static const _weightKey = 'profile_weight_kg';
  static const _bodyFatKey = 'profile_bodyfat';
  static const _activityKey = 'profile_activity';
  static const _goalKey = 'profile_goal';
  static const _goalsExtraKey = 'profile_goals_extra';
  static const _goalWeightKey = 'profile_goal_weight';
  static const _dietKey = 'profile_diet';
  static const _restrictionsKey = 'profile_restrictions';
  static const _allergiesKey = 'profile_allergies';
  static const _regionDistrictKey = 'region_district';
  static const _regionStateKey = 'region_state';
  static const _regionCountryKey = 'region_country';
  static const _regionManualKey = 'region_manual';
  static const _customTargetsKey = 'profile_custom_targets';

  static Future<bool> onboardingV1Done() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingV1Key) ?? false;
  }

  static Future<void> setOnboardingV1Done(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingV1Key, v);
  }

  static Future<int?> getAge() async =>
      (await SharedPreferences.getInstance()).getInt(_ageKey);
  static Future<void> setAge(int v) async =>
      (await SharedPreferences.getInstance()).setInt(_ageKey, v);

  static Future<String?> getSex() async =>
      (await SharedPreferences.getInstance()).getString(_sexKey);
  static Future<void> setSex(String v) async =>
      (await SharedPreferences.getInstance()).setString(_sexKey, v);

  static Future<double?> getHeightCm() async =>
      (await SharedPreferences.getInstance()).getDouble(_heightKey);
  static Future<void> setHeightCm(double v) async =>
      (await SharedPreferences.getInstance()).setDouble(_heightKey, v);

  static Future<double?> getWeightKg() async =>
      (await SharedPreferences.getInstance()).getDouble(_weightKey);
  static Future<void> setWeightKg(double v) async =>
      (await SharedPreferences.getInstance()).setDouble(_weightKey, v);

  static Future<double?> getBodyFatPct() async =>
      (await SharedPreferences.getInstance()).getDouble(_bodyFatKey);
  static Future<void> setBodyFatPct(double? v) async {
    final prefs = await SharedPreferences.getInstance();
    if (v == null) {
      await prefs.remove(_bodyFatKey);
    } else {
      await prefs.setDouble(_bodyFatKey, v);
    }
  }

  static Future<String?> getActivity() async =>
      (await SharedPreferences.getInstance()).getString(_activityKey);
  static Future<void> setActivity(String v) async =>
      (await SharedPreferences.getInstance()).setString(_activityKey, v);

  static Future<String?> getGoal() async =>
      (await SharedPreferences.getInstance()).getString(_goalKey);
  static Future<void> setGoal(String v) async =>
      (await SharedPreferences.getInstance()).setString(_goalKey, v);

  static Future<List<String>> getGoalsExtra() async =>
      (await SharedPreferences.getInstance())
          .getStringList(_goalsExtraKey) ??
      const [];
  static Future<void> setGoalsExtra(List<String> v) async =>
      (await SharedPreferences.getInstance())
          .setStringList(_goalsExtraKey, v);

  static Future<double?> getGoalWeightKg() async =>
      (await SharedPreferences.getInstance()).getDouble(_goalWeightKey);
  static Future<void> setGoalWeightKg(double? v) async {
    final prefs = await SharedPreferences.getInstance();
    if (v == null) {
      await prefs.remove(_goalWeightKey);
    } else {
      await prefs.setDouble(_goalWeightKey, v);
    }
  }

  static Future<String?> getDiet() async =>
      (await SharedPreferences.getInstance()).getString(_dietKey);
  static Future<void> setDiet(String v) async =>
      (await SharedPreferences.getInstance()).setString(_dietKey, v);

  static Future<List<String>> getRestrictions() async =>
      (await SharedPreferences.getInstance())
          .getStringList(_restrictionsKey) ??
      const [];
  static Future<void> setRestrictions(List<String> v) async =>
      (await SharedPreferences.getInstance())
          .setStringList(_restrictionsKey, v);

  static Future<List<String>> getAllergies() async =>
      (await SharedPreferences.getInstance())
          .getStringList(_allergiesKey) ??
      const [];
  static Future<void> setAllergies(List<String> v) async =>
      (await SharedPreferences.getInstance())
          .setStringList(_allergiesKey, v);

  static Future<void> setRegion({
    String? district,
    String? state,
    String? country,
    bool manual = true,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (district == null) {
      await prefs.remove(_regionDistrictKey);
    } else {
      await prefs.setString(_regionDistrictKey, district);
    }
    if (state == null) {
      await prefs.remove(_regionStateKey);
    } else {
      await prefs.setString(_regionStateKey, state);
    }
    if (country == null) {
      await prefs.remove(_regionCountryKey);
    } else {
      await prefs.setString(_regionCountryKey, country);
    }
    await prefs.setBool(_regionManualKey, manual);
  }

  static Future<Map<String, String?>> getRegion() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'district': prefs.getString(_regionDistrictKey),
      'state': prefs.getString(_regionStateKey),
      'country': prefs.getString(_regionCountryKey),
    };
  }

  /// Which targets the user hand-edited (never silently overwritten, §19).
  static Future<Set<String>> customTargets() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_customTargetsKey) ?? const []).toSet();
  }

  static Future<void> markTargetCustom(String which) async {
    final prefs = await SharedPreferences.getInstance();
    final cur =
        (prefs.getStringList(_customTargetsKey) ?? []).toSet()..add(which);
    await prefs.setStringList(_customTargetsKey, cur.toList());
  }

  /// Clears personalization so onboarding can run again (Settings action).
  static Future<void> resetPersonalization() async {
    final prefs = await SharedPreferences.getInstance();
    for (final k in [
      _onboardingV1Key,
      _ageKey,
      _sexKey,
      _heightKey,
      _weightKey,
      _bodyFatKey,
      _activityKey,
      _goalKey,
      _goalsExtraKey,
      _goalWeightKey,
      _dietKey,
      _restrictionsKey,
      _allergiesKey,
      _regionDistrictKey,
      _regionStateKey,
      _regionCountryKey,
      _regionManualKey,
      _customTargetsKey,
    ]) {
      await prefs.remove(k);
    }
  }

  static Future<void> logout() async {
    // 🧪 Release code if verified
    try {
      final code = await getLastVerifiedCode();
      if (code != null) {
        // 🆕 Add timeout to prevent hanging
        await UserApi.releaseTesterCode(code).timeout(
          const Duration(seconds: 3),
          onTimeout: () {
            debugPrint('Logout API timeout - proceeding with local logout');
          },
        );
      }
    } catch (e) {
      // ⚠️ Ignore network errors, prioritize local logout
      debugPrint('Logout API error: $e');
    }
    
    final prefs = await SharedPreferences.getInstance();
    // Keep appearance + personalization across logout (theme, palette,
    // timing, onboarding). Only tester/session keys are cleared.
    final keep = <String, Object>{};
    for (final k in [
      _themeKey,
      _customBgKey,
      _customCardKey,
      _customPrimaryKey,
      _bottomNavBgKey,
      _bottomNavSelectionKey,
      _splashSecondsKey,
      _onboardingV1Key,
      _usernameKey,
      _ageKey,
      _sexKey,
      _heightKey,
      _weightKey,
      _bodyFatKey,
      _activityKey,
      _goalKey,
      _goalsExtraKey,
      _goalWeightKey,
      _dietKey,
      _restrictionsKey,
      _allergiesKey,
      _regionDistrictKey,
      _regionStateKey,
      _regionCountryKey,
      _regionManualKey,
      _customTargetsKey,
    ]) {
      final v = prefs.get(k);
      if (v != null) keep[k] = v;
    }
    final keepLists = <String, List<String>>{};
    for (final k in [_goalsExtraKey, _restrictionsKey, _allergiesKey]) {
      final v = prefs.getStringList(k);
      if (v != null) keepLists[k] = v;
    }
    await prefs.clear(); // This clears everything including verified status
    for (final e in keep.entries) {
      final v = e.value;
      if (v is String) await prefs.setString(e.key, v);
      if (v is int) await prefs.setInt(e.key, v);
      if (v is double) await prefs.setDouble(e.key, v);
      if (v is bool) await prefs.setBool(e.key, v);
    }
    for (final e in keepLists.entries) {
      await prefs.setStringList(e.key, e.value);
    }
  }
}
