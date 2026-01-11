import 'package:hive/hive.dart';
import '../hive/avatar_hive_model.dart';

class AvatarStore {
  // -------------------------
  // SINGLETON (IMPORTANT)
  // -------------------------
  static final AvatarStore _instance = AvatarStore._internal();
  factory AvatarStore() => _instance;

  AvatarStore._internal() {
    _avatarBox = Hive.box<AvatarHive>('avatarBox');
    _metaBox = Hive.box('avatarMetaBox');

    if (!_avatarBox.containsKey(_avatarKey)) {
      _avatarBox.put(
        _avatarKey,
        AvatarHive(health: 0, energy: 0, stamina: 0),
      );
    }

    _ensureWeek();
    _ensureTodayStamina();
  }

  // -------------------------
  // BOXES
  // -------------------------
  late final Box<AvatarHive> _avatarBox;
  late final Box _metaBox;

  // -------------------------
  // KEYS
  // -------------------------
  static const String _avatarKey = 'avatar';
  static const String _weekKey = 'weekId';
  static const String _weeklyJunkKey = 'weeklyJunkCount';
  static const String _dailyStaminaPreviewKey = 'dailyStaminaPreview';
  static const String _dailyStaminaDateKey = 'dailyStaminaDate';

  // -------------------------
  // LIMITS
  // -------------------------
  static const double maxHealth = 83.0;
  static const double maxEnergy = 100.0;
  static const double maxStamina = 100.0;
  static const double waterStaminaIncrement = 5.0;

  // =====================================================
  // LEGACY METHODS (REQUIRED – DO NOT REMOVE)
  // =====================================================
  Future<void> init() async {
    // kept only so old calls don't crash
  }

  void addDailyRaw({
    required int healthRaw,
    required int energyRaw,
    required int staminaRaw,
  }) {
    // deprecated raw system – no-op
  }

  // -------------------------
  // GETTERS
  // -------------------------
  AvatarHive get avatar => _avatarBox.get(_avatarKey)!;

  int get weeklyJunkCount =>
      _metaBox.get(_weeklyJunkKey, defaultValue: 0) as int;

  double get dailyStaminaPreview =>
      (_metaBox.get(_dailyStaminaPreviewKey) as double?) ??
      avatar.stamina;

  // -------------------------
  // APPLY HEALTH + ENERGY
  // -------------------------
  void applyHealthEnergy({
    required double healthDelta,
    required double energyDelta,
    required bool junkConsumed,
  }) {
    final a = avatar;

    a.health =
        (a.health + healthDelta).clamp(0.0, maxHealth);
    a.energy =
        (a.energy + energyDelta).clamp(0.0, maxEnergy);

    a.save();

    if (junkConsumed) {
      _metaBox.put(_weeklyJunkKey, weeklyJunkCount + 1);
    }
  }

  // -------------------------
  // 💧 WATER → STAMINA
  // -------------------------
  void addStaminaFromWater() {
    _ensureTodayStamina();

    final double updated =
        (dailyStaminaPreview + waterStaminaIncrement)
            .clamp(0.0, maxStamina)
            .toDouble();

    _metaBox.put(_dailyStaminaPreviewKey, updated);

    final a = avatar;
    a.stamina = updated;
    a.save();
  }

  // -------------------------
  // DAILY RESET
  // -------------------------
  void _ensureTodayStamina() {
    final today = _todayKey();
    final saved = _metaBox.get(_dailyStaminaDateKey);

    if (saved != today) {
      _metaBox.put(_dailyStaminaDateKey, today);
      _metaBox.put(_dailyStaminaPreviewKey, avatar.stamina);
    }
  }

  // -------------------------
  // WEEK RESET
  // -------------------------
  void _ensureWeek() {
    final currentWeek = _currentWeekId();
    final savedWeek = _metaBox.get(_weekKey);

    if (savedWeek != currentWeek) {
      _metaBox.put(_weekKey, currentWeek);
      _metaBox.put(_weeklyJunkKey, 0);
    }
  }

  String _todayKey() {
    final n = DateTime.now();
    return '${n.year}-${n.month}-${n.day}';
  }

  String _currentWeekId() {
    final n = DateTime.now();
    final sunday =
        n.subtract(Duration(days: n.weekday % 7));
    return '${sunday.year}-${sunday.month}-${sunday.day}';
  }
}
