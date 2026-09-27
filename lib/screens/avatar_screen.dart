import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';
import '../avatar/avatar_store.dart'; // 🔔
import 'profile_screen.dart';
import 'update_log_screen.dart'; // 🆕 Full screen log
import '../widgets/dev_theme_tools.dart';
import '../themes/hiw_theme.dart';

enum AvatarStage { unhealthy, normal, healthy, veryHealthy }

class AvatarScreen extends StatelessWidget {
  final double healthPercent; // weekly finalized
  final double energyPercent; // weekly finalized
  final double staminaPercent; // 🆕 daily preview stamina

  const AvatarScreen({
    super.key,
    required this.healthPercent,
    required this.energyPercent,
    required this.staminaPercent,
  });

  AvatarStage _stage(double p) {
    if (p >= 80) return AvatarStage.veryHealthy;
    if (p >= 60) return AvatarStage.healthy;
    if (p >= 40) return AvatarStage.normal;
    return AvatarStage.unhealthy;
  }

  @override
  Widget build(BuildContext context) {
    // 🔔 LISTEN TO AVATAR STORE LIVE
    return AnimatedBuilder(
      animation: AvatarStore(),
      builder: (context, _) {
        final store = AvatarStore();
        final currentHealth = store.avatar.health;
        final currentEnergy = store.avatar.energy;
        final currentStamina =
            store.dailyStaminaPreview; // preview is the live one

        final stage = _stage(currentHealth);

        return Stack(
          children: [
            ListView(
              padding: EdgeInsets.all(16.r),
              children: [
                SizedBox(height: 40.h), // Space for top buttons

                // -------------------------
                // AVATAR DASHBOARD CARD
                // -------------------------
                Center(
                  child: Container(
                    width: 220.w,
                    height: 240.h,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24.r),
                      gradient: _gradient(stage),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.tealAccent.withValues(alpha: 0.3),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                      border: Border.all(
                        color: Colors.tealAccent.withValues(alpha: 0.8),
                        width: 2.w,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          stage == AvatarStage.veryHealthy
                              ? Icons.workspace_premium
                              : stage == AvatarStage.healthy
                                  ? Icons.favorite
                                  : stage == AvatarStage.normal
                                      ? Icons.emoji_emotions
                                      : Icons.battery_alert,
                          size: 72.r,
                          color: Colors.black87,
                        ),
                        SizedBox(height: 12.h),
                        Text(
                          'Health Avatar Status',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16.sp,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 6.h),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 12.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Text(
                            stage.name.toUpperCase(),
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 12.sp,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 20.h),

                // -------------------------
                // STATS
                // -------------------------
                _statRow(context, 'Health ', currentHealth),
                _statRow(context, 'Energy ', currentEnergy),
                _statRow(context, 'Stamina ', currentStamina),

                SizedBox(height: 24.h),

                Center(
                  child: Column(
                    children: [
                      // 🎮 ENTER GAMING WORLD BUTTON (Coming Soon)
                      ElevatedButton.icon(
                        icon: const Icon(Icons.sports_esports),
                        label: const Text('Enter Gaming World'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                          backgroundColor: Colors.tealAccent,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18.r),
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const _GamingWorldStub(),
                            ),
                          );
                        },
                      ),

                      SizedBox(height: 10.h),

                      Text(
                        'ℹ️ Gaming World is under development\n(Coming Soon)',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                          fontSize: 12.sp,
                          fontStyle: FontStyle.italic,
                        ),
                      ),

                      SizedBox(height: 20.h),

                      // 🚀 UPDATE LOG BUTTON
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const UpdateLogScreen()),
                          );
                        },
                        icon:
                            const Icon(Icons.history_edu, color: Colors.white),
                        label: const Text(
                          'View Update Log',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                              horizontal: 24, vertical: 14.h),
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          elevation: 8,
                          shadowColor: Colors.black.withValues(alpha: 0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15.r),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // ⚙️ SETTINGS / PROFILE BUTTON (Top Right)
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: Icon(Icons.settings,
                    color: Theme.of(context).iconTheme.color, size: 28),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  );
                },
              ),
            ),

            // 🎨 DEV TOOLS BUTTON (Top Left)
            Positioned(
              top: 10,
              left: 10,
              child: IconButton(
                icon: Icon(Icons.palette,
                    color: Theme.of(context).iconTheme.color, size: 28),
                onPressed: () => showDevThemeTools(context),
              ),
            ),
          ],
        );
      },
    );
  }

  // -------------------------
  // GRADIENT BY STAGE
  // -------------------------
  Gradient _gradient(AvatarStage s) {
    switch (s) {
      case AvatarStage.unhealthy:
        return const LinearGradient(
          colors: [Colors.grey, Colors.red],
        );
      case AvatarStage.normal:
        return const LinearGradient(
          colors: [Colors.blueGrey, Colors.green],
        );
      case AvatarStage.healthy:
        return const LinearGradient(
          colors: [Colors.green, Colors.teal],
        );
      case AvatarStage.veryHealthy:
        return const LinearGradient(
          colors: [Colors.teal, Colors.lightGreenAccent],
        );
    }
  }

  // -------------------------
  // STAT ROW
  // -------------------------
  Widget _statRow(BuildContext context, String label, double value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        children: [
          SizedBox(
            width: 110.w,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999.r),
              child: LinearProgressIndicator(
                value: (value / 100).clamp(0, 1),
                minHeight: 10,
                backgroundColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white12
                    : Colors.black.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation(
                  Theme.of(context).primaryColor,
                ),
              ),
            ),
          ),
          SizedBox(width: 8.w),
          Text(
            '${value.toStringAsFixed(0)}%',
            style:
                TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
          ),
        ],
      ),
    );
  }
}

/// Gaming World placeholder — follows the active theme.
class _GamingWorldStub extends StatelessWidget {
  const _GamingWorldStub();

  @override
  Widget build(BuildContext context) {
    final t = HiwTheme.of(context);
    final accent = Theme.of(context).primaryColor;
    return Scaffold(
      backgroundColor:
          t.isMinimal ? null : Colors.black,
      appBar: AppBar(
        title: Text('Gaming World',
            style: TextStyle(color: t.inkColor)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: t.inkColor),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sports_esports,
                size: 72.r, color: accent),
            SizedBox(height: 16.h),
            Text(
              'Gaming World\nComing Soon 🎮',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: t.inkColor,
                fontSize: 22.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              'Stay tuned for interactive avatar worlds!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: t.mutedColor,
                fontSize: 14.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
