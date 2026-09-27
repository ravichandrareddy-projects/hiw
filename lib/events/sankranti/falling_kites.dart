import 'dart:math';
import 'package:flutter/material.dart';

class FallingKites extends StatefulWidget {
  final int count;
  const FallingKites({super.key, this.count = 5});

  @override
  State<FallingKites> createState() => _FallingKitesState();
}

class _FallingKitesState extends State<FallingKites>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final Random _rnd = Random();
  late List<_Kite> _kites;

  @override
  void initState() {
    super.initState();
    _kites = List.generate(widget.count, (_) => _Kite.random(_rnd));
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
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
          for (final k in _kites) {
            k.update();
          }
          return CustomPaint(
            painter: _KitePainter(_kites),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _Kite {
  double x, y, size, speedX, speedY;
  Color color;
  double angle;
  double rotationSpeed;
  double scale;

  _Kite(this.x, this.y, this.size, this.speedX, this.speedY, this.color,
      this.angle, this.rotationSpeed, this.scale);

  factory _Kite.random(Random rnd) {
    return _Kite(
      rnd.nextDouble(),
      rnd.nextDouble() * 1.2, // Start off-screen
      rnd.nextDouble() * 25 + 25,
      (rnd.nextDouble() - 0.5) * 0.0015,
      rnd.nextDouble() * 0.001 + 0.0008,
      Colors.primaries[rnd.nextInt(Colors.primaries.length)]
          .withValues(alpha: 0.8),
      rnd.nextDouble() * pi / 4 - pi / 8,
      (rnd.nextDouble() - 0.5) * 0.02,
      rnd.nextDouble() * 0.5 + 0.5, // Depth variation
    );
  }

  void update() {
    y -= speedY;
    x += speedX + sin(y * 5) * 0.0005; // Added swaying
    angle += rotationSpeed;

    if (y < -0.2) {
      y = 1.2;
      x = Random().nextDouble();
    }
    if (x < -0.2) x = 1.2;
    if (x > 1.2) x = -0.2;
  }
}

class _KitePainter extends CustomPainter {
  final List<_Kite> kites;
  _KitePainter(this.kites);

  @override
  void paint(Canvas canvas, Size size) {
    for (final k in kites) {
      final pos = Offset(k.x * size.width, k.y * size.height);
      final kiteSize = k.size * k.scale;

      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(k.angle);

      // 🪁 KITE BODY (TRADITIONAL DIAMOND)
      final bodyPaint = Paint()
        ..color = k.color
        ..style = PaintingStyle.fill;

      final path = Path()
        ..moveTo(0, -kiteSize) // Top
        ..lineTo(kiteSize * 0.9, 0) // Right
        ..lineTo(0, kiteSize) // Bottom
        ..lineTo(-kiteSize * 0.9, 0) // Left
        ..close();
      canvas.drawPath(path, bodyPaint);

      // 📐 STRUCTURE LINES (CROSS BARS)
      final structurePaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      // Vertical Bar
      canvas.drawLine(
          Offset(0, -kiteSize), Offset(0, kiteSize), structurePaint);

      // Curved Horizontal Bar
      final curvePath = Path()
        ..moveTo(-kiteSize * 0.9, 0)
        ..quadraticBezierTo(0, -kiteSize * 0.4, kiteSize * 0.9, 0);
      canvas.drawPath(curvePath, structurePaint);

      // 📐 BOTTOM TRIANGLE (TAIL FIN)
      final finPaint = Paint()
        ..color = k.color.withValues(alpha: 0.9)
        ..style = PaintingStyle.fill;

      final finPath = Path()
        ..moveTo(0, kiteSize)
        ..lineTo(kiteSize * 0.25, kiteSize + kiteSize * 0.25)
        ..lineTo(-kiteSize * 0.25, kiteSize + kiteSize * 0.25)
        ..close();
      canvas.drawPath(finPath, finPaint);

      // 🧵 TRAILING THREAD
      final threadPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;

      canvas.drawLine(Offset(0, kiteSize + kiteSize * 0.25),
          Offset(sin(k.angle) * 40, kiteSize * 3), threadPaint);

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_) => true;
}
