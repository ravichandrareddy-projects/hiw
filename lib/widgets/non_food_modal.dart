import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'glass_card.dart';

class NonFoodModal extends StatelessWidget {
  final String detectedItemName;
  final VoidCallback onScanAgain;

  const NonFoodModal({
    super.key,
    required this.detectedItemName,
    required this.onScanAgain,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 24.w),
      child: GlassCard(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.amber.withOpacity(0.2),
                border: Border.all(color: Colors.amber, width: 1.5),
              ),
              child: Icon(
                Icons.no_food_rounded,
                color: Colors.amber,
                size: 48.r,
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'Not a Food Item',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.h),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: TextStyle(color: const Color(0xFFCBD5E1), fontSize: 15.sp),
                children: [
                  const TextSpan(text: 'Detected object: '),
                  TextSpan(
                    text: detectedItemName,
                    style: const TextStyle(
                      color: Colors.amberAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const TextSpan(
                    text: '\n\nHIW focuses on food items to calculate nutrition scores.',
                  ),
                ],
              ),
            ),
            SizedBox(height: 24.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00E676),
                  foregroundColor: Colors.black,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  onScanAgain();
                },
                icon: const Icon(Icons.camera_alt_rounded),
                label: Text(
                  'Scan Again',
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
    );
  }
}
