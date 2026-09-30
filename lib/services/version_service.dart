import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VersionService {
  static const String _kMajor = 'app_version_major';
  static const String _kMinor = 'app_version_minor';
  static const String _kPatch = 'app_version_patch';

  static Future<void> incrementVersion() async {
    final prefs = await SharedPreferences.getInstance();
    
    int major = prefs.getInt(_kMajor) ?? 0;
    int minor = prefs.getInt(_kMinor) ?? 0;
    int patch = prefs.getInt(_kPatch) ?? 2; // Starting from 0.0.02 as requested

    // Increment Patch
    patch++;

    // Rollover Logic (Max 10)
    if (patch > 10) {
      patch = 0;
      minor++;
    }

    if (minor > 10) {
      minor = 0;
      major++;
    }

    // Save back
    await prefs.setInt(_kMajor, major);
    await prefs.setInt(_kMinor, minor);
    await prefs.setInt(_kPatch, patch);
    
    debugPrint("VERSION UPDATED: ${getVersionStringSync(major, minor, patch)}");
  }

  static Future<String> getVersionString() async {
    final prefs = await SharedPreferences.getInstance();
    int major = prefs.getInt(_kMajor) ?? 0;
    int minor = prefs.getInt(_kMinor) ?? 0;
    int patch = prefs.getInt(_kPatch) ?? 2;
    return getVersionStringSync(major, minor, patch);
  }

  static String getVersionStringSync(int major, int minor, int patch) {
    // Format: v0.01.10 (using zero padding for minor/patch if needed or direct as requested)
    // The user example: v0.0.03, v0.0.04 ... v0.01.10
    // I will use 2-digit padding for minor and patch to match "v0.01.10" aesthetic
    String minStr = minor < 10 ? "0$minor" : "$minor";
    String patStr = patch < 10 ? "0$patch" : "$patch";
    
    // Actually, looking at the user's request: "v0.0.03, v0.0.04" then "v0.01.10"
    // It seems they want 1-digit while < 10 for major, but maybe 2-digit for minor/patch?
    // Let's stick to a clean vX.YY.ZZ format or similar.
    // Re-reading: "v0.01.10". This implies 2 digits for minor and 2 for patch.
    
    return "v$major.$minStr.$patStr";
  }
}
