import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../themes/hiw_theme.dart';
import '../core/theme_manager.dart';

class BottomNav extends StatelessWidget {
  final int currentIndex;
  final void Function(int) onTap;
  const BottomNav({super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeManager(),
      builder: (context, _) {
        final tm = ThemeManager();
        final themeColor = tm.bottomNavSelection ?? Theme.of(context).primaryColor;
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final t = HiwTheme.of(context);
        final bottomInset = MediaQuery.of(context).padding.bottom;

        final customBarColor = tm.bottomNavBg;
        final isCustomBarDark = customBarColor != null && customBarColor.computeLuminance() < 0.45;

        final navBgColor = customBarColor != null
            ? (customBarColor.a < 1.0 ? customBarColor : customBarColor.withValues(alpha: 0.95))
            : (t.isMinimal
                ? Colors.white.withValues(alpha: 0.95)
                : (isDark
                    ? const Color(0xFF1E2024).withValues(alpha: 0.92)
                    : Colors.white.withValues(alpha: 0.90)));

        return Padding(
          // 🌟 FLOATING DETACHED ISLAND (Not connected to screen bottom)
          padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, (bottomInset > 0 ? bottomInset : 10.h)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(36.r), // 🥚 Big Oval Capsule
            child: BackdropFilter(
              filter: ImageFilter.blur(
                  sigmaX: t.isMinimal ? 0 : 20, sigmaY: t.isMinimal ? 0 : 20),
              child: Container(
                decoration: BoxDecoration(
                  color: navBgColor,
                  borderRadius: BorderRadius.circular(36.r), // 🥚 Big Oval
                  border: Border.all(
                    color: customBarColor != null
                        ? (isCustomBarDark
                            ? Colors.white.withValues(alpha: 0.15)
                            : Colors.black.withValues(alpha: 0.08))
                        : (t.isMinimal
                            ? t.cardStroke
                            : (isDark
                                ? Colors.white.withValues(alpha: 0.12)
                                : Colors.black.withValues(alpha: 0.06))),
                    width: 1.w,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.14),
                      blurRadius: 22.r,
                      spreadRadius: 2.r,
                      offset: Offset(0, 6.r),
                    ),
                  ],
                ),
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 6.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(_items.length, (i) {
                    final item = _items[i];
                    final active = currentIndex == i;

                    // 🌈 Left-to-right glowing card colors
                    final Color glowStart;
                    final Color glowEnd;
                    if (tm.bottomNavSelection != null) {
                      glowStart = HSLColor.fromColor(themeColor)
                          .withLightness((HSLColor.fromColor(themeColor).lightness + 0.12).clamp(0.0, 1.0))
                          .toColor();
                      glowEnd = themeColor;
                    } else if (themeColor == const Color(0xFF0B6B3A)) {
                      glowStart = const Color(0xFF22C55E);
                      glowEnd = const Color(0xFF15803D);
                    } else {
                      glowStart = const Color(0xFFFF9E44);
                      glowEnd = themeColor;
                    }

                    // Inactive text & icon color based on bar luminance
                    final inactiveColor = customBarColor != null
                        ? (isCustomBarDark ? Colors.white60 : Colors.black54)
                        : t.mutedColor;

                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onTap(i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 260),
                        curve: Curves.easeInOutCubic,
                        padding: EdgeInsets.symmetric(
                          horizontal: active ? 14.w : 10.w,
                          vertical: 6.h,
                        ),
                        decoration: BoxDecoration(
                          // 💫 Separate card: glowing left-to-right gradient when active
                          gradient: active
                              ? LinearGradient(
                                  colors: [glowStart, glowEnd],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                )
                              : null,
                          color: active ? null : Colors.transparent,
                          borderRadius: BorderRadius.circular(22.r),
                          border: active
                              ? Border.all(
                                  color: Colors.white.withValues(alpha: 0.4),
                                  width: 0.8.w,
                                )
                              : null,
                          boxShadow: active
                              ? [
                                  BoxShadow(
                                    color: glowEnd.withValues(alpha: 0.45),
                                    blurRadius: 14.r,
                                    spreadRadius: 1.r,
                                    offset: Offset(0, 3.r),
                                  ),
                                  BoxShadow(
                                    color: glowStart.withValues(alpha: 0.35),
                                    blurRadius: 18.r,
                                    spreadRadius: 2.r,
                                  ),
                                ]
                              : [],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              item.icon,
                              color: active ? Colors.white : inactiveColor,
                              size: active ? 21.sp : 19.sp,
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              item.label,
                              style: TextStyle(
                                fontSize: 9.5.sp,
                                fontWeight:
                                    active ? FontWeight.bold : FontWeight.w600,
                                color: active ? Colors.white : inactiveColor,
                                letterSpacing: active ? 0.3 : 0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem(this.icon, this.label);
}

const _items = [
  _NavItem(Icons.restaurant_menu, 'Foodity'),
  _NavItem(Icons.shopping_bag_outlined, 'Food'),
  _NavItem(Icons.camera_alt_outlined, 'HIW'),
  _NavItem(Icons.history, 'History'),
  _NavItem(Icons.person_outline, 'Avatar'),
];
