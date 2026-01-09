import 'package:hive/hive.dart';

class WaterStore {
  // 🔒 SINGLETON
  static final WaterStore _instance = WaterStore._internal();
  factory WaterStore() => _instance;
  WaterStore._internal();

  static const String boxName = 'waterbox';

  static const String keyDate = 'date';
  static const String keyTicks = 'ticks';
  static const String keyLastLog = 'lastLog';

  Box? _box;

  // -------------------------
  // INIT (SAFE, IDENTITY-BASED)
  // -------------------------
  Future<void> init() async {
    if (_box != null) return; // ✅ already initialized

    if (Hive.isBoxOpen(boxName)) {
      _box = Hive.box(boxName);
    } else {
      _box = await Hive.openBox(boxName);
    }

    _ensureToday();
  }

  bool get _ready => _box != null;

  // -------------------------
  // GETTERS
  // -------------------------
  int get waterTicks =>
      _ready ? _box!.get(keyTicks, defaultValue: 0) : 0;

  DateTime? get lastLoggedTime {
    if (!_ready) return null;
    final v = _box!.get(keyLastLog);
    if (v == null) return null;
    return DateTime.tryParse(v);
  }

  // -------------------------
  // CAN LOG?
  // -------------------------
  bool canLogNow() {
    final last = lastLoggedTime;
    if (last == null) return true;
    return DateTime.now().difference(last).inMinutes >= 60;
  }

  // -------------------------
  // LOG WATER
  // -------------------------
  bool logWater() {
    if (!_ready) return false;

    _ensureToday();

    if (!canLogNow()) return false;

    _box!.put(keyTicks, waterTicks + 1);
    _box!.put(keyLastLog, DateTime.now().toIso8601String());
    return true;
  }

  // -------------------------
  // DAY RESET
  // -------------------------
  void _ensureToday() {
    final today = _todayKey();
    final saved = _box!.get(keyDate);

    if (saved != today) {
      _box!.put(keyDate, today);
      _box!.put(keyTicks, 0);
      _box!.put(keyLastLog, null);
    }
  }

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }
}
