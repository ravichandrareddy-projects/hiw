import 'package:hive/hive.dart';
import '../hive/food_hive_model.dart';
import '../hive/history_hive_model.dart';
import '../hive/avatar_hive_model.dart';

class HiveService {
  static final foodBox = Hive.box<FoodHive>('foodBox');
  static final historyBox = Hive.box<HistoryHive>('historyBox');
  static final avatarBox = Hive.box<AvatarHive>('avatarBox');

  // FOOD
  static void addFood(FoodHive food) {
    foodBox.add(food);
  }

  static List<FoodHive> getTodayFood() {
    final today = DateTime.now();
    return foodBox.values.where((f) =>
      f.time.year == today.year &&
      f.time.month == today.month &&
      f.time.day == today.day
    ).toList();
  }

  // AVATAR
  static void saveAvatar(AvatarHive avatar) {
    avatarBox.clear();
    avatarBox.add(avatar);
  }

  static AvatarHive? loadAvatar() {
    return avatarBox.isNotEmpty ? avatarBox.values.first : null;
  }
}
