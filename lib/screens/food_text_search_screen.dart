// lib/screens/food_text_search_screen.dart
// TEXT MODE: DB-first search -> candidates -> shared FoodResultScreen.
// Glassmorphism with HiwTheme tokens only.
import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../core/food_item.dart';
import '../core/food_result.dart';
import '../core/food_search_service.dart';
import '../themes/hiw_theme.dart';
import '../widgets/hiw_card.dart';
import 'food_result_screen.dart';

class FoodTextSearchScreen extends StatefulWidget {
  final MealType initialMeal;
  final String? initialQuery; // 🆕 barcode flow pre-fills the OFF name
  const FoodTextSearchScreen({
    super.key,
    this.initialMeal = MealType.lunch,
    this.initialQuery,
  });

  @override
  State<FoodTextSearchScreen> createState() => _FoodTextSearchScreenState();
}

class _FoodTextSearchScreenState extends State<FoodTextSearchScreen> {
  final _ctrl = TextEditingController();
  final _svc = FoodSearchService();
  List<FoodSearchHit> _hits = [];
  Timer? _deb;
  bool _searched = false;
  String _filter = 'All';

  static const _filters = ['All', 'Indian', 'Rice Dishes', 'Non-Veg', 'Veg'];
  static const _quick = [
    'Biryani',
    'Chicken Biryani',
    'Veg Biryani',
    'Hyderabadi Biryani',
    'Mutton Biryani'
  ];

  @override
  void dispose() {
    _ctrl.dispose();
    _deb?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final q = widget.initialQuery?.trim() ?? '';
    if (q.isNotEmpty) {
      _ctrl.text = q;
      _searched = true;
      _hits = _svc.search(q, limit: 12);
    }
  }

  void _onChanged(String v) {
    _deb?.cancel();
    _deb = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      setState(() {
        _searched = v.trim().isNotEmpty;
        _hits = _svc.search(v, limit: 12);
      });
    });
  }

  List<FoodSearchHit> get _filtered {
    if (_filter == 'All') return _hits;
    return _hits.where((h) {
      final r = h.record;
      switch (_filter) {
        case 'Indian':
          return r.region.toLowerCase().contains('india');
        case 'Rice Dishes':
          return r.name.toLowerCase().contains('rice') ||
              r.name.toLowerCase().contains('biryani');
        case 'Non-Veg':
          return r.diet.toLowerCase().contains('non');
        case 'Veg':
          return r.diet.toLowerCase() == 'veg';
        default:
          return true;
      }
    }).toList();
  }

  void _openResult(FoodSearchHit hit) {
    final res = FoodRecognitionResult.fromRecord(
      hit.record,
      mealType: widget.initialMeal,
      source: FoodSource.db,
      confidence: (hit.score / 100).clamp(0.6, 0.98),
    );
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FoodResultScreen(initial: res),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = HiwTheme.of(context);
    final list = _filtered;

    const cream = Color(0xFFF5EDE0);
    const creamInk = Color(0xFF2A211A);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(18.w, 8.h, 18.w, 16.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Reference top row: back + Scan/Text toggle (Text active).
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: EdgeInsets.all(10.r),
                      decoration: BoxDecoration(
                        color: t.cardBackground,
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: t.cardStroke),
                      ),
                      child: Icon(
                          Icons.arrow_back_rounded,
                          color: t.inkColor,
                          size: 20.sp),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: EdgeInsets.all(4.r),
                    decoration: BoxDecoration(
                      color: t.cardBackground,
                      borderRadius:
                          BorderRadius.circular(24.r),
                      border:
                          Border.all(color: t.cardStroke),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () =>
                              Navigator.of(context).pop(),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 18.w,
                                vertical: 8.h),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius:
                                  BorderRadius.circular(
                                      18.r),
                            ),
                            child: Text('Scan',
                                style: TextStyle(
                                    color: t.mutedColor,
                                    fontWeight:
                                        FontWeight.w500,
                                    fontSize: 13.sp)),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 18.w,
                              vertical: 8.h),
                          decoration: BoxDecoration(
                            color: cream,
                            borderRadius:
                                BorderRadius.circular(
                                    18.r),
                          ),
                          child: const Text('Text',
                              style: TextStyle(
                                  color: creamInk,
                                  fontWeight:
                                      FontWeight.bold,
                                  fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: EdgeInsets.all(10.r),
                    decoration: BoxDecoration(
                      color: t.cardBackground,
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: t.cardStroke),
                    ),
                    child: Icon(Icons.flash_auto_rounded,
                        color: t.inkColor, size: 20.sp),
                  ),
                ],
              ),
              SizedBox(height: 18.h),
              Text(
                'What did you eat?',
                style: TextStyle(
                  color: t.inkColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 24.sp,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                'Search from HIW food database',
                style: TextStyle(
                    color: t.mutedColor, fontSize: 13.sp),
              ),
              SizedBox(height: 14.h),
              // Glass search bar
              ClipRRect(
                borderRadius: BorderRadius.circular(18.r),
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                      sigmaX: t.blurSigma, sigmaY: t.blurSigma),
                  child: Container(
                    decoration: BoxDecoration(
                      color: t.cardBackground,
                      borderRadius: BorderRadius.circular(18.r),
                      border: Border.all(color: t.cardStroke),
                    ),
                    child: TextField(
                      controller: _ctrl,
                      onChanged: _onChanged,
                      style: TextStyle(
                          color: t.inkColor, fontSize: 15.sp),
                      decoration: InputDecoration(
                        hintText: 'Search dosa, biryani, idli...',
                        hintStyle: TextStyle(
                            color: t.mutedColor, fontSize: 14.sp),
                        prefixIcon: Icon(Icons.search_rounded,
                            color: t.mutedColor),
                        suffixIcon: _ctrl.text.isEmpty
                            ? null
                            : IconButton(
                                icon: Icon(Icons.close_rounded,
                                    color: t.mutedColor),
                                onPressed: () {
                                  _ctrl.clear();
                                  setState(() {
                                    _hits = [];
                                    _searched = false;
                                  });
                                },
                              ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 8.w, vertical: 14.h),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 12.h),
              // Quick chips
              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: _quick
                    .map((q) => GestureDetector(
                          onTap: () {
                            _ctrl.text = q;
                            _onChanged(q);
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 14.w, vertical: 8.h),
                            decoration: BoxDecoration(
                              color: t.cardBackground,
                              borderRadius:
                                  BorderRadius.circular(20.r),
                              border:
                                  Border.all(color: t.cardStroke),
                            ),
                            child: Text(q,
                                style: TextStyle(
                                    color: t.inkColor,
                                    fontSize: 12.sp)),
                          ),
                        ))
                    .toList(),
              ),
              SizedBox(height: 12.h),
              // Filters
              SizedBox(
                height: 36.h,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _filters.length,
                  separatorBuilder: (_, __) =>
                      SizedBox(width: 8.w),
                  itemBuilder: (ctx, i) {
                    final f = _filters[i];
                    final sel = _filter == f;
                    return GestureDetector(
                      onTap: () =>
                          setState(() => _filter = f),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 14.w, vertical: 8.h),
                        decoration: BoxDecoration(
                          color: sel
                              ? t.accentColor
                              : t.cardBackground,
                          borderRadius:
                              BorderRadius.circular(20.r),
                          border: Border.all(
                              color: sel
                                  ? t.accentColor
                                  : t.cardStroke),
                        ),
                        child: Text(f,
                            style: TextStyle(
                              color: sel
                                  ? Colors.white
                                  : t.mutedColor,
                              fontWeight: sel
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              fontSize: 12.sp,
                            )),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 12.h),
              Expanded(
                child: !_searched
                    ? Center(
                        child: Text(
                          'Type to search 2,600+ foods',
                          style: TextStyle(
                              color: t.mutedColor,
                              fontSize: 13.sp),
                        ),
                      )
                    : list.isEmpty
                        ? _emptyState(t)
                        : ListView.separated(
                            itemCount: list.length,
                            separatorBuilder: (_, __) =>
                                SizedBox(height: 10.h),
                            itemBuilder: (ctx, i) {
                              final hit = list[i];
                              final r = hit.record;
                              return HiwCard(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 12.w,
                                    vertical: 10.h),
                                child: ListTile(
                                  contentPadding:
                                      EdgeInsets.zero,
                                  leading: Container(
                                    width: 52.w,
                                    height: 52.w,
                                    decoration: BoxDecoration(
                                      color: t.accentColor
                                          .withValues(alpha: 0.12),
                                      borderRadius:
                                          BorderRadius.circular(
                                              14.r),
                                      border: Border.all(
                                          color: t.cardStroke),
                                    ),
                                    child: Icon(
                                      Icons
                                          .restaurant_rounded,
                                      color: t.accentColor,
                                    ),
                                  ),
                                  title: Text(
                                    r.name,
                                    style: TextStyle(
                                      color: t.inkColor,
                                      fontWeight:
                                          FontWeight.bold,
                                      fontSize: 14.sp,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${r.region} • ${r.servingUnit}\n${r.caloriesPer100g} kcal / 100 g${hit.matchedAlias != null ? ' • ${hit.matchedAlias}' : ''}',
                                    style: TextStyle(
                                        color: t.mutedColor,
                                        fontSize: 12.sp),
                                  ),
                                  trailing: Icon(
                                      Icons
                                          .chevron_right_rounded,
                                      color: t.mutedColor),
                                  onTap: () =>
                                      _openResult(hit),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyState(HiwTheme t) {
    return Center(
      child: HiwCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded,
                size: 40.sp, color: t.mutedColor),
            SizedBox(height: 10.h),
            Text(
              "Couldn't find an exact match.",
              style: TextStyle(
                  color: t.inkColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 15.sp),
            ),
            SizedBox(height: 12.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: t.inkColor,
                    side: BorderSide(color: t.cardStroke),
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(12.r)),
                  ),
                  onPressed: () {
                    setState(() {
                      _hits = [];
                      _searched = false;
                      _ctrl.clear();
                    });
                  },
                  child: const Text('Try Again'),
                ),
                SizedBox(width: 10.w),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: t.accentColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(12.r)),
                  ),
                  // AI fallback only after DB miss + needs confirmation
                  // inside FoodResultScreen (spec B.4).
                  onPressed: () {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(
                      const SnackBar(
                          content: Text(
                              'Describe your food — AI fallback coming from camera scan for now.')),
                    );
                  },
                  child: const Text('Describe Food'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
