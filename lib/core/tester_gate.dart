// lib/core/tester_gate.dart
// Launch-safety gate: dev commands, dev screens, and tester tools
// are visible ONLY in debug builds or for tester-verified users.
// Public release users never see them (see launch_safety_audit.txt).
import 'package:flutter/foundation.dart';
import 'app_state.dart';

class TesterGate {
  static Future<bool> isTesterMode() async {
    if (kDebugMode) return true;
    try {
      return await AppState.isTesterVerified();
    } catch (_) {
      return false;
    }
  }
}
