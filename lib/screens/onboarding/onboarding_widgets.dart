// lib/screens/onboarding/onboarding_widgets.dart
// Shared onboarding chrome: everything from HiwTheme tokens only.
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../themes/hiw_theme.dart';
import '../../widgets/hiw_card.dart';

/// Page chrome: progress, title, subtitle, scroll-safe body, nav buttons.
class OnbScaffold extends StatelessWidget {
  final int step; // 1-based for display
  final int total;
  final String title;
  final String? subtitle;
  final Widget child;
  final bool showBack;
  final VoidCallback? onBack;
  final String nextLabel;
  final VoidCallback? onNext;
  final bool nextEnabled;
  final String? skipLabel;
  final VoidCallback? onSkip;

  const OnbScaffold({
    super.key,
    required this.step,
    required this.total,
    required this.title,
    this.subtitle,
    required this.child,
    this.showBack = true,
    this.onBack,
    this.nextLabel = 'Next',
    this.onNext,
    this.nextEnabled = true,
    this.skipLabel,
    this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final t = HiwTheme.of(context);
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: EdgeInsets.fromLTRB(22.w, 12.h, 22.w, 18.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (showBack)
                      GestureDetector(
                        onTap: onBack ??
                            () => Navigator.of(context).maybePop(),
                        child: Container(
                          padding: EdgeInsets.all(10.r),
                          decoration: BoxDecoration(
                            color: t.cardBackground,
                            shape: BoxShape.circle,
                            border: Border.all(color: t.cardStroke),
                          ),
                          child: Icon(Icons.arrow_back_rounded,
                              color: t.inkColor, size: 20.sp),
                        ),
                      )
                    else
                      SizedBox(width: 40.w),
                    Expanded(
                      child: Center(
                        child: Text(
                          '$step / $total',
                          style: TextStyle(
                            color: t.mutedColor,
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    if (skipLabel != null)
                      GestureDetector(
                        onTap: onSkip,
                        child: Padding(
                          padding: EdgeInsets.all(8.r),
                          child: Text(
                            skipLabel!,
                            style: TextStyle(
                              color: t.accentColor,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      )
                    else
                      SizedBox(width: 40.w),
                  ],
                ),
                SizedBox(height: 10.h),
                // Segmented progress bar.
                Row(
                  children: List.generate(total, (i) {
                    final on = i < step;
                    return Expanded(
                      child: Container(
                        height: 4.h,
                        margin: EdgeInsets.only(
                            right: i == total - 1 ? 0 : 6.w),
                        decoration: BoxDecoration(
                          color: on
                              ? t.accentColor
                              : t.accentColor.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      ),
                    );
                  }),
                ),
                SizedBox(height: 22.h),
                Text(
                  title,
                  style: TextStyle(
                    color: t.inkColor,
                    fontSize: 26.sp,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
                if (subtitle != null) ...[
                  SizedBox(height: 8.h),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      color: t.mutedColor,
                      fontSize: 14.sp,
                      height: 1.5,
                    ),
                  ),
                ],
                SizedBox(height: 20.h),
                Expanded(
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.only(bottom: 16.h),
                    child: child,
                  ),
                ),
                SizedBox(height: 12.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: nextEnabled
                          ? t.accentColor
                          : t.mutedColor.withValues(alpha: 0.4),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                    ),
                    onPressed: nextEnabled ? onNext : null,
                    child: Text(
                      nextLabel,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Selectable option card (goals, activity, diet).
class OnbOption<T> extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final bool selected;
  final bool isMultiSelect;
  final bool isPrimary;
  final VoidCallback onTap;
  final VoidCallback? onPrimaryTap;

  const OnbOption({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    required this.selected,
    this.isMultiSelect = false,
    this.isPrimary = false,
    required this.onTap,
    this.onPrimaryTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = HiwTheme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 10.h),
        padding:
            EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: selected
              ? t.accentColor.withValues(alpha: 0.12)
              : t.cardBackground,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: selected ? t.accentColor : t.cardStroke,
            width: selected ? 1.8 : 1,
          ),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon,
                  color: selected
                      ? t.accentColor
                      : t.mutedColor,
                  size: 24.sp),
              SizedBox(width: 12.w),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: TextStyle(
                            color: t.inkColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 15.sp,
                          ),
                        ),
                      ),
                      if (isPrimary) ...[
                        SizedBox(width: 8.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 8.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: t.accentColor,
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Text(
                            'PRIMARY',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (subtitle != null)
                    Padding(
                      padding: EdgeInsets.only(top: 2.h),
                      child: Text(
                        subtitle!,
                        style: TextStyle(
                          color: t.mutedColor,
                          fontSize: 12.sp,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Icon(
              isMultiSelect
                  ? (selected
                      ? Icons.check_box_rounded
                      : Icons.check_box_outline_blank_rounded)
                  : (selected
                      ? Icons.check_circle_rounded
                      : Icons.circle_outlined),
              color: selected ? t.accentColor : t.mutedColor,
            ),
          ],
        ),
      ),
    );
  }
}

/// Labeled numeric/text input in a theme card with reactive onChanged support.
class OnbField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final TextInputType keyboard;
  final TextInputAction textInputAction;
  final String? error;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onSubmitted;

  const OnbField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.keyboard = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.error,
    this.onChanged,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final t = HiwTheme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: t.inkColor,
              fontWeight: FontWeight.w700,
              fontSize: 14.sp,
            ),
          ),
          SizedBox(height: 8.h),
          HiwCard(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: TextField(
              controller: controller,
              keyboardType: keyboard,
              textInputAction: textInputAction,
              onChanged: onChanged,
              onSubmitted: onSubmitted != null ? (_) => onSubmitted!() : null,
              scrollPadding: EdgeInsets.only(bottom: 80.h),
              style: TextStyle(color: t.inkColor, fontSize: 16.sp),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                    color: t.mutedColor, fontSize: 14.sp),
                border: InputBorder.none,
                contentPadding:
                    EdgeInsets.symmetric(vertical: 14.h),
              ),
            ),
          ),
          if (error != null) ...[
            SizedBox(height: 6.h),
            Text(
              error!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12.sp,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
