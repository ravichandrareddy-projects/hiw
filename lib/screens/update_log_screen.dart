import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';
import '../widgets/premium_glass_card.dart';

class UpdateLogScreen extends StatelessWidget {
  const UpdateLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Fallback
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F172A), // Deep navy
              Color(0xFF020617), // Near black
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: EdgeInsets.all(16.0.r),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      'Development Roadmap',
                      style: TextStyle(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: Colors.tealAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(color: Colors.tealAccent.withOpacity(0.3)),
                      ),
                      child: Text(
                        'v0.03.05',
                        style: TextStyle(
                          color: Colors.tealAccent,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Divider(color: Colors.white10),

              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 12.h),
                      
                      // 🚀 LAUNCH ANNOUNCEMENT
                      _infoCard(
                        context,
                        icon: Icons.rocket_launch,
                        color: Colors.tealAccent,
                        title: 'Official Launch: Mid-March',
                        description: 'HIW is entering the final polishing phase. We are on track for a public release in mid-March! 🚀',
                      ),

                      SizedBox(height: 32.h),

                      // ✨ LATEST UPDATES
                      Text(
                        '✨ LATEST IMPROVEMENTS',
                        style: TextStyle(
                          color: Colors.tealAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 14.sp,
                          letterSpacing: 1.2,
                        ),
                      ),
                      SizedBox(height: 16.h),
                      
                      _updateItem(
                        '🥗 Enhanced Food UI',
                        'Refined the food screen with a premium visual upgrade: larger fonts, bold nutrient cards, tightened card spacing, and a large dynamic daily calorie progress bar.',
                      ),
                      _updateItem(
                        '🤖 Split Identity Chatbot',
                        'Restructured the AI into two specialized modes: Health Expert (Foodity) and Empathic Mood Support.',
                      ),
                      _updateItem(
                        '👋 Free Greetings',
                        'Simple greetings like "Hi," "Hello," or "Good morning" no longer consume your daily energy. Talk freely! ✨',
                      ),
                      _updateItem(
                        '🛡️ Domain Restriction',
                        'Foodity now strictly focuses on Food, Nutrition, and Health questions to provide more accurate advice.',
                      ),
                      _updateItem(
                        '💙 Proactive Support',
                        'Mood Support AI is now solution-oriented, offering immediate practical remedies (breathing, tips) for user.',
                      ),
                      _updateItem(
                        '📱 Perfect Scaling',
                        'New responsive layout system ensures the premium UI looks stunning on any device size.',
                      ),
                      _updateItem(
                        '🧹 Daily Refresh',
                        'All chat history and daily limits now automatically reset at midnight for a fresh start.',
                      ),

                      SizedBox(height: 40.h),

                      // 🛠️ UPCOMING FEATURES
                      Text(
                        '🛠️ WORK IN PROGRESS',
                        style: TextStyle(
                          color: Colors.orangeAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 14.sp,
                          letterSpacing: 1.2,
                        ),
                      ),
                      SizedBox(height: 16.h),

                      _updateItem(
                        '🧠 Model Update 2.0',
                        'Our core ML model is being upgraded for even higher accuracy in nutrient detection and health insights.\nBy the time of deployment, the model will predict over 70 types of food items and 30 different types of fruits and veggies. Working on it, Stay Tuned!!',
                        isUpcoming: true,
                      ),
                      _updateItem(
                        '📝 Describe Your Meal',
                        'Describe your lunch in words or voice to get instant nutrition data.',
                        isUpcoming: true,
                      ),
                      _updateItem(
                        '🎨 Help Us Shape the Default HIW UI',
                        'We want the "Default HIW" vibe to be perfect. When there are no festivals or sports events, what aesthetic fits health and wealth best? Drop your feedback or design ideas to help us set the standard look! 🤝',
                        isUpcoming: true,
                      ),

                      _updateItem(
                        '🌐 Website & Community',
                        'We are building an official HIW landing page and a WhatsApp community for exclusive sneak peeks, live updates, and direct feedback channels. Stay tuned! 🚀',
                        isUpcoming: true,
                      ),

                      SizedBox(height: 40.h),

                      // 🛠️ TESTER TOOLKIT
                      Text(
                        '🛠️ TESTER TOOLKIT',
                        style: TextStyle(
                          color: Colors.lightBlueAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 14.sp,
                          letterSpacing: 1.2,
                        ),
                      ),
                      SizedBox(height: 16.h),
                      
                      _updateItem(
                        '🧹 /clean',
                        'Wipe all chat history and local cache immediately. Use in any AI chat.',
                      ),
                      _updateItem(
                        '🔥 /streak',
                        'Instantly seed a 10-day test streak in your history for UI verification.',
                      ),
                      _updateItem(
                        '🧩 Dynamic Stats: /<num>[H|E|S]',
                        'Add/remove specific stats. Examples: /25H (Health), /10E (Energy), /5S (Stamina). Supports negative numbers like /-10H.',
                      ),
                      _updateItem(
                        '🎯 /max | /mid | /min',
                        'Set your daily calorie goal to high, medium, or low levels for testing progress bars.',
                      ),
                      _updateItem(
                        '🗑️ /remove_chat [name]',
                        'Delete a specific chat session by typing its exact name (e.g. /remove_chat yo).',
                      ),
                      _updateItem(
                        '🔄 /reset | /reste',
                        'Clear all daily nutrient progress for the current day without affecting history. Also resets chat limits.',
                      ),

                      SizedBox(height: 40.h),
                      
                      Center(
                        child: Text(
                          'Stay tuned, my friends! Updates drop frequently.\nHIW: Health is Wealth.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white24,
                            fontSize: 12.sp,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                      SizedBox(height: 40.h),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoCard(BuildContext context, {required IconData icon, required Color color, required String title, required String description}) {
    return PremiumGlassCard(
      padding: EdgeInsets.all(20.r),
      borderRadius: 20,
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15.r),
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          SizedBox(width: 20.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16.sp),
                ),
                SizedBox(height: 4.h),
                Text(
                  description,
                  style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13.sp),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _updateItem(String title, String desc, {bool isUpcoming = false}) {
    final color = isUpcoming ? Colors.orangeAccent : Colors.tealAccent;
    return Padding(
      padding: EdgeInsets.only(bottom: 24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle_outline, color: color.withOpacity(0.5), size: 16),
              SizedBox(width: 8.w),
              Text(
                title,
                style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15.sp),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Padding(
            padding: EdgeInsets.only(left: 24.w),
            child: Text(
              desc,
              style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14.sp, height: 1.4.h),
            ),
          ),
        ],
      ),
    );
  }
}
