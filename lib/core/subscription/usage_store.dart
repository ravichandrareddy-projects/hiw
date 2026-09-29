// lib/core/subscription/usage_store.dart
// Quota counters: monthly scans, daily chat. Timezone-safe window keys,
// consume-after-success ONLY, idempotent keys kill double-counting.
import 'package:hive/hive.dart';
import 'plan.dart';

class UsageStore {
  static const _boxName = 'quotas';

  static Box _box() {
    if (!Hive.isBoxOpen(_boxName)) {
      throw StateError('quotas box not open');
    }
    return Hive.box(_boxName);
  }

  static Future<void> init() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox(_boxName);
    }
  }

  static String _monthKey(DateTime d) => '${d.year}-${d.month}';
  static String _dayKey(DateTime d) =>
      '${d.year}-${d.month}-${d.day}';

  static String _key(String kind, String window) => '$kind:$window';

  static int used(String kind, String window) {
    try {
      return _box().get(_key(kind, window), defaultValue: 0) as int;
    } catch (_) {
      return 0;
    }
  }

  static int scansUsedThisMonth() =>
      used('photo', _monthKey(DateTime.now()));
  static int barcodeUsedThisMonth() =>
      used('barcode', _monthKey(DateTime.now()));
  static int chatUsedToday() =>
      used('chat', _dayKey(DateTime.now()));

  static int scansLeft() =>
      (PlanConfig.freeScansPerMonth - scansUsedThisMonth())
          .clamp(0, 9999);
  static int barcodeLeft() =>
      (PlanConfig.freeBarcodePerMonth - barcodeUsedThisMonth())
          .clamp(0, 9999);
  static int chatLeft() =>
      (PlanConfig.freeChatPerDay - chatUsedToday()).clamp(0, 9999);

  static String monthResetLabel() {
    final now = DateTime.now();
    final next = DateTime(now.year, now.month + 1, 1);
    return '${next.day} ${_monthName(next.month)}';
  }

  static String _monthName(int m) => const [
        '',
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ][m];

  /// Record one use. [idem] dedupes retries/double-taps within 60s.
  static void consume(String kind, String window, {String? idem}) {
    try {
      final box = _box();
      if (idem != null) {
        final seenKey = 'seen:$idem';
        final seenAt = box.get(seenKey) as int?;
        final nowMs = DateTime.now().millisecondsSinceEpoch;
        if (seenAt != null && nowMs - seenAt < 60000) return;
        box.put(seenKey, nowMs);
      }
      final k = _key(kind, window);
      box.put(k, (box.get(k, defaultValue: 0) as int) + 1);
    } catch (_) {}
  }

  static void consumeScan({String? idem}) =>
      consume('photo', _monthKey(DateTime.now()), idem: idem);
  static void consumeBarcode({String? idem}) =>
      consume('barcode', _monthKey(DateTime.now()), idem: idem);
  static void consumeChat({String? idem}) =>
      consume('chat', _dayKey(DateTime.now()), idem: idem);
}
