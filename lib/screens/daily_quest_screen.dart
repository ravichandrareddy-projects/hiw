import 'package:flutter/material.dart';
import '../widgets/stub_screen.dart';
import '../themes/hiw_theme.dart';

class DailyQuestScreen extends StatelessWidget {
  const DailyQuestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StubScreen(
      title: 'Daily Quests',
      icon: Icons.rocket_launch_rounded,
      iconColor: HiwTheme.of(context).accentColor,
      message: 'Daily Quests\nComing Soon 🚀',
    );
  }
}
