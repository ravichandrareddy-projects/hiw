import 'dart:math';
import 'package:flutter/material.dart';

class FallingSnow extends StatefulWidget {
  final int flakes;
  const FallingSnow({super.key, this.flakes = 55}); // heavy like image

  @override
  State<FallingSnow> createState() => _FallingSnowState();
}

class _FallingSnowState extends State<FallingSnow>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final Random _rnd = Random();
  late List<_SnowFlake> _flakes;

  @override
  void initState() {
    super.initState();

    _flakes = List.generate(widget.flakes, (_) => _SnowFlake.random(_rnd));

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 22),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) {
          for (final f in _flakes) {
            f.update();
          }
          return CustomPaint(
            painter: _SnowPainter(_flakes),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _SnowFlake {
  double x, y, r, speed;

  _SnowFlake(this.x, this.y, this.r, this.speed);

  factory _SnowFlake.random(Random rnd) {
    return _SnowFlake(
      rnd.nextDouble(),
      rnd.nextDouble(),
      rnd.nextDouble() * 2.8 + 1.5, // BIG flakes
      rnd.nextDouble() * 0.002 + 0.001,
    );
  }

  void update() {
    y += speed;
    if (y > 1) {
      y = 0;
      x = Random().nextDouble();
    }
  }
}

class _SnowPainter extends CustomPainter {
  final List<_SnowFlake> flakes;
  _SnowPainter(this.flakes);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.55); // strong snow

    for (final f in flakes) {
      canvas.drawCircle(
        Offset(f.x * size.width, f.y * size.height),
        f.r,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_) => true;
}
