// lib/core/food_search_service.dart
// DB-first search: canonical name + regional aliases + fuzzy matching.
// No duplicate Food records for spelling variations.
import 'food_nutrition_database.dart';

class FoodSearchHit {
  final FoodNutritionRecord record;
  final double score; // 0..100
  final String? matchedAlias;
  const FoodSearchHit({
    required this.record,
    required this.score,
    this.matchedAlias,
  });
}

/// Regional / alternate spellings → canonical-ish keys.
/// Values are matched against normalized DB names; add more over time.
const Map<String, List<String>> kFoodAliases = {
  'pesarattu': ['pesara dosa', 'pesarattu', 'moong dal dosa', 'green gram dosa'],
  'masala dosa': ['masala dosa', 'mysore dosa', 'plain dosa', 'dosa'],
  'idli': ['idli', 'idly', 'idle'],
  'chicken biryani': ['chicken biryani', 'biryani', 'chicken biriyani', 'biriyani'],
  'hyderabadi biryani': ['hyderabadi biryani', 'hyderabadi biriyani'],
  'mutton biryani': ['mutton biryani', 'mutton biriyani'],
  'veg biryani': ['veg biryani', 'vegetable biryani', 'veg biriyani'],
  'egg biryani': ['egg biryani', 'egg biriyani'],
  'paneer biryani': ['paneer biryani'],
  'roti': ['roti', 'chapati', 'chapathi', 'phulka'],
  'boiled egg': ['boiled egg', 'boil egg', 'boild egg'],
  'noodles': ['noodles', 'noodils', 'noodle'],
  'mango pickle': ['mango pickle', 'mangopickle', 'mango pickle'],
  'gulab jamun': ['gulab jamun', 'gulabjamun'],
  'sambar': ['sambar', 'sambhar'],
};

String normalizeFoodQuery(String input) {
  var s = input.toLowerCase().trim();
  s = s.replaceAll(RegExp(r'[_-]+'), ' ');
  s = s.replaceAll(RegExp(r'[^a-z0-9 ]'), '');
  s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
  // tiny plural strip (dosas -> dosa) — keep it conservative
  s = s.split(' ').map((w) {
    if (w.length > 4 && w.endsWith('s') && !w.endsWith('ss')) {
      return w.substring(0, w.length - 1);
    }
    return w;
  }).join(' ');
  // known typo fixes
  const fixes = {
    'idly': 'idli',
    'boild egg': 'boiled egg',
    'noodil': 'noodle',
  };
  return fixes[s] ?? s;
}

int _levenshtein(String a, String b) {
  if (a == b) return 0;
  if (a.isEmpty) return b.length;
  if (b.isEmpty) return a.length;
  final prev = List<int>.generate(b.length + 1, (i) => i);
  final curr = List<int>.filled(b.length + 1, 0);
  for (var i = 1; i <= a.length; i++) {
    curr[0] = i;
    for (var j = 1; j <= b.length; j++) {
      final cost = a[i - 1] == b[j - 1] ? 0 : 1;
      curr[j] = [
        curr[j - 1] + 1,
        prev[j] + 1,
        prev[j - 1] + cost,
      ].reduce((x, y) => x < y ? x : y);
    }
    for (var j = 0; j <= b.length; j++) {
      prev[j] = curr[j];
    }
  }
  return prev[b.length];
}

class FoodSearchService {
  static final FoodSearchService _i = FoodSearchService._internal();
  factory FoodSearchService() => _i;
  FoodSearchService._internal();

  final Map<String, List<FoodSearchHit>> _cache = {};

  List<FoodSearchHit> search(String query, {int limit = 10}) {
    final q = normalizeFoodQuery(query);
    if (q.isEmpty) return const [];
    if (_cache.containsKey(q)) return _cache[q]!.take(limit).toList();

    final db = FoodNutritionDatabase();
    if (!db.isLoaded) return const [];

    final hits = <FoodSearchHit>[];

    // Build alias reverse lookup once per query (cheap, small map)
    final aliasFor = <String, String>{};
    kFoodAliases.forEach((canonical, aliases) {
      for (final a in aliases) {
        aliasFor[normalizeFoodQuery(a)] = canonical;
      }
    });

    for (final rec in db.records) {
      final name = normalizeFoodQuery(rec.name);
      double score = 0;
      String? alias;

      if (name == q) {
        score = 100;
      } else if (aliasFor[q] != null &&
          (name == normalizeFoodQuery(aliasFor[q]!) ||
              name.contains(aliasFor[q]!))) {
        score = 95;
        alias = aliasFor[q];
      } else if (name.contains(q) || q.contains(name)) {
        // longer overlap → higher score
        final overlap = q.length < name.length ? q.length : name.length;
        final longer = q.length > name.length ? q.length : name.length;
        score = 70 + 15 * (overlap / longer);
      } else {
        // token overlap
        final qTokens =
            q.split(' ').where((t) => t.length > 1).toSet();
        final nTokens =
            name.split(' ').where((t) => t.length > 1).toSet();
        final common = qTokens.intersection(nTokens).length;
        if (common > 0) {
          score = 55 + common * 8;
        } else {
          // fuzzy: edit distance ≤ 2 on short names, ≤ 3 on long
          final dist = _levenshtein(q, name);
          final threshold = name.length > 10 ? 3 : 2;
          if (dist <= threshold && q.length > 2) {
            score = 60 - dist * 5;
          }
        }
      }

      if (score > 0) {
        hits.add(FoodSearchHit(record: rec, score: score, matchedAlias: alias));
      }
    }

    hits.sort((a, b) => b.score.compareTo(a.score));
    final out = hits.take(limit).toList();
    // cache small result sets
    if (_cache.length > 40) _cache.clear();
    _cache[q] = out;
    return out;
  }

  void clearCache() => _cache.clear();
}
