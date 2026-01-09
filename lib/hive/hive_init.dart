//lib/hive/hive_init.dart
import 'package:hive_flutter/hive_flutter.dart';

import 'food_hive_model.dart';
import 'history_hive_model.dart';
import 'avatar_hive_model.dart';
import 'water_hive_model.dart'; // 🆕 ADD THIS

Future<void> initHive() async {
  await Hive.initFlutter();

  // -------------------------
  // REGISTER ADAPTERS
  // -------------------------
  Hive.registerAdapter(FoodHiveAdapter());
  Hive.registerAdapter(HistoryHiveAdapter());
  Hive.registerAdapter(AvatarHiveAdapter());
  Hive.registerAdapter(WaterHiveAdapter()); // 🆕 ADD THIS

  // -------------------------
  // OPEN BOXES
  // -------------------------
  await Hive.openBox<FoodHive>('foodBox');
  await Hive.openBox<HistoryHive>('historyBox');
  await Hive.openBox<AvatarHive>('avatarBox');

  await Hive.openBox<WaterHive>('waterBox'); // 🧴 THIS IS WHAT YOU ASKED
}
