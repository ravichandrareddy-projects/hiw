import 'dart:math';
import 'package:flutter/material.dart';

class FireworksAnimation extends StatefulWidget {
  const FireworksAnimation({super.key});

  @override
  State<FireworksAnimation> createState() => _FireworksAnimationState();
}

class _FireworksAnimationState extends State<FireworksAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final Random _rnd = Random();
  final List<_Firework> _fireworks = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )
      ..addListener(() {
        _update();
      })
      ..repeat();
  }

  void _update() {
    if (_rnd.nextDouble() < 0.05) {
      _fireworks.add(_Firework.random(_rnd));
    }

    for (int i = _fireworks.length - 1; i >= 0; i--) {
      _fireworks[i].update();
      if (_fireworks[i].isDead) {
        _fireworks.removeAt(i);
      }
    }
    setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _FireworksPainter(_fireworks),
        size: Size.infinite,
      ),
    );
  }
}

class _Firework {
  double x, y;
  Color color;
  List<_Particle> particles = [];
  bool isDead = false;

  _Firework.random(Random rnd)
      : x = rnd.nextDouble(),
        y = rnd.nextDouble() * 0.5,
        color = Colors.primaries[rnd.nextInt(Colors.primaries.length)] {
    int count = rnd.nextInt(20) + 30;
    for (int i = 0; i < count; i++) {
      particles.add(_Particle.random(rnd, color));
    }
  }

  void update() {
    for (final p in particles) {
      p.update();
    }
    if (particles.every((p) => p.life <= 0)) {
      isDead = true;
    }
  }
}

class _Particle {
  double vx, vy;
  double life;
  double x = 0, y = 0;
  Color color;

  _Particle.random(Random rnd, this.color)
      : vx = (rnd.nextDouble() - 0.5) * 0.015,
        vy = (rnd.nextDouble() - 0.5) * 0.015,
        life = 1.0;

  void update() {
    x += vx;
    y += vy;
    vy += 0.0002; // gravity
    life -= 0.02;
  }
}

class _FireworksPainter extends CustomPainter {
  final List<_Firework> fireworks;
  _FireworksPainter(this.fireworks);

  @override
  void paint(Canvas canvas, Size size) {
    for (final fw in fireworks) {
      for (final p in fw.particles) {
        if (p.life <= 0) continue;
        final paint = Paint()
          ..color = fw.color.withValues(alpha: p.life)
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round;

        canvas.drawCircle(
          Offset((fw.x + p.x) * size.width, (fw.y + p.y) * size.height),
          1.5,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_) => true;
}
