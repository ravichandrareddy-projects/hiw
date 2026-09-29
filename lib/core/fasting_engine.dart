// lib/core/fasting_engine.dart — intermittent fasting timer + history.
// State in SharedPreferences (survives reboot); ring reads live elapsed.
import 'package:shared_preferences/shared_preferences.dart';

class FastPreset {
  final String label;
  final Duration fast;
  const FastPreset(this.label, this.fast);
  static const list = [
    FastPreset('12:12', Duration(hours: 12)),
    FastPreset('14:10', Duration(hours: 14)),
    FastPreset('16:8', Duration(hours: 16)),
    FastPreset('18:6', Duration(hours: 18)),
    FastPreset('20:4', Duration(hours: 20)),
  ];
}

class FastingEngine {
  static const _startKey = 'fast_start_ms';
  static const _lenKey = 'fast_len_min';
  static const _histKey = 'fast_history'; // "startMs>endMs>done" entries

  static Future<DateTime?> activeStart() async {
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt(_startKey);
    return ms == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  static Future<int> activeLengthMin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_lenKey) ?? 16 * 60;
  }

  static Future<bool> isActive() async => activeStart() != null;

  static Future<void> start(Duration length) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
        _startKey, DateTime.now().millisecondsSinceEpoch);
    await prefs.setInt(_lenKey, length.inMinutes);
  }

  /// Ends the fast, records history, returns completed full fast or not.
  static Future<bool> end({bool completed = true}) async {
    final prefs = await SharedPreferences.getInstance();
    final start = await activeStart();
    final lenMin = await activeLengthMin();
    await prefs.remove(_startKey);
    await prefs.remove(_lenKey);
    if (start != null) {
      final hist = prefs.getStringList(_histKey) ?? [];
      final end = DateTime.now();
      final full = end.difference(start).inMinutes >= lenMin;
      hist.add(
          '${start.millisecondsSinceEpoch}>${end.millisecondsSinceEpoch}>${full && completed}');
      await prefs.setStringList(
          _histKey, hist.length > 90 ? hist.sublist(hist.length - 90) : hist);
      return full && completed;
    }
    return false;
  }

  static Future<List<String>> history() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_histKey) ?? [];
  }

  static double progress(DateTime start, int lenMin, DateTime now) {
    final total = lenMin * 60;
    if (total <= 0) return 0;
    return (now.difference(start).inSeconds / total).clamp(0.0, 1.0);
  }

  static String remainingLabel(
      DateTime start, int lenMin, DateTime now) {
    final end = start.add(Duration(minutes: lenMin));
    final left = end.difference(now);
    if (left.isNegative) return 'Done — tap to finish 🎉';
    final h = left.inHours;
    final m = left.inMinutes % 60;
    final s = left.inSeconds % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}
