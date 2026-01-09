//lib/screens/avatar_screen.dart
import 'package:flutter/material.dart';

enum AvatarStage { unhealthy, normal, healthy, veryHealthy }

class AvatarScreen extends StatelessWidget {
  final double healthPercent;        // weekly finalized
  final double energyPercent;        // weekly finalized
  final double staminaPercent;       // 🆕 daily preview stamina

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
    final stage = _stage(healthPercent);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // -------------------------
        // AVATAR CARD
        // -------------------------
        Center(
          child: Container(
            width: 200,
            height: 240,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: _gradient(stage),
              border: Border.all(
                color: Colors.tealAccent.withOpacity(0.8),
                width: 2,
              ),
            ),
            child: const Center(
              child: Text(
                '3D Avatar\nplaceholder',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 20),

        // -------------------------
        // STATS
        // -------------------------
        _statRow('Health (weekly)', healthPercent),
        _statRow('Energy (weekly)', energyPercent),
        _statRow('Stamina (today)', staminaPercent), // 🆕

        const SizedBox(height: 12),

        Center(
          child: Text(
            'Stage: ${stage.name.toUpperCase()}',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),

        const SizedBox(height: 28),

        // -------------------------
        // 🎮 GAME ACCESS (TESTER MODE)
        // -------------------------
        Center(
          child: Column(
            children: [
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
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const GamingWorldScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 10),

              // 🔒 OFFICIAL RULE NOTE
              const Text(
                'ℹ️ Official game unlock: Every Saturday at 4:00 PM\n'
                '(Tester access currently enabled)',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ],
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
  Widget _statRow(String label, double value) {
    return Padding(

      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: (value / 100).clamp(0, 1),
                minHeight: 10,
                backgroundColor: Colors.white12,
                valueColor: const AlwaysStoppedAnimation(
                  Colors.tealAccent,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text('${value.toStringAsFixed(0)}%'),
        ],
      ),
    );
  }
}

// -------------------------
// 🎮 PLACEHOLDER GAME WORLD
// -------------------------
class GamingWorldScreen extends StatelessWidget {
  const GamingWorldScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gaming World')),
      body: const Center(
        child: Text(
          '🎮 Gaming World\n\n'
          'CURRENTLY UNDER CONSTRUCTION\n'
          'Coming Soon 🚀',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
