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
  int _index = 2; // HIW default (camera/scanner)

  final List<Widget> _screens = const [
    ChatbotScreen(),
    FoodScreen(),
    ScannerScreen(), // HIW main
    HistoryScreen(),
    AvatarScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _screens[_index],
      bottomNavigationBar: BottomNav(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}
