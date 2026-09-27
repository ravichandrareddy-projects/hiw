import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../services/food_recognition_service.dart';

/// Unified scan-result card. ALWAYS shows what the AI detected — laptop,
/// book, biryani, anything — plus what happens next.
class DetectionResultModal extends StatelessWidget {
  final File? imageFile;
  final String itemName;
  final bool isFood;
  final bool isInDatabase;
  final double quantity;
  final String? servingUnit;
  final int? caloriesPreview;

  /// All distinct items detected (dosa + chutney + sambar …).
  final List<ScannedItem> items;
  final VoidCallback onScanAgain;
  final VoidCallback? onViewDetails;

  const DetectionResultModal({
    super.key,
    this.imageFile,
    required this.itemName,
    required this.isFood,
    required this.isInDatabase,
    this.quantity = 1.0,
    this.servingUnit,
    this.caloriesPreview,
    this.items = const [],
    required this.onScanAgain,
    this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    // Dark premium card matching the scanner reference aesthetic.
    // (Modal sits over the live camera preview, which is always dark.)
    const cream = Color(0xFFF5EDE0);
    const creamInk = Color(0xFF2A211A);
    final badgeColor = !isFood
        ? const Color(0xFFFBBF24)
        : isInDatabase
            ? const Color(0xFF34D399)
            : const Color(0xFF38BDF8);
    final badgeText = !isFood
        ? 'NOT FOOD'
        : (isInDatabase ? 'FOOD • IN DATABASE' : 'FOOD • COMING SOON');
    final icon = !isFood
        ? Icons.devices_rounded
        : isInDatabase
            ? Icons.restaurant_menu_rounded
            : Icons.hourglass_top_rounded;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 22.w),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1712).withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(24.r),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.16),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Detected photo ──
                if (imageFile != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18.r),
                    child: Image.file(
                      imageFile!,
                      height: 170.h,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                if (imageFile != null) SizedBox(height: 16.h),

                // ── Type badge ──
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                        color: badgeColor.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, color: badgeColor, size: 16.r),
                      SizedBox(width: 6.w),
                      Text(
                        badgeText,
                        style: TextStyle(
                          color: badgeColor,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12.h),

                // ── Detected name ──
                Text(
                  itemName,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (caloriesPreview != null) SizedBox(height: 4.h),
                if (caloriesPreview != null)
                  Text(
                    '≈ $caloriesPreview kcal${servingUnit != null ? ' • $quantity x $servingUnit' : ''}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: badgeColor,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                // ── Combo list ──
                if (items.where((i) => i.isEdible).length > 1) ...[
                  SizedBox(height: 12.h),
                  ...items.where((i) => i.isEdible).map((i) {
                    final kcal = i.record?.toFoodItem(
                          quantityMultiplier:
                              i.quantity <= 0 ? 1.0 : i.quantity,
                        ).calories;
                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: 3.h),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_rounded,
                              color: badgeColor, size: 16.r),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              i.name,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (kcal != null)
                            Text(
                              '≈ $kcal kcal',
                              style: TextStyle(
                                color: Colors.white60,
                                fontSize: 12.sp,
                              ),
                            ),
                        ],
                      ),
                    );
                  }),
                ],
                SizedBox(height: 8.h),

                // ── Helper line ──
                Text(
                  !isFood
                      ? 'This looks like a $itemName.\nHIW tracks food items to calculate nutrition scores.'
                      : isInDatabase
                          ? 'Matched in your food database${servingUnit != null ? ' • $quantity x $servingUnit' : ''}.\nTap below for full nutrition details.'
                          : 'We recognized it, but it is not in your food database yet.\nComing soon!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 14.sp,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 22.h),

                // ── View details (only for matched food) ──
                if (isFood && isInDatabase && onViewDetails != null)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cream,
                        foregroundColor: creamInk,
                        padding:
                            EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(16.r),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        onViewDetails!();
                      },
                      icon: const Icon(
                          Icons.restaurant_menu_rounded),
                      label: Text(
                        'View Food Details',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                if (isFood && isInDatabase && onViewDetails != null)
                  SizedBox(height: 12.h),

                // ── Scan again (always) ──
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      padding:
                          EdgeInsets.symmetric(vertical: 14.h),
                      side: BorderSide(
                          color: Colors.white
                              .withValues(alpha: 0.3)),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(16.r),
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
        ),
      ),
    );
  }
}
