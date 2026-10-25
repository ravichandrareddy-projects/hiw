// lib/screens/level_progress_screen.dart — Dedicated HIW Level & Progression screen.
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../core/progression_engine.dart';
import '../core/hw_wallet.dart';
import '../services/daily_checkin_service.dart';
import '../themes/hiw_theme.dart';
import '../themes/hiw_gold.dart';
import '../core/subscription/entitlement.dart';

class LevelProgressScreen extends StatefulWidget {
  const LevelProgressScreen({super.key});

  @override
  State<LevelProgressScreen> createState() => _LevelProgressScreenState();
}

class _LevelProgressScreenState extends State<LevelProgressScreen> {
  final ProgressionEngine _engine = ProgressionEngine();
  final HWWallet _wallet = HWWallet();
  final DailyCheckInService _checkInService = DailyCheckInService();

  bool _checkedInToday = false;
  int _checkInStreak = 0;
  bool _checkingIn = false;
  bool _isPro = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _engine.init();
    await _wallet.init();
    final checkedIn = await _checkInService.hasCheckedInToday();
    final streak = await _checkInService.currentCheckInStreak();
    final pro = (await EntitlementStore.current()).isPro;
    if (mounted) {
      setState(() {
        _isPro = pro;
        _checkedInToday = checkedIn;
        _checkInStreak = streak;
      });
    }
  }

  Future<void> _claimCheckIn() async {
    if (_checkedInToday || _checkingIn) return;
    setState(() => _checkingIn = true);

    try {
      final res = await _checkInService.performCheckIn();
      if (!mounted) return;
      if (res.success) {
        setState(() {
          _checkedInToday = true;
          _checkInStreak = res.streakDays;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.teal.shade800,
            content: Text(
              '🎉 +${res.coinsEarned} HW Coin & +${res.xpEarned} XP! Great job showing up today.',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _checkingIn = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = HiwTheme.of(context);
    final model = _engine.levelModel;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: t.inkColor, size: 20.sp),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Level & Progress',
          style: TextStyle(
            color: t.inkColor,
            fontWeight: FontWeight.bold,
            fontSize: 18.sp,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 32.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🏆 HERO LEVEL CARD (Gold effect for Pro users)
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20.r),
                decoration: BoxDecoration(
                  color: _isPro
                      ? (Theme.of(context).brightness == Brightness.dark
                          ? HiwGold.cardBgDark
                          : HiwGold.cardBgLight)
                      : t.cardBackground,
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: _isPro ? HiwGold.warmGold : t.cardStroke,
                    width: _isPro ? 2.0.w : 1.0,
                  ),
                  boxShadow: [
                    if (_isPro)
                      HiwGold.haloGlow(blur: 20.r, spread: 2.r, opacity: 0.35)
                    else
                      BoxShadow(
                        color: t.accentColor.withValues(alpha: 0.08),
                        blurRadius: 16.r,
                        offset: const Offset(0, 4),
                      ),
                  ],
                ),
                child: Column(
                  children: [
                    if (_isPro) ...[
                      Row(
                        children: [
                          HiwGold.proPill(
                              label: 'HIW PRO MEMBER',
                              showCrown: true,
                              fontSize: 10),
                          const Spacer(),
                          Icon(Icons.workspace_premium_rounded,
                              color: HiwGold.warmGold, size: 20.sp),
                        ],
                      ),
                      SizedBox(height: 14.h),
                    ],
                    Row(
                      children: [
                        Container(
                          width: 60.w,
                          height: 60.h,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: _isPro ? HiwGold.goldGradient : null,
                            color: _isPro
                                ? null
                                : t.accentColor.withValues(alpha: 0.15),
                            border: Border.all(
                              color: _isPro ? Colors.white : t.accentColor,
                              width: 2.w,
                            ),
                            boxShadow: _isPro
                                ? [HiwGold.subtleGlow(blur: 8.r, opacity: 0.4)]
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              '${model.level}',
                              style: TextStyle(
                                color: _isPro
                                    ? const Color(0xFF381A00)
                                    : t.accentColor,
                                fontWeight: FontWeight.w900,
                                fontSize: 24.sp,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'LEVEL ${model.level}',
                                style: TextStyle(
                                  color: _isPro
                                      ? HiwGold.deepGold
                                      : t.accentColor,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12.sp,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                model.title,
                                style: TextStyle(
                                  color: t.inkColor,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 19.sp,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                '${model.currentLevelXP} / ${model.xpToNextLevel} XP to Level ${model.level + 1}',
                                style: TextStyle(
                                  color: t.mutedColor,
                                  fontSize: 12.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),
                    // Progress Bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8.r),
                      child: LinearProgressIndicator(
                        value: model.progress,
                        minHeight: 10.h,
                        backgroundColor:
                            _isPro ? HiwGold.champagneLight : t.cardStroke,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            _isPro ? HiwGold.warmGold : t.accentColor),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${(model.progress * 100).toInt()}% Complete',
                          style: TextStyle(
                            color: _isPro ? HiwGold.deepGold : t.mutedColor,
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${model.totalXP} Total XP Earned',
                          style: TextStyle(
                            color: t.mutedColor,
                            fontSize: 11.sp,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(height: 16.h),

              // 🪙 HW COINS & DAILY CHECK-IN ROW
              Row(
                children: [
                  // HW Coins Wallet Card
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.all(14.r),
                      decoration: BoxDecoration(
                        color: t.cardBackground,
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(color: t.cardStroke),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text('🪙', style: TextStyle(fontSize: 18.sp)),
                              SizedBox(width: 6.w),
                              Text(
                                'HW Coins',
                                style: TextStyle(
                                  color: t.mutedColor,
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8.h),
                          ListenableBuilder(
                            listenable: _wallet,
                            builder: (context, _) => Text(
                              '${_wallet.balance}',
                              style: TextStyle(
                                color: t.inkColor,
                                fontSize: 24.sp,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            'Virtual rewards • No cash value',
                            style: TextStyle(
                              color: t.mutedColor.withValues(alpha: 0.8),
                              fontSize: 10.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(width: 12.w),

                  // Daily Check-In Card
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.all(14.r),
                      decoration: BoxDecoration(
                        color: t.cardBackground,
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                          color: _checkedInToday ? Colors.green.withValues(alpha: 0.4) : t.accentColor,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text('📅', style: TextStyle(fontSize: 18.sp)),
                              SizedBox(width: 6.w),
                              Text(
                                'Daily Check-In',
                                style: TextStyle(
                                  color: t.mutedColor,
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            _checkedInToday ? 'Day $_checkInStreak Streak' : '+1 HW Coin & +20 XP',
                            style: TextStyle(
                              color: t.inkColor,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 6.h),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _checkedInToday ? Colors.green : t.accentColor,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: 6.h),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                elevation: 0,
                              ),
                              onPressed: _checkedInToday ? null : _claimCheckIn,
                              child: Text(
                                _checkedInToday
                                    ? 'Claimed ✅'
                                    : (_checkingIn ? '...' : 'Claim'),
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 20.h),

              // 📖 HOW XP IS EARNED SECTION
              Text(
                'How to Earn XP',
                style: TextStyle(
                  color: t.inkColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16.sp,
                ),
              ),
              SizedBox(height: 10.h),
              Container(
                padding: EdgeInsets.all(14.r),
                decoration: BoxDecoration(
                  color: t.cardBackground,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: t.cardStroke),
                ),
                child: Column(
                  children: [
                    _xpRow(t, '🍽️', 'Food & Meal Logging', '+15 to +20 XP', 'Track breakfast, lunch, snack, or dinner'),
                    Divider(color: t.cardStroke, height: 16.h),
                    _xpRow(t, '💧', 'Hydration Progress', '+10 XP', 'Log daily water intake milestones'),
                    Divider(color: t.cardStroke, height: 16.h),
                    _xpRow(t, '🔥', 'Active Habit Streaks', '+40 XP', 'Keep your daily consistency unbroken'),
                    Divider(color: t.cardStroke, height: 16.h),
                    _xpRow(t, '🌱', 'Food Index Discovery', '+15 XP', 'Explore regional foods and healthy nutrition'),
                  ],
                ),
              ),

              SizedBox(height: 20.h),

              // 🏅 ACHIEVEMENTS SECTION
              Text(
                'Achievements',
                style: TextStyle(
                  color: t.inkColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16.sp,
                ),
              ),
              SizedBox(height: 10.h),
              ..._engine.achievements.map((a) => Container(
                    margin: EdgeInsets.only(bottom: 10.h),
                    padding: EdgeInsets.all(12.r),
                    decoration: BoxDecoration(
                      color: t.cardBackground,
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(
                        color: a.unlocked ? t.accentColor.withValues(alpha: 0.5) : t.cardStroke,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44.w,
                          height: 44.h,
                          decoration: BoxDecoration(
                            color: a.unlocked
                                ? t.accentColor.withValues(alpha: 0.15)
                                : t.cardStroke.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Center(
                            child: Text(
                              a.icon,
                              style: TextStyle(fontSize: 22.sp),
                            ),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                a.title,
                                style: TextStyle(
                                  color: t.inkColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14.sp,
                                ),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                a.description,
                                style: TextStyle(
                                  color: t.mutedColor,
                                  fontSize: 11.5.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: a.unlocked
                                ? Colors.green.withValues(alpha: 0.15)
                                : t.cardStroke.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Text(
                            a.unlocked ? 'Unlocked' : '+${a.xpReward} XP',
                            style: TextStyle(
                              color: a.unlocked ? Colors.green : t.mutedColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 11.sp,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),

              SizedBox(height: 16.h),

              // 📜 RECENT XP EVENTS
              if (_engine.recentEvents.isNotEmpty) ...[
                Text(
                  'Recent Activity',
                  style: TextStyle(
                    color: t.inkColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16.sp,
                  ),
                ),
                SizedBox(height: 10.h),
                Container(
                  padding: EdgeInsets.all(14.r),
                  decoration: BoxDecoration(
                    color: t.cardBackground,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: t.cardStroke),
                  ),
                  child: Column(
                    children: _engine.recentEvents.take(8).map((ev) {
                      final timeStr = DateFormat.MMMd().add_jm().format(ev.timestamp);
                      return Padding(
                        padding: EdgeInsets.symmetric(vertical: 6.h),
                        child: Row(
                          children: [
                            Text('⚡', style: TextStyle(fontSize: 14.sp)),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Text(
                                ev.title,
                                style: TextStyle(
                                  color: t.inkColor,
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Text(
                              '+${ev.xp} XP',
                              style: TextStyle(
                                color: t.accentColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 13.sp,
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              timeStr,
                              style: TextStyle(
                                color: t.mutedColor,
                                fontSize: 10.sp,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _xpRow(
    HiwTheme t,
    String icon,
    String title,
    String xp,
    String desc,
  ) {
    return Row(
      children: [
        Text(icon, style: TextStyle(fontSize: 20.sp)),
        SizedBox(width: 10.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: t.inkColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13.sp,
                ),
              ),
              Text(
                desc,
                style: TextStyle(color: t.mutedColor, fontSize: 11.sp),
              ),
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
          decoration: BoxDecoration(
            color: t.accentColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Text(
            xp,
            style: TextStyle(
              color: t.accentColor,
              fontWeight: FontWeight.bold,
              fontSize: 11.sp,
            ),
          ),
        ),
      ],
    );
  }
}
