// lib/widgets/habit_card.dart
// Update A+B: HIW Score + sparkline, weekly challenge, streak freezes,
// shareable progress card. Theme tokens only.
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../core/habit_engine.dart';
import '../themes/hiw_theme.dart';
import 'hiw_card.dart';

class HabitCard extends StatefulWidget {
  const HabitCard({super.key});

  @override
  State<HabitCard> createState() => _HabitCardState();
}

class _HabitCardState extends State<HabitCard> {
  final _shotKey = GlobalKey();
  bool _sharing = false;

  Future<void> _share() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      final boundary = _shotKey.currentContext
          ?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final bytes =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) return;
      final dir = await getTemporaryDirectory();
      final file = File(
          '${dir.path}/hiw-progress-${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(bytes.buffer.asUint8List());
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: 'My HIW progress 🔥',
        ),
      );
    } catch (_) {
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = HiwTheme.of(context);
    final engine = HabitEngine();
    final score = engine.scoreToday();
    final challenge = engine.currentChallenge();
    final freezes = engine.freezesAvailable();
    final spark = engine.last7MealCounts();
    final streak = engine.protectedStreak();

    return RepaintBoundary(
      key: _shotKey,
      child: HiwCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 64.w,
                  height: 64.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: t.accentColor, width: 3.w),
                  ),
                  child: Center(
                    child: Text(
                      '${score.total}',
                      style: TextStyle(
                        color: t.inkColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 20.sp,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        'HIW Score',
                        style: TextStyle(
                          color: t.inkColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16.sp,
                        ),
                      ),
                      Text(
                        '$streak-day streak • today’s progress, not medical advice',
                        style: TextStyle(
                            color: t.mutedColor,
                            fontSize: 11.sp),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: _share,
                  child: Container(
                    padding: EdgeInsets.all(9.r),
                    decoration: BoxDecoration(
                      color: t.accentColor
                          .withValues(alpha: 0.12),
                      borderRadius:
                          BorderRadius.circular(12.r),
                      border: Border.all(
                          color: t.accentColor
                              .withValues(alpha: 0.35)),
                    ),
                    child: _sharing
                        ? SizedBox(
                            width: 18.w,
                            height: 18.w,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2,
                              color: t.accentColor,
                            ),
                          )
                        : Icon(Icons.share_rounded,
                            color: t.accentColor,
                            size: 18.sp),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),
            // 7-day sparkline.
            SizedBox(
              height: 44.h,
              width: double.infinity,
              child: CustomPaint(
                painter: _SparkPainter(
                    spark, t.accentColor),
              ),
            ),
            SizedBox(height: 10.h),
            // Weekly challenge.
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        challenge.title,
                        style: TextStyle(
                          color: t.inkColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 13.sp,
                        ),
                      ),
                      Text(
                        '${challenge.progress}/${challenge.target} • ${challenge.subtitle}',
                        style: TextStyle(
                            color: t.mutedColor,
                            fontSize: 11.sp),
                      ),
                    ],
                  ),
                ),
                if (challenge.done)
                  Icon(Icons.verified_rounded,
                      color: t.accentColor, size: 22.sp),
              ],
            ),
            SizedBox(height: 6.h),
            ClipRRect(
              borderRadius: BorderRadius.circular(8.r),
              child: LinearProgressIndicator(
                value: challenge.ratio,
                minHeight: 8.h,
                backgroundColor: t.accentColor
                    .withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation<Color>(
                    t.accentColor),
              ),
            ),
            SizedBox(height: 10.h),
            // Freeze row.
            GestureDetector(
              onTap: freezes > 0
                  ? () {
                      final ok = engine.useFreeze();
                      if (ok && mounted) {
                        setState(() {});
                        ScaffoldMessenger.of(context)
                            .showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Streak freeze applied 🛡️')),
                        );
                      }
                    }
                  : null,
              child: Container(
                padding: EdgeInsets.symmetric(
                    horizontal: 12.w, vertical: 9.h),
                decoration: BoxDecoration(
                  color: t.accentColor
                      .withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                      color: t.cardStroke),
                ),
                child: Row(
                  children: [
                    Icon(Icons.shield_outlined,
                        color: t.accentColor, size: 18.sp),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        freezes > 0
                            ? '$freezes freeze${freezes == 1 ? '' : 's'} ready — tap to protect today'
                            : 'Earn a freeze every 14 streak days',
                        style: TextStyle(
                            color: t.mutedColor,
                            fontSize: 12.sp),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SparkPainter extends CustomPainter {
  final List<int> values;
  final Color color;
  _SparkPainter(this.values, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final maxV =
        values.fold<int>(1, (a, b) => a > b ? a : b).toDouble();
    final stepX = size.width / 6;
    final pts = <Offset>[];
    for (var i = 0; i < 7; i++) {
      final v = values[i].toDouble();
      pts.add(Offset(
        stepX * i,
        size.height - 4 - (v / maxV) * (size.height - 10),
      ));
    }
    final line = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 1; i < pts.length; i++) {
      final mid = Offset(
        (pts[i - 1].dx + pts[i].dx) / 2,
        (pts[i - 1].dy + pts[i].dy) / 2,
      );
      path.quadraticBezierTo(
          pts[i - 1].dx, pts[i - 1].dy, mid.dx, mid.dy);
    }
    path.lineTo(pts.last.dx, pts.last.dy);
    canvas.drawPath(path, line);
    final dot = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(pts.last, 4, dot);
  }

  @override
  bool shouldRepaint(_SparkPainter old) =>
      old.values != values || old.color != color;
}
