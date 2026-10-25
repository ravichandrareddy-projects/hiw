// lib/core/progression_engine.dart — XP, level curve, achievements, and progression events.
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class XPEvent {
  final String id;
  final String title;
  final int xp;
  final DateTime timestamp;
  final String category; // 'meal', 'water', 'habit', 'streak', 'checkin', 'index'

  const XPEvent({
    required this.id,
    required this.title,
    required this.xp,
    required this.timestamp,
    required this.category,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'xp': xp,
        'timestamp': timestamp.toIso8601String(),
        'category': category,
      };

  factory XPEvent.fromJson(Map<String, dynamic> json) => XPEvent(
        id: json['id'] as String,
        title: json['title'] as String,
        xp: json['xp'] as int,
        timestamp: DateTime.parse(json['timestamp'] as String),
        category: json['category'] as String,
      );
}

class LevelModel {
  final int level;
  final int totalXP;
  final int currentLevelXP;
  final int xpToNextLevel;
  final double progress; // 0.0 to 1.0

  const LevelModel({
    required this.level,
    required this.totalXP,
    required this.currentLevelXP,
    required this.xpToNextLevel,
    required this.progress,
  });

  String get title {
    if (level < 3) return 'Health Explorer';
    if (level < 6) return 'Habit Builder';
    if (level < 10) return 'Consistency Achiever';
    if (level < 15) return 'Wellness Warrior';
    if (level < 25) return 'Nutrition Champion';
    return 'HIW Legend';
  }
}

class Achievement {
  final String id;
  final String title;
  final String description;
  final String icon;
  final bool unlocked;
  final int xpReward;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.unlocked,
    required this.xpReward,
  });
}

class ProgressionEngine extends ChangeNotifier {
  static final ProgressionEngine _instance = ProgressionEngine._internal();
  factory ProgressionEngine() => _instance;
  ProgressionEngine._internal();

  static const _totalXPKey = 'hiw_progression_total_xp';
  static const _eventsKey = 'hiw_progression_events';
  static const _achievementsKey = 'hiw_progression_achievements';

  int _totalXP = 0;
  final List<XPEvent> _recentEvents = [];
  final Set<String> _unlockedAchievementIds = {};
  bool _initialized = false;

  int get totalXP => _totalXP;
  List<XPEvent> get recentEvents => List.unmodifiable(_recentEvents);

  Future<void> init() async {
    if (_initialized) return;
    final prefs = await SharedPreferences.getInstance();
    _totalXP = prefs.getInt(_totalXPKey) ?? 0;

    final eventsRaw = prefs.getStringList(_eventsKey) ?? [];
    _recentEvents.clear();
    for (final raw in eventsRaw) {
      try {
        _recentEvents.add(XPEvent.fromJson(jsonDecode(raw) as Map<String, dynamic>));
      } catch (_) {}
    }

    final achRaw = prefs.getStringList(_achievementsKey) ?? [];
    _unlockedAchievementIds.clear();
    _unlockedAchievementIds.addAll(achRaw);

    _initialized = true;
    notifyListeners();
  }

  /// Calculates XP threshold required to complete a given level:
  /// Formula: 100 * (level ^ 1.4)
  static int xpForLevel(int level) {
    if (level <= 1) return 100;
    return (100 * math.pow(level, 1.4)).round();
  }

  /// Computes current level and progress from total cumulative XP
  LevelModel get levelModel {
    int lvl = 1;
    int xpRemaining = _totalXP;
    int threshold = xpForLevel(lvl);

    while (xpRemaining >= threshold) {
      xpRemaining -= threshold;
      lvl++;
      threshold = xpForLevel(lvl);
    }

    final double prog = threshold > 0 ? (xpRemaining / threshold).clamp(0.0, 1.0) : 0.0;

    return LevelModel(
      level: lvl,
      totalXP: _totalXP,
      currentLevelXP: xpRemaining,
      xpToNextLevel: threshold,
      progress: prog,
    );
  }

  int get currentLevel => levelModel.level;

  /// Award XP for a health habit or consistency action.
  /// Returns `true` if a level-up was triggered.
  Future<bool> awardXP(
    int amount, {
    required String title,
    required String category,
  }) async {
    await init();
    if (amount <= 0) return false;

    final prevLevel = levelModel.level;
    _totalXP += amount;

    final event = XPEvent(
      id: '${DateTime.now().millisecondsSinceEpoch}_${math.Random().nextInt(1000)}',
      title: title,
      xp: amount,
      timestamp: DateTime.now(),
      category: category,
    );

    _recentEvents.insert(0, event);
    if (_recentEvents.length > 30) {
      _recentEvents.removeRange(30, _recentEvents.length);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_totalXPKey, _totalXP);
    await prefs.setStringList(
      _eventsKey,
      _recentEvents.map((e) => jsonEncode(e.toJson())).toList(),
    );

    notifyListeners();

    final newLevel = levelModel.level;
    return newLevel > prevLevel;
  }

  List<Achievement> get achievements {
    final curLevel = levelModel.level;
    final total = _totalXP;

    final defs = [
      Achievement(
        id: 'first_log',
        title: 'First Step',
        description: 'Log your very first meal or food item in HIW.',
        icon: '🌱',
        unlocked: _unlockedAchievementIds.contains('first_log') || total > 0,
        xpReward: 20,
      ),
      Achievement(
        id: 'water_pioneer',
        title: 'Hydration Pioneer',
        description: 'Reach 8 water glasses logged in a single day.',
        icon: '💧',
        unlocked: _unlockedAchievementIds.contains('water_pioneer'),
        xpReward: 30,
      ),
      Achievement(
        id: 'streak_3',
        title: 'Consistency Spark',
        description: 'Maintain a 3-day active tracking streak.',
        icon: '🔥',
        unlocked: _unlockedAchievementIds.contains('streak_3'),
        xpReward: 50,
      ),
      Achievement(
        id: 'streak_7',
        title: 'Habit Champion',
        description: 'Complete 7 consecutive streak days with HIW.',
        icon: '🏆',
        unlocked: _unlockedAchievementIds.contains('streak_7'),
        xpReward: 100,
      ),
      Achievement(
        id: 'level_5',
        title: 'Rising Warrior',
        description: 'Advance to Level 5.',
        icon: '⭐',
        unlocked: curLevel >= 5,
        xpReward: 75,
      ),
      Achievement(
        id: 'level_10',
        title: 'Master of Health',
        description: 'Reach Level 10 through daily discipline.',
        icon: '👑',
        unlocked: curLevel >= 10,
        xpReward: 150,
      ),
    ];

    return defs;
  }

  Future<void> unlockAchievement(String id) async {
    await init();
    if (_unlockedAchievementIds.add(id)) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_achievementsKey, _unlockedAchievementIds.toList());
      notifyListeners();
    }
  }
}
