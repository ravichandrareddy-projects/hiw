import 'food_item.dart';

class HealthEngine {
  double health = 70;
  double energy = 70;
  double stamina = 70;

  void applyFood(FoodItem food) {
    // Late night penalty
    if (food.mealType == MealType.lateNight) {
      health -= 2;
      energy -= 3;
    } else {
      energy += 1;
    }

    // Protein bonus
    if (food.protein > 15) {
      stamina += 1;
    }

    _clamp();
  }

  void _clamp() {
    health = health.clamp(0, 100);
    energy = energy.clamp(0, 100);
    stamina = stamina.clamp(0, 100);
  }
}
