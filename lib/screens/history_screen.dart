import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../events/christmas/christmas_background.dart';
import 'weekly_history_screen.dart';
import 'monthly_history_screen.dart';
import 'protein_history_screen.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
      child: SizedBox(
        height: 760,
        child: Stack(
          children: [
            // WEEKLY – TOP LEFT
            Positioned(
              top: 0,
              left: 0,
              child: _floatingPie(
                context,
                title: "Weekly\nHealthy vs Junk",
                healthy: 72,
                junk: 28,
                onTap: () =>
                    _open(context, const WeeklyHistoryScreen()),
              ),
            ),

            // MONTHLY – CENTER RIGHT
            Positioned(
              top: 250,
              right: 0,
              child: _floatingPie(
                context,
                title: "Monthly\nHealthy vs Junk",
                healthy: 68,
                junk: 32,
                onTap: () =>
                    _open(context, const MonthlyHistoryScreen()),
              ),
            ),

            // PROTEIN – BOTTOM LEFT (NO CONST ❗)
            Positioned(
              top: 520,
              left: 0,
              child: _floatingPie(
                context,
                title: "Monthly\nProtein Intake",
                healthy: 110,
                junk: 40,
                isPercent: false,
                onTap: () =>
                    _open(context, ProteinHistoryScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _open(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChristmasBackground(child: screen),
      ),
    );
  }

  Widget _floatingPie(
    BuildContext context, {
    required String title,
    required double healthy,
    required double junk,
    bool isPercent = true,
    required VoidCallback onTap,
  }) {
    final size = MediaQuery.of(context).size.width * 0.55;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 10),

          ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.25),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: PieChart(
                    PieChartData(
                      centerSpaceRadius: size * 0.30,
                      sectionsSpace: 2,
                      startDegreeOffset: -90,
                      sections: [
                        PieChartSectionData(
                          value: healthy,
                          color: Colors.tealAccent,
                          title: isPercent
                              ? "${healthy.toInt()}%"
                              : "${healthy.toInt()}g",
                          titleStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        PieChartSectionData(
                          value: junk,
                          color: Colors.redAccent,
                          title: isPercent
                              ? "${junk.toInt()}%"
                              : "",
                          titleStyle: const TextStyle(
                            fontSize: 10,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                    swapAnimationDuration:
                        const Duration(milliseconds: 900),
                    swapAnimationCurve: Curves.easeOutCubic,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
