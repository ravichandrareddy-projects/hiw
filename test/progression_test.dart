import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hiw/core/progression_engine.dart';
import 'package:hiw/core/hw_wallet.dart';
import 'package:hiw/services/daily_checkin_service.dart';
import 'package:hiw/core/ai/ai_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ProgressionEngine Tests', () {
    test('Progression curve generates progressive thresholds', () {
      final lvl1 = ProgressionEngine.xpForLevel(1);
      final lvl2 = ProgressionEngine.xpForLevel(2);
      final lvl5 = ProgressionEngine.xpForLevel(5);
      final lvl10 = ProgressionEngine.xpForLevel(10);

      expect(lvl1, 100);
      expect(lvl2 > lvl1, true);
      expect(lvl5 > lvl2, true);
      expect(lvl10 > lvl5, true);
    });

    test('Initial level is 1 with 0 XP', () async {
      final engine = ProgressionEngine();
      await engine.init();
      expect(engine.currentLevel, 1);
      expect(engine.totalXP, 0);
      expect(engine.levelModel.progress, 0.0);
    });

    test('awardXP increments XP and triggers level-up when crossing threshold', () async {
      final engine = ProgressionEngine();
      await engine.init();

      final leveledUp = await engine.awardXP(120, title: 'Big Habit', category: 'habit');
      expect(leveledUp, true);
      expect(engine.currentLevel, 2);
      expect(engine.recentEvents.isNotEmpty, true);
      expect(engine.recentEvents.first.title, 'Big Habit');
    });
  });

  group('HWWallet Tests', () {
    test('Wallet credits virtual non-cash coins and maintains ledger', () async {
      final wallet = HWWallet();
      await wallet.init();

      expect(wallet.balance, 0);
      await wallet.credit(5, reason: 'Streak milestone');
      expect(wallet.balance, 5);
      expect(wallet.ledger.first.reason, 'Streak milestone');
      expect(wallet.ledger.first.amount, 5);
    });
  });

  group('DailyCheckInService Tests', () {
    test('Daily check-in awards 1 coin + 20 XP and prevents duplicate same-day claims', () async {
      final checkIn = DailyCheckInService();

      // First check in
      final firstResult = await checkIn.performCheckIn();
      expect(firstResult.success, true);
      expect(firstResult.alreadyCheckedIn, false);
      expect(firstResult.coinsEarned, 1);
      expect(firstResult.xpEarned, 20);

      // Duplicate check in on same day
      final secondResult = await checkIn.performCheckIn();
      expect(secondResult.success, false);
      expect(secondResult.alreadyCheckedIn, true);
    });
  });

  group('AI Provider Abstraction Tests', () {
    test('FallbackChatProvider delivers helpful guidance without network', () async {
      final fallback = FallbackChatProvider();
      final reply = await fallback.ask('How much water should I drink?');
      expect(reply.contains('water') || reply.contains('hydrated'), true);
    });

    test('AiManager switches chat provider smoothly', () async {
      final manager = AiManager();
      manager.configureChatProvider(FallbackChatProvider());
      expect(manager.chatProvider.name, 'Offline Assistant');

      final insight = await manager.chartInsightProvider.getInsight(
        chartData: {'calories': 1800, 'protein': 90},
        userGoal: 'Weight Loss',
      );
      expect(insight.isNotEmpty, true);
    });
  });
}
