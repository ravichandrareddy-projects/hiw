import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../themes/hiw_theme.dart';

class BottomNav extends StatelessWidget {
  final int currentIndex;
  final void Function(int) onTap;
  const BottomNav({super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t = HiwTheme.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(18.r),
        topRight: Radius.circular(18.r),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(
            sigmaX: t.isMinimal ? 0 : 18, sigmaY: t.isMinimal ? 0 : 18),
        child: Container(
          decoration: BoxDecoration(
            color: t.isMinimal
                ? Colors.white.withValues(alpha: 0.94)
                : (isDark
                    ? Colors.black.withValues(alpha: 0.4)
                    : Colors.white.withValues(alpha: 0.25)),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(18.r),
              topRight: Radius.circular(18.r),
            ),
            border: Border.all(
              color: t.isMinimal
                  ? t.cardStroke
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.black.withValues(alpha: 0.04)),
              width: 0.5.w,
            ),
          ),
          padding: EdgeInsets.only(
              top: 4.h, bottom: 4.h), // 📏 ULTRA COMPACT (Reduced from 6)
          child: SafeArea(
            // Ensure it respects Safe Area
            top: false,
            bottom: true,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_items.length, (i) {
                final item = _items[i];
                final active = currentIndex == i;
                return GestureDetector(
                  onTap: () => onTap(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    padding: EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6.h), // Smaller padding
                    decoration: BoxDecoration(
                      color: active
                          ? themeColor.withValues(alpha: 0.12)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(item.icon,
                            color: active
                                ? themeColor
                                : t.mutedColor,
                            size: 20), // Smaller Icon
                        SizedBox(height: 2.h),
                        Text(item.label,
                            style: TextStyle(
                                fontSize: 9.sp,
                                fontWeight: active
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: active
                                    ? themeColor
                                    : t.mutedColor)), // Smaller Text
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
