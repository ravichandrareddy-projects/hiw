// lib/services/cloud_sync_service.dart
// Cloud synchronization for HIW with Supabase.
// Syncs meal logs, daily health profile targets, and streaks.
// Completely safe offline: if Supabase is unconfigured or offline,
// calls silently no-op and local Hive/SharedPreferences continue unaffected.

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/backend_config.dart';

class CloudSyncService {
  static final CloudSyncService _instance = CloudSyncService._internal();
  factory CloudSyncService() => _instance;
  CloudSyncService._internal();

  SupabaseClient? get _client =>
      BackendConfig.hasSupabase ? Supabase.instance.client : null;

  String? get currentUserId => _client?.auth.currentUser?.id;

  /// Syncs an individual food/meal log to Supabase 'meal_logs' table.
  Future<bool> syncMealLog({
    required String foodName,
    required int calories,
    double protein = 0,
    double carbs = 0,
    double fats = 0,
    String mealType = 'snack',
  }) async {
    final client = _client;
    final userId = currentUserId;
    if (client == null || userId == null) return false;

    try {
      await client.from('meal_logs').insert({
        'user_id': userId,
        'food_name': foodName,
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fats': fats,
        'meal_type': mealType,
        'logged_at': DateTime.now().toUtc().toIso8601String(),
      });
      debugPrint('☁️ Synced meal to Supabase: $foodName ($calories kcal)');
      return true;
    } catch (e) {
      debugPrint('⚠️ Meal cloud sync error: $e');
      return false;
    }
  }

  /// Syncs user profile targets (calorie goals, streak, water) to 'profiles' table.
  Future<bool> syncUserProfile({
    String? username,
    int? dailyCalories,
    int? streak,
    int? waterGoalMl,
  }) async {
    final client = _client;
    final userId = currentUserId;
    if (client == null || userId == null) return false;

    final updates = <String, dynamic>{
      'id': userId,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    if (username != null) updates['username'] = username;
    if (dailyCalories != null) updates['daily_calories'] = dailyCalories;
    if (streak != null) updates['streak'] = streak;
    if (waterGoalMl != null) updates['water_goal_ml'] = waterGoalMl;

    try {
      await client.from('profiles').upsert(updates);
      debugPrint('☁️ Synced profile to Supabase');
      return true;
    } catch (e) {
      debugPrint('⚠️ Profile cloud sync error: $e');
      return false;
    }
  }

  /// Fetches meal history from Supabase for the logged-in user.
  Future<List<Map<String, dynamic>>> fetchRemoteMealLogs({int limit = 50}) async {
    final client = _client;
    final userId = currentUserId;
    if (client == null || userId == null) return [];

    try {
      final response = await client
          .from('meal_logs')
          .select()
          .eq('user_id', userId)
          .order('logged_at', ascending: false)
          .limit(limit);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('⚠️ Fetch remote meal logs error: $e');
      return [];
    }
  }
}
