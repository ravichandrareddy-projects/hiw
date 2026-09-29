// lib/core/subscription/plan.dart
// THE single source of subscription truth. No prices/limits anywhere else.
class PlanConfig {
  // Prices (INR).
  static const int monthlyPaise = 11900;
  static const int annualPaise = 89900;
  static const String monthlyLabel = '₹119/month';
  static const String annualLabel = '₹899/year';
  static const int trialDays = 7;

  // Free quotas.
  static const int freeScansPerMonth = 40;
  static const int freeBarcodePerMonth = 20;
  static const int freeChatPerDay = 5;
  static const int freeComboFoods = 3;

  // Identifiers (Play Console SKUs — created there when ready).
  static const String skuMonthly = 'hiw_pro_monthly';
  static const String skuAnnual = 'hiw_pro_annual';

  static String priceLabel(bool annual) =>
      annual ? annualLabel : monthlyLabel;
}

enum Tier { free, pro }

enum Feature {
  photoScan,
  barcodeScan,
  chat,
  comboPlate, // >3 foods per scan
  customMacros,
  fasting,
  mealPlans,
  trends,
  gaps,
  export,
}
