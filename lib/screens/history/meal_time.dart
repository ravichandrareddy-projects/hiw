//libs/screens/history/
enum MealType { breakfast, lunch, snack, dinner }

MealType getMealFromTime(DateTime now) {
  final hour = now.hour;
  final minute = now.minute;
  final time = hour + minute / 60.0;

  if (time >= 5 && time < 10.5) return MealType.breakfast;
  if (time >= 10.5 && time < 12.5) return MealType.snack;
  if (time >= 12.5 && time < 15.5) return MealType.lunch;
  if (time >= 15.5 && time < 18.5) return MealType.snack;
  return MealType.dinner; // includes late night
}
