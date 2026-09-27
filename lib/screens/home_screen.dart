import 'package:flutter/material.dart';
import '../widgets/bottom_nav.dart';

// screens
import 'chatbot_screen.dart';
import 'food_screen.dart';
import 'scanner_screen.dart';
import 'history_screen.dart';
import 'avatar_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 2; // default Food tab

  List<Widget> _buildScreens() => [
        const ChatbotScreen(),

        // ✅ REQUIRED PARAM PROVIDED
        FoodScreen(
          onUpdateAvatar: ({required int dailyRaw}) {},
        ),

        // ✅ REQUIRED PARAM PROVIDED
        ScannerScreen(
          isActive: _index == 2,
          onFoodAnalyzed: ({
            required ImageProvider image,
            required String label,
            required double healthyScore,
            required double quantity,
            nutritionRecord,
            required items,
          }) {},
        ),

        const HistoryScreen(),

        // ✅ REQUIRED PARAMS PROVIDED
        const AvatarScreen(
          healthPercent: 0,
          energyPercent: 0,
          staminaPercent: 0,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,

      body: IndexedStack(
        index: _index,
        children: _buildScreens(),
      ),

      bottomNavigationBar: BottomNav(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}
