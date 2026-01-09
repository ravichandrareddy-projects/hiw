enum AddonType {
  counter,
  toggle,
  singleChoice,
  multiChoice,
}

class FoodAddonOption {
  final String id;
  final String label;

  const FoodAddonOption({
    required this.id,
    required this.label,
  });
}

class FoodAddon {
  final String id;
  final String title;
  final AddonType type;
  final int min;
  final int max;
  final List<FoodAddonOption> options;

  const FoodAddon({
    required this.id,
    required this.title,
    required this.type,
    this.min = 0,
    this.max = 10,
    this.options = const [],
  });
}

final Map<String, List<FoodAddon>> foodAddons = {
  // -------- BREAKFAST --------
  "dosa": [
    FoodAddon(id: "count", title: "Number of Dosa", type: AddonType.counter, min: 1, max: 6),
    FoodAddon(
      id: "sides",
      title: "Sides",
      type: AddonType.multiChoice,
      options: [
        FoodAddonOption(id: "chutney", label: "Chutney"),
        FoodAddonOption(id: "sambar", label: "Sambar"),
      ],
    ),
  ],

  "idli": [
    FoodAddon(id: "count", title: "Number of Idli", type: AddonType.counter, min: 1, max: 6),
    FoodAddon(
      id: "sides",
      title: "Sides",
      type: AddonType.multiChoice,
      options: [
        FoodAddonOption(id: "chutney", label: "Chutney"),
        FoodAddonOption(id: "sambar", label: "Sambar"),
      ],
    ),
  ],

  "vada": [
    FoodAddon(id: "count", title: "Number of Vada", type: AddonType.counter, min: 1, max: 6),
  ],

  "boiled_egg": [
    FoodAddon(id: "count", title: "Egg Count", type: AddonType.counter, min: 1, max: 6),
  ],

  "omelette": [
    FoodAddon(
      id: "eggs",
      title: "Egg Count",
      type: AddonType.singleChoice,
      options: [
        FoodAddonOption(id: "1", label: "Single Egg"),
        FoodAddonOption(id: "2", label: "Double Egg"),
      ],
    ),
  ],

  // -------- LUNCH / DINNER --------
  "chicken_biryani": [
    FoodAddon(id: "plate", title: "Plates", type: AddonType.counter, min: 1, max: 3),
  ],

  "dal_curry": [
    FoodAddon(id: "serving", title: "Servings", type: AddonType.counter, min: 1, max: 3),
  ],

  "rice": [
    FoodAddon(id: "plate", title: "Plates", type: AddonType.counter, min: 1, max: 3),
  ],

  "roti": [
    FoodAddon(id: "count", title: "Number of Roti", type: AddonType.counter, min: 1, max: 8),
  ],

  "sambar": [
    FoodAddon(id: "bowl", title: "Bowls", type: AddonType.counter, min: 1, max: 3),
  ],

  "puri": [
    FoodAddon(id: "count", title: "Number of Puri", type: AddonType.counter, min: 1, max: 6),
  ],

  // -------- FAST FOOD --------
  "burger": [
    FoodAddon(
      id: "type",
      title: "Burger Type",
      type: AddonType.singleChoice,
      options: [
        FoodAddonOption(id: "veg", label: "Veg"),
        FoodAddonOption(id: "chicken", label: "Chicken"),
      ],
    ),
  ],

  "pizza": [
    FoodAddon(
      id: "size",
      title: "Pizza Size",
      type: AddonType.singleChoice,
      options: [
        FoodAddonOption(id: "small", label: "Small"),
        FoodAddonOption(id: "medium", label: "Medium"),
        FoodAddonOption(id: "large", label: "Large"),
      ],
    ),
  ],

  "noodles": [
    FoodAddon(
      id: "type",
      title: "Noodles Type",
      type: AddonType.singleChoice,
      options: [
        FoodAddonOption(id: "veg", label: "Veg"),
        FoodAddonOption(id: "egg", label: "Egg"),
        FoodAddonOption(id: "chicken", label: "Chicken"),
      ],
    ),
  ],

  "samosa": [
    FoodAddon(id: "count", title: "Number of Samosa", type: AddonType.counter, min: 1, max: 6),
  ],

  // -------- SWEETS / DRINKS --------
  "gulab_jamun": [
    FoodAddon(id: "count", title: "Pieces", type: AddonType.counter, min: 1, max: 6),
  ],

  "jalebi": [
    FoodAddon(id: "count", title: "Pieces", type: AddonType.counter, min: 1, max: 6),
  ],

  "soft_drinks": [
    FoodAddon(id: "glass", title: "Glasses", type: AddonType.counter, min: 1, max: 3),
  ],

  "mango_pickle": [
    FoodAddon(id: "spoon", title: "Spoons", type: AddonType.counter, min: 1, max: 3),
  ],
};
