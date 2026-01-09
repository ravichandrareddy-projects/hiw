import '../core/history_store.dart';
import '../core/nutrition_store.dart';

class AdminReset {
  /// 🔥 FULL WIPE (DEV ONLY)
  static Future<void> full() async {
    await HistoryStore().clearAll();
    await NutritionStore().clearAll();

    // Future safe adds (not active yet):
    // await MonthStore().clearAll();
    // await AvatarStore().reset();

    print("🧹 DEV RESET: FULL RESET DONE");
  }

  /// 🧹 HISTORY ONLY
  static Future<void> historyOnly() async {
    await HistoryStore().clearAll();
    print("🧹 DEV RESET: HISTORY RESET DONE");
  }
}
