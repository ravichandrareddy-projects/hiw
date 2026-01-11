import 'package:hive_flutter/hive_flutter.dart';

import 'food_hive_model.dart';
import 'history_hive_model.dart';
import 'avatar_hive_model.dart';
import 'water_hive_model.dart';

Future<void> initHive() async {
  await Hive.initFlutter();

  Hive.registerAdapter(FoodHiveAdapter());
  Hive.registerAdapter(HistoryHiveAdapter());
  Hive.registerAdapter(AvatarHiveAdapter());
  Hive.registerAdapter(WaterHiveAdapter());

  await Hive.openBox<FoodHive>('foodBox');
  await Hive.openBox<HistoryHive>('historyBox');
  await Hive.openBox<AvatarHive>('avatarBox'); // ONLY AvatarHive here
  await Hive.openBox('avatarMetaBox');         // 👈 NEW
}

