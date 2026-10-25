import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../core/theme_manager.dart';
import '../themes/hiw_theme.dart';

/// Bottom sheet to tune the Bottom Navigation Bar style:
/// - Full Bar background color (e.g. slate dark, cream, jet black, frosted gray)
/// - Active selection glow color (e.g. emerald, gold, cyan, violet, ruby, orange)
Future<void> showBottomNavThemeSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: HiwTheme.of(context).isMinimal
        ? Colors.white
        : const Color(0xFF1E293B),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
    ),
    builder: (_) => const BottomNavThemeSheet(),
  );
}

class BottomNavThemeSheet extends StatelessWidget {
  const BottomNavThemeSheet({super.key});

  static const _barBgSwatches = <Color>[
    Color(0xFF2B2D31), // slate gray (matches top status bar!)
    Color(0xFF1E2024), // deep charcoal
    Color(0xFF121316), // pitch night
    Color(0xFF0F172A), // dark midnight blue
    Colors.black,      // pitch black
    Color(0xFFF1F5F9), // cool light grey
    Color(0xFFFBF7EF), // warm cream
    Colors.white,      // pure white
  ];

  static const _selectionSwatches = <Color>[
    Color(0xFFE86A1D), // energetic orange
    Color(0xFFFFB300), // vibrant amber gold
    Color(0xFF00E676), // emerald neon green
    Color(0xFF0B6B3A), // deep forest green
    Color(0xFF00B0FF), // vivid sky cyan
    Color(0xFF3A86FF), // electric royal blue
    Color(0xFF9D4EDD), // royal purple
    Color(0xFFFF4081), // vibrant pink
    Color(0xFFEF4444), // crimson red
    Color(0xFF00BFA5), // bright teal
  ];

  @override
  Widget build(BuildContext context) {
    final t = HiwTheme.of(context);
    return ListenableBuilder(
      listenable: ThemeManager(),
      builder: (context, _) {
        final tm = ThemeManager();
        final currentBarBg = tm.bottomNavBg ??
            (t.isMinimal ? Colors.white : const Color(0xFF1E2024));
        final currentSelection =
            tm.bottomNavSelection ?? Theme.of(context).primaryColor;

        return SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 32.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: t.cardStroke,
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                ),
                SizedBox(height: 18.h),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.r),
                      decoration: BoxDecoration(
                        color: currentSelection.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(Icons.navigation_rounded,
                          color: currentSelection, size: 24.sp),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bottom Bar Color Settings',
                            style: TextStyle(
                              color: t.inkColor,
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            'Customize bar background & glowing selection',
                            style: TextStyle(
                                color: t.mutedColor, fontSize: 12.sp),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20.h),

                // Live Preview Capsule
                Text(
                  'Live Preview',
                  style: TextStyle(
                    color: t.mutedColor,
                    fontSize: 11.5.sp,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 8.h),
                _buildLiveNavPreview(context, currentBarBg, currentSelection),
                SizedBox(height: 24.h),

                // 1. Full Bar Background Color
                _buildColorSection(
                  context,
                  tm: tm,
                  t: t,
                  title: 'Bottom Bar Background',
                  subtitle: 'Change the overall capsule island color',
                  which: 'bottomNavBg',
                  current: currentBarBg,
                  swatches: _barBgSwatches,
                ),

                SizedBox(height: 22.h),

                // 2. Selection Glow Color
                _buildColorSection(
                  context,
                  tm: tm,
                  t: t,
                  title: 'Active Selection Color',
                  subtitle: 'Glowing gradient on the selected tab',
                  which: 'bottomNavSelection',
                  current: currentSelection,
                  swatches: _selectionSwatches,
                ),

                SizedBox(height: 26.h),

                // Reset Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => tm.resetBottomNavColors(),
                    icon: const Icon(Icons.restore_rounded),
                    label: const Text('Reset to Default Theme'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: t.inkColor,
                      side: BorderSide(color: t.cardStroke),
                      padding: EdgeInsets.symmetric(vertical: 13.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLiveNavPreview(
      BuildContext context, Color barBg, Color selectionColor) {
    final glowStart = HSLColor.fromColor(selectionColor)
        .withLightness(
            (HSLColor.fromColor(selectionColor).lightness + 0.12).clamp(0.0, 1.0))
        .toColor();
    final isDarkBg = barBg.computeLuminance() < 0.45;
    final inactiveColor = isDarkBg ? Colors.white60 : Colors.black54;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: barBg,
        borderRadius: BorderRadius.circular(28.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 18.r,
            offset: Offset(0, 4.r),
          ),
        ],
        border: Border.all(
          color: isDarkBg
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.black.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Active Tab Preview
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [glowStart, selectionColor],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(18.r),
              boxShadow: [
                BoxShadow(
                  color: selectionColor.withValues(alpha: 0.45),
                  blurRadius: 10.r,
                  spreadRadius: 1.r,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.shopping_bag_outlined,
                    color: Colors.white, size: 16.sp),
                SizedBox(width: 5.w),
                Text('Food',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11.sp)),
              ],
            ),
          ),
          // Inactive Tab Previews
          _previewInactiveTab(Icons.restaurant_menu, 'Foodity', inactiveColor),
          _previewInactiveTab(Icons.camera_alt_outlined, 'HIW', inactiveColor),
          _previewInactiveTab(Icons.person_outline, 'Avatar', inactiveColor),
        ],
      ),
    );
  }

  Widget _previewInactiveTab(IconData icon, String label, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16.sp),
        SizedBox(height: 2.h),
        Text(label,
            style: TextStyle(
                color: color, fontSize: 9.sp, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildColorSection(
    BuildContext context, {
    required ThemeManager tm,
    required HiwTheme t,
    required String title,
    required String subtitle,
    required String which,
    required Color current,
    required List<Color> swatches,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: t.inkColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 14.sp,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    subtitle,
                    style: TextStyle(color: t.mutedColor, fontSize: 11.5.sp),
                  ),
                ],
              ),
            ),
            Container(
              width: 26.w,
              height: 26.h,
              decoration: BoxDecoration(
                color: current,
                shape: BoxShape.circle,
                border: Border.all(color: t.cardStroke, width: 2),
              ),
            ),
            SizedBox(width: 8.w),
            OutlinedButton.icon(
              onPressed: () => _showFullPicker(context, tm, t, title, which, current),
              icon: const Icon(Icons.colorize_rounded, size: 15),
              label: const Text('Custom'),
              style: OutlinedButton.styleFrom(
                foregroundColor: t.inkColor,
                side: BorderSide(color: t.cardStroke),
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18.r),
                ),
                textStyle: TextStyle(fontSize: 11.sp),
              ),
            ),
          ],
        ),
        SizedBox(height: 10.h),
        Wrap(
          spacing: 10.w,
          runSpacing: 10.h,
          children: swatches.map((c) {
            final selected = c.toARGB32() == current.toARGB32();
            return GestureDetector(
              onTap: () => tm.setCustomColor(which, c),
              child: Container(
                width: 36.w,
                height: 36.h,
                decoration: BoxDecoration(
                  color: c,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? Theme.of(context).primaryColor : t.cardStroke,
                    width: selected ? 2.8 : 1,
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: c.withValues(alpha: 0.4),
                            blurRadius: 8.r,
                          )
                        ]
                      : null,
                ),
                child: selected
                    ? Icon(
                        Icons.check,
                        color: c.computeLuminance() < 0.45
                            ? Colors.white
                            : Colors.black,
                        size: 18,
                      )
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _showFullPicker(BuildContext context, ThemeManager tm, HiwTheme t,
      String label, String which, Color start) {
    Color picked = start;
    showDialog(
      context: context,
      builder: (ctx) {
        final dlgInk = HiwTheme.of(ctx).inkColor;
        final dlgBg = HiwTheme.of(ctx).isMinimal
            ? Colors.white
            : const Color(0xFF1E293B);
        return AlertDialog(
          backgroundColor: dlgBg,
          title: Text('Pick $label',
              style: TextStyle(color: dlgInk, fontSize: 17.sp)),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: picked,
              onColorChanged: (c) {
                picked = c.withValues(alpha: 1.0);
                tm.setCustomColor(which, picked);
              },
              colorPickerWidth: 280,
              pickerAreaHeightPercent: 0.7,
              enableAlpha: false,
              displayThumbColor: true,
              paletteType: PaletteType.hsvWithHue,
              labelTypes: const [],
              hexInputBar: true,
            ),
          ),
          actions: [
            TextButton(
              child: Text('Done',
                  style: TextStyle(color: Theme.of(ctx).primaryColor)),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ],
        );
      },
    );
  }
}
