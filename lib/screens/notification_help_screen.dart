import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../widgets/glass_card.dart';

class NotificationHelpScreen extends StatelessWidget {
  const NotificationHelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Fix Notifications'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(20.r),
          children: [
            Text(
              '🔔 Notification Troubleshooting',
              style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20.h),
            GlassCard(
              padding: EdgeInsets.all(16.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'For MIUI/Xiaomi Devices (Redmi, Mi)',
                    style:
                        TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 12.h),
                  _buildStep('1', 'Go to Settings → Apps → Manage Apps'),
                  _buildStep('2', 'Find and tap "HIW"'),
                  _buildStep(
                      '3', 'Tap "Battery saver" → Select "No restrictions"'),
                  _buildStep('4', 'Go back → Tap "Autostart" → Enable it'),
                  _buildStep('5', 'Go back → Tap "Notifications" → Enable all'),
                  SizedBox(height: 12.h),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await openAppSettings();
                    },
                    icon: const Icon(Icons.settings),
                    label: const Text('Open App Settings'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20.h),
            GlassCard(
              padding: EdgeInsets.all(16.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'For Other Android Devices',
                    style:
                        TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 12.h),
                  _buildStep('1', 'Go to Settings → Apps → HIW'),
                  _buildStep('2', 'Enable "Notifications"'),
                  _buildStep('3', 'Disable "Battery optimization" for HIW'),
                  _buildStep('4', 'Enable "Alarms & reminders" permission'),
                ],
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              '💡 After making these changes, restart the app and try the test notification again!',
              style: TextStyle(fontSize: 14.sp, fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(String number, String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24.w,
            height: 24.h,
            decoration: BoxDecoration(
              color: Colors.tealAccent.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              number,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12.sp,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 14.sp),
            ),
          ),
        ],
      ),
    );
  }
}
