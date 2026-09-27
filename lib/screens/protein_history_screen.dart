import 'package:flutter/material.dart';
import '../widgets/stub_screen.dart';

class ProteinHistoryScreen extends StatelessWidget {
  const ProteinHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const StubScreen(
      title: 'Protein History',
      icon: Icons.fitness_center_rounded,
      iconColor: Colors.orangeAccent,
      message: 'Protein history coming soon 🥩',
    );
  }
}
