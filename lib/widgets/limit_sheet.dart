// lib/widgets/limit_sheet.dart — friendly limit-reached bottom sheet.
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../screens/paywall_screen.dart';
import '../themes/hiw_theme.dart';

/// Shows quota state + reset info + Pro upsell. Returns true if user
/// chose to continue within Free (when [freeAlternative] provided).
Future<bool> showLimitSheet(
  BuildContext context, {
  required String title,
  required String usedLabel,
  required String resetLabel,
  String? freeAlternativeLabel,
}) async {
  final res = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final t = HiwTheme.of(context);
      return ClipRRect(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(24.r)),
        child: BackdropFilter(
          filter: ImageFilter.blur(
              sigmaX: t.blurSigma, sigmaY: t.blurSigma),
          child: Container(
            padding:
                EdgeInsets.fromLTRB(22.w, 12.h, 22.w, 28.h),
            decoration: BoxDecoration(
              color: t.cardBackground,
              borderRadius: BorderRadius.vertical(
                  top: Radius.circular(24.r)),
              border: Border.all(color: t.cardStroke),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: t.mutedColor.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
                SizedBox(height: 14.h),
                Icon(Icons.bolt_outlined,
                    size: 40.sp, color: t.accentColor),
                SizedBox(height: 10.h),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: t.inkColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 18.sp,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  '$usedLabel\nResets $resetLabel',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: t.mutedColor, fontSize: 13.sp),
                ),
                SizedBox(height: 16.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: t.accentColor,
                      foregroundColor: Colors.white,
                      padding:
                          EdgeInsets.symmetric(vertical: 14.h),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(14.r),
                      ),
                    ),
                    onPressed: () async {
                      Navigator.pop(ctx, false);
                      await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                          builder: (_) => const PaywallScreen(),
                        ),
                      );
                    },
                    child: const Text('See HIW Pro',
                        style: TextStyle(
                            fontWeight: FontWeight.bold)),
                  ),
                ),
                if (freeAlternativeLabel != null) ...[
                  SizedBox(height: 8.h),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: t.inkColor,
                        side:
                            BorderSide(color: t.cardStroke),
                        padding: EdgeInsets.symmetric(
                            vertical: 14.h),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(14.r),
                        ),
                      ),
                      onPressed: () =>
                          Navigator.pop(ctx, true),
                      child: Text(freeAlternativeLabel),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    },
  );
  return res ?? false;
}
