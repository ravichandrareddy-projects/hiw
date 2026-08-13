import 'package:flutter_test/flutter_test.dart';
import 'package:hiw/services/greeting_detection_service.dart';

void main() {
  group('GreetingDetectionService Tests', () {
    test('Detects common greetings and returns offline response', () {
      final greetings = [
        'hi',
        'hello',
        'hey',
        'hlo',
        'hii',
        'good morning',
        'how are you',
        'what\'s up',
        'sup',
        'yo',
        'thanks',
        'bye'
      ];

      for (final g in greetings) {
        expect(GreetingDetectionService.isGreeting(g), isTrue, reason: 'Failed for: $g');
        final reply = GreetingDetectionService.getOfflineGreetingReply(g);
        expect(reply, isNotNull, reason: 'Reply should be non-null for: $g');
      }
    });

    test('Does not intercept food or nutrition questions as greetings', () {
      final questions = [
        'what is the protein content in apple',
        'is pizza healthy for weight loss',
        'suggest a high protein meal plan for dinner',
        'how many calories are in a avocado salad',
      ];

      for (final q in questions) {
        expect(GreetingDetectionService.isGreeting(q), isFalse, reason: 'Failed for: $q');
        final reply = GreetingDetectionService.getOfflineGreetingReply(q);
        expect(reply, isNull, reason: 'Reply should be null for real question: $q');
      }
    });
  });
}
