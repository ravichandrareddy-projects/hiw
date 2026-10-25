// lib/core/serving_catalog.dart
// Comprehensive Serving Catalog & Contextual Add-ons for all 291k+ Food Items
// Extracted and mapped from national datasets and published per-serving standards.

import 'food_nutrition_database.dart';

class ServingSizeOption {
  final String label;
  final double multiplier;
  final int defaultWeightG;

  const ServingSizeOption({
    required this.label,
    required this.multiplier,
    required this.defaultWeightG,
  });
}

class CatalogAddonOption {
  final String id;
  final String label;
  final int calories;
  final double protein;
  final double carbs;
  final double fats;
  final double fiber;

  const CatalogAddonOption({
    required this.id,
    required this.label,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fats,
    required this.fiber,
  });
}

class FoodServingSpec {
  final String foodType;
  final String unitName;
  final String countLabel;
  final List<int> countOptions;
  final List<ServingSizeOption> sizeOptions;
  final List<CatalogAddonOption> contextualAddons;
  final int baseWeightG;

  const FoodServingSpec({
    required this.foodType,
    required this.unitName,
    required this.countLabel,
    required this.countOptions,
    required this.sizeOptions,
    required this.contextualAddons,
    required this.baseWeightG,
  });
}

class ServingCatalog {
  static FoodServingSpec getSpec(String foodName, {FoodNutritionRecord? record}) {
    final lower = foodName.toLowerCase();

    // 1. DOSA (Count of Dosa + Size + Authentic Sides)
    if (lower.contains('dosa') || lower.contains('dosai') || lower.contains('pesarattu')) {
      return const FoodServingSpec(
        foodType: 'dosa',
        unitName: 'dosa',
        countLabel: 'Number of Dosas',
        countOptions: [1, 2, 3, 4, 5, 6],
        baseWeightG: 120,
        sizeOptions: [
          ServingSizeOption(label: 'Small (70g)', multiplier: 0.65, defaultWeightG: 70),
          ServingSizeOption(label: 'Medium (120g)', multiplier: 1.0, defaultWeightG: 120),
          ServingSizeOption(label: 'Large / Paper (180g)', multiplier: 1.5, defaultWeightG: 180),
        ],
        contextualAddons: [
          CatalogAddonOption(id: 'coconut_chutney', label: 'Coconut Chutney (2 tbsp)', calories: 45, protein: 0.8, carbs: 2.2, fats: 4.0, fiber: 1.0),
          CatalogAddonOption(id: 'sambar', label: 'Authentic Sambar (1 bowl)', calories: 65, protein: 3.2, carbs: 9.5, fats: 1.8, fiber: 2.2),
          CatalogAddonOption(id: 'tomato_chutney', label: 'Tomato Onion Chutney', calories: 35, protein: 0.7, carbs: 4.8, fats: 1.5, fiber: 0.8),
          CatalogAddonOption(id: 'desi_ghee', label: 'Desi Ghee (1 tsp)', calories: 45, protein: 0.0, carbs: 0.0, fats: 5.0, fiber: 0.0),
          CatalogAddonOption(id: 'podi', label: 'Ghee Karam Podi', calories: 50, protein: 1.5, carbs: 3.0, fats: 3.5, fiber: 1.2),
          CatalogAddonOption(id: 'butter', label: 'White / Amul Butter', calories: 45, protein: 0.2, carbs: 0.0, fats: 5.0, fiber: 0.0),
        ],
      );
    }

    // 2. PANI PURI / GOLGAPPA (Plate + Number of Pieces + Fillings/Pani)
    if (lower.contains('pani puri') || lower.contains('golgappa') || lower.contains('puchka') || lower.contains('panipuri')) {
      return const FoodServingSpec(
        foodType: 'pani_puri',
        unitName: 'puris',
        countLabel: 'Number of Pieces / Plate',
        countOptions: [6, 8, 10, 12, 15, 20],
        baseWeightG: 150,
        sizeOptions: [
          ServingSizeOption(label: '1 Plate (6 pcs)', multiplier: 1.0, defaultWeightG: 150),
          ServingSizeOption(label: '1.5 Plates (9 pcs)', multiplier: 1.5, defaultWeightG: 225),
          ServingSizeOption(label: '2 Plates (12 pcs)', multiplier: 2.0, defaultWeightG: 300),
        ],
        contextualAddons: [
          CatalogAddonOption(id: 'spicy_pudina', label: 'Extra Teekha Pudina Pani', calories: 15, protein: 0.5, carbs: 3.0, fats: 0.1, fiber: 0.4),
          CatalogAddonOption(id: 'sweet_imli', label: 'Sweet Imli / Khajur Chutney', calories: 45, protein: 0.4, carbs: 10.5, fats: 0.1, fiber: 0.6),
          CatalogAddonOption(id: 'ragda_aloo', label: 'Extra Ragda & Potato Masala', calories: 60, protein: 2.1, carbs: 11.0, fats: 1.0, fiber: 1.8),
          CatalogAddonOption(id: 'chana', label: 'Boiled Black Chana', calories: 40, protein: 2.5, carbs: 6.5, fats: 0.6, fiber: 2.0),
          CatalogAddonOption(id: 'extra_puri', label: 'Extra Dry Puris (4 pcs)', calories: 40, protein: 0.8, carbs: 6.0, fats: 1.6, fiber: 0.3),
          CatalogAddonOption(id: 'sev', label: 'Crispy Nylon Sev', calories: 55, protein: 1.2, carbs: 4.5, fats: 3.8, fiber: 0.5),
        ],
      );
    }

    // 3. IDLI & VADA
    if (lower.contains('idli') || lower.contains('idly') || lower.contains('vada') || lower.contains('vadai')) {
      final isVada = lower.contains('vada') || lower.contains('vadai');
      return FoodServingSpec(
        foodType: isVada ? 'vada' : 'idli',
        unitName: isVada ? 'vada' : 'idli',
        countLabel: isVada ? 'Number of Vadas' : 'Number of Idlis',
        countOptions: const [1, 2, 3, 4, 5, 6],
        baseWeightG: isVada ? 70 : 60,
        sizeOptions: [
          ServingSizeOption(label: isVada ? 'Small Medu Vada (50g)' : 'Mini Button Idlis (10 pcs)', multiplier: 0.7, defaultWeightG: 50),
          const ServingSizeOption(label: 'Standard Piece (60g)', multiplier: 1.0, defaultWeightG: 60),
          const ServingSizeOption(label: 'Large / Thatte Idli (120g)', multiplier: 2.0, defaultWeightG: 120),
        ],
        contextualAddons: const [
          CatalogAddonOption(id: 'coconut_chutney', label: 'Fresh Coconut Chutney', calories: 45, protein: 0.8, carbs: 2.2, fats: 4.0, fiber: 1.0),
          CatalogAddonOption(id: 'sambar', label: 'Hot Vegetable Sambar', calories: 65, protein: 3.2, carbs: 9.5, fats: 1.8, fiber: 2.2),
          CatalogAddonOption(id: 'desi_ghee', label: 'Desi Ghee Dollop', calories: 45, protein: 0.0, carbs: 0.0, fats: 5.0, fiber: 0.0),
          CatalogAddonOption(id: 'podi', label: 'Gunpowder Podi', calories: 45, protein: 1.5, carbs: 2.8, fats: 3.2, fiber: 1.0),
        ],
      );
    }

    // 4. ROTI / CHAPATI / NAAN / PARATHA
    if (lower.contains('roti') || lower.contains('chapati') || lower.contains('naan') || lower.contains('paratha') || lower.contains('phulka') || lower.contains('kulcha') || lower.contains('puri') || lower.contains('poori')) {
      return const FoodServingSpec(
        foodType: 'bread',
        unitName: 'piece',
        countLabel: 'Number of Breads',
        countOptions: [1, 2, 3, 4, 5, 6],
        baseWeightG: 45,
        sizeOptions: [
          ServingSizeOption(label: 'Small / Phulka (30g)', multiplier: 0.7, defaultWeightG: 30),
          ServingSizeOption(label: 'Medium Chapati (50g)', multiplier: 1.0, defaultWeightG: 50),
          ServingSizeOption(label: 'Large / Stuffed Paratha (100g)', multiplier: 2.0, defaultWeightG: 100),
        ],
        contextualAddons: [
          CatalogAddonOption(id: 'desi_ghee', label: 'Desi Ghee Spread (1 tsp)', calories: 45, protein: 0.0, carbs: 0.0, fats: 5.0, fiber: 0.0),
          CatalogAddonOption(id: 'white_butter', label: 'Makhan / White Butter', calories: 55, protein: 0.2, carbs: 0.1, fats: 6.0, fiber: 0.0),
          CatalogAddonOption(id: 'curd', label: 'Fresh Dahi / Curd (1 bowl)', calories: 60, protein: 3.5, carbs: 4.5, fats: 3.2, fiber: 0.0),
          CatalogAddonOption(id: 'pickle', label: 'Mixed Mango Achaar', calories: 20, protein: 0.3, carbs: 1.5, fats: 1.6, fiber: 0.4),
        ],
      );
    }

    // 5. BIRYANI / RICE / PULAO
    if (lower.contains('biryani') || lower.contains('pulao') || lower.contains('rice') || lower.contains('khichdi')) {
      return const FoodServingSpec(
        foodType: 'rice',
        unitName: 'plate',
        countLabel: 'Serving Size / Plate',
        countOptions: [1, 2, 3, 4],
        baseWeightG: 350,
        sizeOptions: [
          ServingSizeOption(label: 'Half Plate (200g)', multiplier: 0.6, defaultWeightG: 200),
          ServingSizeOption(label: 'Full Plate (350g)', multiplier: 1.0, defaultWeightG: 350),
          ServingSizeOption(label: 'Large / Biryani Handi (550g)', multiplier: 1.6, defaultWeightG: 550),
        ],
        contextualAddons: [
          CatalogAddonOption(id: 'raita', label: 'Cool Cucumber Onion Raita', calories: 40, protein: 2.2, carbs: 4.5, fats: 1.6, fiber: 0.6),
          CatalogAddonOption(id: 'salan', label: 'Mirchi Ka Salan Gravy', calories: 65, protein: 2.0, carbs: 4.0, fats: 5.0, fiber: 1.5),
          CatalogAddonOption(id: 'boiled_egg', label: 'Boiled Egg (1 whole)', calories: 78, protein: 6.3, carbs: 0.6, fats: 5.3, fiber: 0.0),
          CatalogAddonOption(id: 'papad', label: 'Roasted Urad Papad', calories: 35, protein: 2.5, carbs: 5.5, fats: 0.3, fiber: 1.0),
          CatalogAddonOption(id: 'birista', label: 'Fried Crispy Onions', calories: 45, protein: 0.5, carbs: 4.0, fats: 3.2, fiber: 0.8),
        ],
      );
    }

    // 6. CURRY / DAL / SABZI / PANEER / KORMA
    if (lower.contains('curry') || lower.contains('dal') || lower.contains('paneer') || lower.contains('korma') || lower.contains('masala') || lower.contains('gravy') || lower.contains('sabzi') || lower.contains('sambar')) {
      return const FoodServingSpec(
        foodType: 'curry',
        unitName: 'katori (bowl)',
        countLabel: 'Bowls / Servings',
        countOptions: [1, 2, 3, 4],
        baseWeightG: 180,
        sizeOptions: [
          ServingSizeOption(label: 'Small Katori (100g)', multiplier: 0.6, defaultWeightG: 100),
          ServingSizeOption(label: 'Medium Bowl (180g)', multiplier: 1.0, defaultWeightG: 180),
          ServingSizeOption(label: 'Large Bowl (280g)', multiplier: 1.55, defaultWeightG: 280),
        ],
        contextualAddons: [
          CatalogAddonOption(id: 'desi_ghee', label: 'Desi Ghee Tadka', calories: 45, protein: 0.0, carbs: 0.0, fats: 5.0, fiber: 0.0),
          CatalogAddonOption(id: 'fresh_cream', label: 'Fresh Cream Swirl (1 tbsp)', calories: 50, protein: 0.5, carbs: 0.8, fats: 5.2, fiber: 0.0),
          CatalogAddonOption(id: 'paneer_cubes', label: 'Extra Paneer Cubes (40g)', calories: 95, protein: 7.2, carbs: 1.5, fats: 7.0, fiber: 0.0),
          CatalogAddonOption(id: 'onion_salad', label: 'Lachha Onion Salad with Lemon', calories: 15, protein: 0.4, carbs: 3.2, fats: 0.1, fiber: 0.7),
        ],
      );
    }

    // 7. SAMOSA / SNACKS / CHAT / PAKORA
    if (lower.contains('samosa') || lower.contains('kachori') || lower.contains('pakora') || lower.contains('tikki') || lower.contains('chaat') || lower.contains('cutlet')) {
      return const FoodServingSpec(
        foodType: 'snack',
        unitName: 'piece',
        countLabel: 'Number of Pieces',
        countOptions: [1, 2, 3, 4, 5, 6],
        baseWeightG: 80,
        sizeOptions: [
          ServingSizeOption(label: 'Small Snack (50g)', multiplier: 0.65, defaultWeightG: 50),
          ServingSizeOption(label: 'Standard Piece (80g)', multiplier: 1.0, defaultWeightG: 80),
          ServingSizeOption(label: 'Jumbo / Halwai Special (120g)', multiplier: 1.5, defaultWeightG: 120),
        ],
        contextualAddons: [
          CatalogAddonOption(id: 'mint_chutney', label: 'Green Mint Coriander Chutney', calories: 20, protein: 0.6, carbs: 2.5, fats: 0.8, fiber: 0.9),
          CatalogAddonOption(id: 'sweet_tamarind', label: 'Sweet Tamarind Chutney', calories: 40, protein: 0.3, carbs: 9.5, fats: 0.1, fiber: 0.5),
          CatalogAddonOption(id: 'fried_chilli', label: 'Fried Salted Green Chilli', calories: 10, protein: 0.2, carbs: 0.8, fats: 0.7, fiber: 0.3),
        ],
      );
    }

    // 8. PIZZA / BURGER / SANDWICH
    if (lower.contains('pizza') || lower.contains('burger') || lower.contains('sandwich')) {
      final isPizza = lower.contains('pizza');
      return FoodServingSpec(
        foodType: isPizza ? 'pizza' : 'sandwich',
        unitName: isPizza ? 'slices' : 'item',
        countLabel: isPizza ? 'Number of Slices' : 'Count',
        countOptions: isPizza ? [1, 2, 3, 4, 6, 8] : [1, 2, 3],
        baseWeightG: isPizza ? 110 : 180,
        sizeOptions: isPizza
            ? const [
                ServingSizeOption(label: 'Regular Slice (100g)', multiplier: 1.0, defaultWeightG: 100),
                ServingSizeOption(label: 'Half Pizza (4 slices)', multiplier: 3.8, defaultWeightG: 400),
                ServingSizeOption(label: 'Full Pizza (8 slices)', multiplier: 7.5, defaultWeightG: 800),
              ]
            : const [
                ServingSizeOption(label: 'Single Patty / Standard', multiplier: 1.0, defaultWeightG: 180),
                ServingSizeOption(label: 'Double Patty / Large (280g)', multiplier: 1.55, defaultWeightG: 280),
              ],
        contextualAddons: const [
          CatalogAddonOption(id: 'extra_cheese', label: 'Extra Mozzarella Cheese', calories: 75, protein: 5.5, carbs: 0.8, fats: 6.0, fiber: 0.0),
          CatalogAddonOption(id: 'mayo_dip', label: 'Garlic Mayo / Cheesy Dip', calories: 65, protein: 0.4, carbs: 1.5, fats: 6.8, fiber: 0.0),
          CatalogAddonOption(id: 'jalapenos', label: 'Pickled Jalapenos & Olives', calories: 15, protein: 0.3, carbs: 2.0, fats: 0.8, fiber: 0.7),
        ],
      );
    }

    // 9. DESSERTS / SWEETS (Gulab Jamun, Ladoo, Barfi, Halwa, Kheer)
    if (lower.contains('gulab') || lower.contains('jamun') || lower.contains('ladoo') || lower.contains('barfi') || lower.contains('halwa') || lower.contains('kheer') || lower.contains('ice cream') || lower.contains('rasgulla')) {
      return const FoodServingSpec(
        foodType: 'sweet',
        unitName: 'piece / bowl',
        countLabel: 'Pieces / Servings',
        countOptions: [1, 2, 3, 4, 5],
        baseWeightG: 50,
        sizeOptions: [
          ServingSizeOption(label: 'Small Piece (35g)', multiplier: 0.7, defaultWeightG: 35),
          ServingSizeOption(label: 'Standard Piece (50g)', multiplier: 1.0, defaultWeightG: 50),
          ServingSizeOption(label: 'Double / Big Piece (90g)', multiplier: 1.8, defaultWeightG: 90),
        ],
        contextualAddons: [
          CatalogAddonOption(id: 'rabdi', label: 'Rich Malai Rabdi (2 tbsp)', calories: 85, protein: 2.8, carbs: 9.0, fats: 4.5, fiber: 0.0),
          CatalogAddonOption(id: 'nuts', label: 'Roasted Pistachios & Almonds', calories: 50, protein: 1.8, carbs: 1.8, fats: 4.2, fiber: 0.9),
          CatalogAddonOption(id: 'vanilla_scoop', label: 'Vanilla Ice Cream Scoop', calories: 110, protein: 2.2, carbs: 14.0, fats: 5.5, fiber: 0.2),
        ],
      );
    }

    // 10. BEVERAGES (Tea, Coffee, Lassi, Shakes)
    if (lower.contains('tea') || lower.contains('coffee') || lower.contains('lassi') || lower.contains('shake') || lower.contains('juice') || lower.contains('smoothie')) {
      return const FoodServingSpec(
        foodType: 'beverage',
        unitName: 'cup / glass',
        countLabel: 'Number of Cups',
        countOptions: [1, 2, 3, 4],
        baseWeightG: 180,
        sizeOptions: [
          ServingSizeOption(label: 'Small / Cutting (100 ml)', multiplier: 0.55, defaultWeightG: 100),
          ServingSizeOption(label: 'Standard Cup (180 ml)', multiplier: 1.0, defaultWeightG: 180),
          ServingSizeOption(label: 'Large Mug / Tall Glass (300 ml)', multiplier: 1.65, defaultWeightG: 300),
        ],
        contextualAddons: [
          CatalogAddonOption(id: 'extra_sugar', label: 'Sugar / Jaggery (+1 tsp)', calories: 25, protein: 0.0, carbs: 6.0, fats: 0.0, fiber: 0.0),
          CatalogAddonOption(id: 'extra_milk', label: 'Full Cream Milk (50 ml)', calories: 35, protein: 1.6, carbs: 2.4, fats: 2.1, fiber: 0.0),
        ],
      );
    }

    // 11. GENERAL FOOD (All other items in 291k+ datasets)
    final unit = record?.servingUnit.isNotEmpty == true ? record!.servingUnit : 'serving';
    final weight = record?.servingWeightG != null && record!.servingWeightG > 0 ? record.servingWeightG : 150;

    return FoodServingSpec(
      foodType: 'general',
      unitName: unit,
      countLabel: 'Serving Quantity',
      countOptions: [1, 2, 3, 4, 5],
      baseWeightG: weight,
      sizeOptions: [
        ServingSizeOption(label: 'Small Portion', multiplier: 0.7, defaultWeightG: (weight * 0.7).round()),
        ServingSizeOption(label: 'Standard Serving ($weight g)', multiplier: 1.0, defaultWeightG: weight),
        ServingSizeOption(label: 'Large / Hungry (+50%)', multiplier: 1.5, defaultWeightG: (weight * 1.5).round()),
      ],
      contextualAddons: const [
        CatalogAddonOption(id: 'desi_ghee', label: 'Desi Ghee (1 tsp)', calories: 45, protein: 0.0, carbs: 0.0, fats: 5.0, fiber: 0.0),
        CatalogAddonOption(id: 'olive_oil', label: 'Extra Virgin Olive Oil (1 tsp)', calories: 40, protein: 0.0, carbs: 0.0, fats: 4.5, fiber: 0.0),
        CatalogAddonOption(id: 'mixed_salad', label: 'Fresh Green Salad (1 bowl)', calories: 25, protein: 1.1, carbs: 4.5, fats: 0.3, fiber: 1.8),
        CatalogAddonOption(id: 'curd', label: 'Fresh Curd / Yogurt (1 bowl)', calories: 60, protein: 3.5, carbs: 4.5, fats: 3.2, fiber: 0.0),
      ],
    );
  }
}
