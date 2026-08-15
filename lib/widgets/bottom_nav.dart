import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/theme_manager.dart';

class BottomNav extends StatelessWidget {
  final int currentIndex;
  final void Function(int) onTap;
  const BottomNav({super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tm = ThemeManager();

    return ClipRRect(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(18.r),
        topRight: Radius.circular(18.r),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            color: tm.currentThemeName == 'plain'
                ? Colors.white.withOpacity(0.9)
                : (isDark ? Colors.black.withOpacity(0.4) : Colors.white.withOpacity(0.25)),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(18.r),
              topRight: Radius.circular(18.r),
            ),
            border: Border.all(
              color: tm.currentThemeName == 'plain'
                  ? const Color(0xFFE5E7EB)
                  : (isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04)),
              width: 0.5.w,
            ),
          ),
          padding: EdgeInsets.only(top: 4.h, bottom: 4.h), // 📏 ULTRA COMPACT (Reduced from 6)
          child: SafeArea( // Ensure it respects Safe Area
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
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6.h), // Smaller padding
                    decoration: BoxDecoration(
                      color: active ? themeColor.withOpacity(0.12) : Colors.transparent,
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(item.icon, color: active ? themeColor : (isDark ? Colors.white60 : Colors.black45), size: 20), // Smaller Icon
                        SizedBox(height: 2.h),
                        Text(item.label, style: TextStyle(fontSize: 9.sp, fontWeight: active ? FontWeight.bold : FontWeight.normal, color: active ? themeColor : (isDark ? Colors.white38 : Colors.black38))), // Smaller Text
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
