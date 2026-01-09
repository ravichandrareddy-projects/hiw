import 'package:hive/hive.dart';
import '../hive/avatar_hive_model.dart';
import 'avatar_logic.dart';

class AvatarStore {
  static const String boxName = 'avatarBox';

  static const String avatarKey = 'avatar';
  static const String weekKey = 'weekId';

  static const String rawHealthKey = 'rawHealth';
  static const String rawEnergyKey = 'rawEnergy';
  static const String rawStaminaKey = 'rawStamina';

  // 🆕 DAILY STAMINA PREVIEW (VISIBLE TODAY)
  static const String dailyStaminaPreviewKey = 'dailyStaminaPreview';
  static const String dailyStaminaDateKey = 'dailyStaminaDate';

  static const double maxDailyStamina = 100.0;
  static const double waterStaminaIncrement = 5.0;

  Box? _box; // 🔧 SAFE nullable box

  // -------------------------
  // INIT (SAFE)
  // -------------------------
  Future<void> init() async {
    if (_box != null) return; // ✅ prevent double init
    _box = await Hive.openBox(boxName);
    _ensureWeek();
    _ensureTodayStamina();

    if (!_box!.containsKey(avatarKey)) {
      _box!.put(
        avatarKey,
        AvatarHive(health: 0, energy: 0, stamina: 0),
      );
    }
  }

  // -------------------------
  // INTERNAL SAFETY
  // -------------------------
  bool get _ready => _box != null;

  // -------------------------
  // GETTERS
  // -------------------------
  AvatarHive get avatar =>
      _ready ? _box!.get(avatarKey) : AvatarHive(health: 0, energy: 0, stamina: 0);

  int get rawHealth =>
      _ready ? _box!.get(rawHealthKey, defaultValue: 0) : 0;

  int get rawEnergy =>
      _ready ? _box!.get(rawEnergyKey, defaultValue: 0) : 0;

  int get rawStamina =>
      _ready ? _box!.get(rawStaminaKey, defaultValue: 0) : 0;

  double get dailyStaminaPreview =>
      _ready
          ? _box!.get(dailyStaminaPreviewKey,
              defaultValue: avatar.stamina)
          : avatar.stamina;

  // -------------------------
  // FOOD → WEEKLY RAW
  // -------------------------
  void addDailyRaw({
    required int healthRaw,
    required int energyRaw,
    required int staminaRaw,
  }) {
    if (!_ready) return;

    _box!.put(rawHealthKey, rawHealth + healthRaw);
    _box!.put(rawEnergyKey, rawEnergy + energyRaw);
    _box!.put(rawStaminaKey, rawStamina + staminaRaw);
  }

  // -------------------------
  // 💧 WATER → DAILY STAMINA (INSTANT)
  // -------------------------
  void addStaminaFromWater() {
    if (!_ready) return;

    _ensureTodayStamina();

    final current = dailyStaminaPreview;
    final updated =
        (current + waterStaminaIncrement).clamp(0.0, maxDailyStamina);

    _box!.put(dailyStaminaPreviewKey, updated);
  }

  // -------------------------
  // FINALIZE WEEK (SAT 4 PM)
  // -------------------------
  void finalizeWeek() {
    if (!_ready) return;

    final avatarData = avatar;

    avatarData.health =
        AvatarLogic.scaleWeeklyRawToStat(rawHealth).toDouble();
    avatarData.energy =
        AvatarLogic.scaleWeeklyRawToStat(rawEnergy).toDouble();
    avatarData.stamina =
        AvatarLogic.scaleWeeklyRawToStat(rawStamina).toDouble();

    avatarData.save();

    // align daily preview with finalized stamina
    _box!.put(dailyStaminaPreviewKey, avatarData.stamina);
  }

  // -------------------------
  // RESET WEEK
  // -------------------------
  void resetWeek() {
    if (!_ready) return;

    _box!.put(rawHealthKey, 0);
    _box!.put(rawEnergyKey, 0);
    _box!.put(rawStaminaKey, 0);
  }

  // -------------------------
  // DAILY STAMINA RESET
  // -------------------------
  void _ensureTodayStamina() {
    if (!_ready) return;

    final today = _todayKey();
    final saved = _box!.get(dailyStaminaDateKey);

    if (saved != today) {
      _box!.put(dailyStaminaDateKey, today);
      _box!.put(dailyStaminaPreviewKey, avatar.stamina);
    }
  }

  // -------------------------
  // WEEK HANDLING
  // -------------------------
  void _ensureWeek() {
    if (!_ready) return;

    final currentWeek = _currentWeekId();
    final savedWeek = _box!.get(weekKey);

    if (savedWeek != currentWeek) {
      resetWeek();
      _box!.put(weekKey, currentWeek);
    }
  }

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }

  String _currentWeekId() {
    final now = DateTime.now();
    final sunday =
        now.subtract(Duration(days: now.weekday % 7));
    return '${sunday.year}-${sunday.month}-${sunday.day}';
  }
}
