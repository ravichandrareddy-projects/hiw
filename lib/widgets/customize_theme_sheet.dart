import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../core/theme_manager.dart';
import '../themes/hiw_theme.dart';

/// Bottom sheet to build your own palette for the Customize theme.
/// Plain + Glass themes are never touched by this editor.
Future<void> showCustomizeSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: HiwTheme.of(context).isMinimal
        ? Colors.white
        : const Color(0xFF1E293B),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
    ),
    builder: (_) => const _CustomizeSheet(),
  );
}

class _CustomizeSheet extends StatelessWidget {
  const _CustomizeSheet();

  static const _swatches = <Color>[
    Color(0xFFFBF7EF), // warm cream
    Colors.white,
    Color(0xFFF1F5F9), // cool grey
    Color(0xFF1A1D21), // ink
    Color(0xFF0F172A), // navy night
    Colors.black,
    Color(0xFFE86A1D), // orange
    Color(0xFF00E676), // HIW green
    Color(0xFF00B0FF), // water blue
    Color(0xFF3A86FF), // royal blue
    Color(0xFF9D4EDD), // purple
    Color(0xFFFF4081), // pink
    Color(0xFFFFB300), // amber
    Color(0xFF00BFA5), // teal
  ];

  @override
  Widget build(BuildContext context) {
    final t = HiwTheme.of(context);
    return ListenableBuilder(
      listenable: ThemeManager(),
      builder: (context, _) {
        final tm = ThemeManager();
        return SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24.r),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Customize Palette 🎨',
                  style: TextStyle(
                    color: t.inkColor,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Applies to the Customize theme only.',
                  style: TextStyle(color: t.mutedColor, fontSize: 13.sp),
                ),
                SizedBox(height: 16.h),
                _livePreview(context, tm),
                SizedBox(height: 16.h),
                _colorRow(context, tm, t, 'Background', 'bg', tm.customizeBg),
                SizedBox(height: 12.h),
                _colorRow(context, tm, t, 'Cards', 'card', tm.customizeCard),
                SizedBox(height: 12.h),
                _colorRow(context, tm, t, 'Accent', 'primary',
                    tm.customizePrimary),
                SizedBox(height: 20.h),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => tm.resetCustomColors(),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Reset to Plain defaults'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: t.inkColor,
                      side: BorderSide(color: t.cardStroke),
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
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

  Widget _livePreview(BuildContext context, ThemeManager tm) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: tm.customizeBg,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: tm.customizePrimary.withValues(alpha: 0.4)),
      ),
      child: Container(
        padding: EdgeInsets.all(12.r),
        decoration: BoxDecoration(
          color: tm.customizeCard,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          children: [
            Container(
              width: 36.w,
              height: 36.h,
              decoration: BoxDecoration(
                color: tm.customizePrimary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.restaurant_menu_rounded,
                  color: Colors.white, size: 20),
            ),
            SizedBox(width: 12.w),
            Text(
              'Live preview',
              style: TextStyle(
                color: tm.customizeBg.computeLuminance() < 0.4
                    ? Colors.white
                    : const Color(0xFF211D16),
                fontWeight: FontWeight.bold,
                fontSize: 15.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _colorRow(BuildContext context, ThemeManager tm, HiwTheme t,
      String label, String which, Color current) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: t.inkColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 14.sp,
                ),
              ),
            ),
            // Current color dot.
            Container(
              width: 28.w,
              height: 28.h,
              decoration: BoxDecoration(
                color: current,
                shape: BoxShape.circle,
                border: Border.all(color: t.cardStroke, width: 1.5),
              ),
            ),
            SizedBox(width: 8.w),
            // Full picker: every color, HSV wheel + hex input.
            OutlinedButton.icon(
              onPressed: () =>
                  _showFullPicker(context, tm, t, label, which, current),
              icon: const Icon(Icons.colorize_rounded, size: 16),
              label: const Text('Custom'),
              style: OutlinedButton.styleFrom(
                foregroundColor: t.inkColor,
                side: BorderSide(color: t.cardStroke),
                padding:
                    EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.r),
                ),
                textStyle: TextStyle(fontSize: 12.sp),
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        Wrap(
          spacing: 10.w,
          runSpacing: 10.h,
          children: _swatches.map((c) {
            final selected = c.toARGB32() == current.toARGB32();
            return GestureDetector(
              onTap: () => tm.setCustomColor(which, c),
              child: Container(
                width: 40.w,
                height: 40.h,
                decoration: BoxDecoration(
                  color: c,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected
                        ? t.accentColor
                        : t.cardStroke,
                    width: selected ? 3 : 1,
                  ),
                ),
                child: selected
                    ? Icon(Icons.check,
                        color: c.computeLuminance() < 0.4
                            ? Colors.white
                            : Colors.black,
                        size: 20)
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// Full color picker: entire spectrum + hex input (not just swatches).
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
              style: TextStyle(color: dlgInk, fontSize: 18.sp)),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: picked,
              onColorChanged: (c) {
                // Opaque only: translucent bg/cards break readability.
                picked = c.withValues(alpha: 1.0);
                tm.setCustomColor(which, picked);
              },
              colorPickerWidth: 300,
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
