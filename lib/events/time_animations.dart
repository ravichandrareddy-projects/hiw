import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:math';
import 'package:flutter/material.dart';

/// 🌅 MORNING: WIND BLOWING / CLOUDS
class MorningWind extends StatefulWidget {
  const MorningWind({super.key});

  @override
  State<MorningWind> createState() => _MorningWindState();
}

class _MorningWindState extends State<MorningWind>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_WindLine> _lines = List.generate(15, (_) => _WindLine.random());

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 10))
          ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        for (var line in _lines) {
          line.update();
        }
        return CustomPaint(
          painter: _WindPainter(_lines),
          size: Size.infinite,
        );
      },
    );
  }
}

class _WindLine {
  double x, y, length, speed;
  _WindLine(this.x, this.y, this.length, this.speed);
  factory _WindLine.random() {
    final r = Random();
    return _WindLine(r.nextDouble(), r.nextDouble(), r.nextDouble() * 50 + 50,
        r.nextDouble() * 0.005 + 0.002);
  }
  void update() {
    x += speed;
    if (x > 1.2) {
      x = -0.2;
      y = Random().nextDouble();
    }
  }
}

class _WindPainter extends CustomPainter {
  final List<_WindLine> lines;
  _WindPainter(this.lines);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    for (var l in lines) {
      canvas.drawLine(
        Offset(l.x * size.width, l.y * size.height),
        Offset((l.x + l.length / size.width) * size.width, l.y * size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_) => true;
}

/// ☀️ AFTERNOON: MOVING SUN WITH RAYS
class AfternoonSun extends StatefulWidget {
  const AfternoonSun({super.key});

  @override
  State<AfternoonSun> createState() => _AfternoonSunState();
}

class _AfternoonSunState extends State<AfternoonSun>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 20))
          ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    // Afternoon is 12:00 to 16:59 (5 hours total)
    const totalMinutes = 5 * 60;
    final currentMinutes = (now.hour - 12) * 60 + now.minute;
    final progress = (currentMinutes / totalMinutes).clamp(0.0, 1.0);

    return Stack(
      children: [
        Positioned(
          right: 20,
          top: 50 + (progress * 300),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return SizedBox(
                width: 150.w,
                height: 150.h,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // 🌞 SUN RAYS
                    CustomPaint(
                      painter: _SunRaysPainter(_controller.value),
                      size: const Size(150, 150),
                    ),
                    // ☀️ SUN CORE
                    Container(
                      width: 60.w,
                      height: 60.h,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.orangeAccent.withValues(alpha: 0.9),
                            Colors.yellowAccent.withValues(alpha: 0.4),
                            Colors.orange.withValues(alpha: 0.0),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withValues(alpha: 0.2),
                            blurRadius: 30.r,
                            spreadRadius: 10.r,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SunRaysPainter extends CustomPainter {
  final double animationValue;
  _SunRaysPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = Colors.orangeAccent.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    const rayCount = 8;
    const innerRadius = 35.0;
    const outerRadius = 70.0;
    const angleStep = (2 * pi) / rayCount;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(animationValue * 2 * pi); // Soft rotation

    for (int i = 0; i < rayCount; i++) {
      final angle = i * angleStep;
      final path = Path();
      path.moveTo(
          cos(angle - 0.2) * innerRadius, sin(angle - 0.2) * innerRadius);
      path.lineTo(cos(angle) * outerRadius, sin(angle) * outerRadius);
      path.lineTo(
          cos(angle + 0.2) * innerRadius, sin(angle + 0.2) * innerRadius);
      path.close();
      canvas.drawPath(path, paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_) => true;
}

/// 🌙 NIGHT: TWINKLING STARS
class NightStars extends StatefulWidget {
  const NightStars({super.key});

  @override
  State<NightStars> createState() => _NightStarsState();
}

class _NightStarsState extends State<NightStars>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Star> _stars = List.generate(100, (_) => _Star.random());

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 4))
          ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          painter: _StarPainter(_stars, _controller.value),
          size: Size.infinite,
        );
      },
    );
  }
}

class _Star {
  double x, y, size, phase;
  _Star(this.x, this.y, this.size, this.phase);
  factory _Star.random() {
    final r = Random();
    return _Star(r.nextDouble(), r.nextDouble(), r.nextDouble() * 2 + 1,
        r.nextDouble() * pi * 2);
  }
}

class _StarPainter extends CustomPainter {
  final List<_Star> stars;
  final double animationValue;
  _StarPainter(this.stars, this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    for (var s in stars) {
      final opacity =
          (0.2 + 0.8 * (0.5 + 0.5 * sin(animationValue * pi * 4 + s.phase)))
              .clamp(0.0, 1.0);
      final paint = Paint()..color = Colors.white.withValues(alpha: opacity);
      canvas.drawCircle(
          Offset(s.x * size.width, s.y * size.height), s.size, paint);
    }
  }

  @override
  bool shouldRepaint(_) => true;
}

/// 🌇 EVENING: SETTING SUN
class EveningSunset extends StatefulWidget {
  const EveningSunset({super.key});

  @override
  State<EveningSunset> createState() => _EveningSunsetState();
}

class _EveningSunsetState extends State<EveningSunset>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 15))
          ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    // Evening is 17:00 to 19:59 (3 hours total)
    const totalMinutes = 3 * 60;
    final currentMinutes = (now.hour - 17) * 60 + now.minute;
    final progress = (currentMinutes / totalMinutes).clamp(0.0, 1.0);

    return Stack(
      children: [
        Positioned(
          left: 40 + (progress * 100),
          bottom: 100 - (progress * 150), // Sinks below horizon
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return SizedBox(
                width: 250.w,
                height: 250.h,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // 🌇 SUN GLOW
                    Container(
                      width: 200.w,
                      height: 200.h,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.deepOrange.withValues(
                                alpha: 0.4 * (1.0 - progress * 0.5)),
                            Colors.orangeAccent.withValues(alpha: 0.1),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                    // ☀️ SUN DISK
                    Container(
                      width: 80.w,
                      height: 80.h,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.orangeAccent,
                            Colors.deepOrange,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.deepOrange.withValues(alpha: 0.5),
                            blurRadius: 40.r + (_controller.value * 20),
                            spreadRadius: 5.r,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
