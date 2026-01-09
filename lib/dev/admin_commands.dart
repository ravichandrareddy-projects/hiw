import 'dev_config.dart';
import 'admin_reset.dart';

class AdminCommands {
  /// Returns true if command was handled
  static Future<bool> handle(String input) async {
    if (!DevConfig.devMode) return false;

    final cmd = input.trim().toUpperCase();

    switch (cmd) {
      case "ADMIN_RESET_ALL":
        await AdminReset.full();
        return true;

      case "ADMIN_RESET_HISTORY":
        await AdminReset.historyOnly();
        return true;

      default:
        return false;
    }
  }
}
