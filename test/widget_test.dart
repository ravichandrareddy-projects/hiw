import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiw/widgets/premium_glass_card.dart';

void main() {
  testWidgets('PremiumGlassCard renders child widget smoke test',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ScreenUtilInit(
            designSize: Size(393, 851),
            child: PremiumGlassCard(
              child: Text('HIW Card'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('HIW Card'), findsOneWidget);
    expect(find.byType(PremiumGlassCard), findsOneWidget);
  });
}
