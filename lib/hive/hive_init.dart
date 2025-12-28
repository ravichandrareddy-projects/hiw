Future<void> initHive() async {
  await Hive.initFlutter();

  Hive.registerAdapter(FoodHiveAdapter());
  Hive.registerAdapter(HistoryHiveAdapter());
  Hive.registerAdapter(AvatarHiveAdapter());

  await Hive.openBox<FoodHive>('foodBox');
  await Hive.openBox<HistoryHive>('historyBox');
  await Hive.openBox<AvatarHive>('avatarBox');

  // 🔥 NEW — daily nutrition summary
  await Hive.openBox('dailyNutritionBox');
}
