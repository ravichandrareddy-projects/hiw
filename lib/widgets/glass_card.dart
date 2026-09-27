//glass card
//
// Legacy name kept for compatibility — now delegates to [HiwCard],
// which renders flat paper in the Plain theme and glass elsewhere.
import 'package:flutter/material.dart';
import 'hiw_card.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double radius;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.radius = 20,
  });

  @override
  Widget build(BuildContext context) {
    return HiwCard(
      padding: padding,
      radius: radius,
      child: child,
    );
  }
}
