import 'package:hive_flutter/hive_flutter.dart';

import 'food_hive_model.dart';
import 'history_hive_model.dart';
import 'avatar_hive_model.dart';
import 'water_hive_model.dart';
import 'chat_hive_model.dart'; // 🆕 Chat history model

Future<void> initHive() async {
  await Hive.initFlutter();

  // -------------------------
  // REGISTER ADAPTERS
  // -------------------------
  Hive.registerAdapter(FoodHiveAdapter());
  Hive.registerAdapter(HistoryHiveAdapter());
  Hive.registerAdapter(AvatarHiveAdapter());
  Hive.registerAdapter(WaterHiveAdapter());
  Hive.registerAdapter(ChatHiveAdapter()); // 🆕 Chat history adapter

  // -------------------------
  // OPEN BOXES
  // -------------------------
  await Hive.openBox<FoodHive>('foodBox');
  await Hive.openBox<HistoryHive>('historyBox');
  await Hive.openBox<AvatarHive>('avatarBox');
  await Hive.openBox('waterBox'); // 💧 Generic box for primitive keys

  // 🔥 META BOXES (CRITICAL)
  await Hive.openBox('metaBox');        // 👈 for calories, profile data
  await Hive.openBox('avatarMetaBox');  // 👈 for avatar metadata
  await Hive.openBox('quotas');         // 👈 subscription usage counters
}