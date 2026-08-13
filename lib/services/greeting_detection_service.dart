import 'dart:math';

/// Service to detect greetings offline (Zero-Token Cost) and return predefined natural responses.
class GreetingDetectionService {
  static final Random _random = Random();

  /// Pool of predefined natural greeting responses (0 API tokens burned!)
  static const List<String> _greetingResponses = [
    "Hello there! 👋 I'm Foodity, your personal food & health assistant. How can I help you with your nutrition and diet goals today?",
    "Hey! 🥗 Great to see you! What food or health topic would you like to explore today?",
    "Hi! Hope you're having a wonderful day! 🍎 Ask me anything about healthy meals, recipes, or nutrition advice.",
    "Hello! 🥑 Ready to nourish your body? Let me know what food or diet questions I can answer for you!",
    "Hey there! I'm feeling great and ready to help! 🥕 How can I guide your food and fitness journey today?",
    "Greetings! 🍉 I'm Foodity. What healthy eating habits or food facts are you curious about today?",
  ];

  /// Pool of predefined thank-you responses
  static const List<String> _thankYouResponses = [
    "You're very welcome! 😊 Stay healthy and feel free to ask me more food questions anytime!",
    "Happy to help! 🥗 Keep up the great work with your nutrition!",
    "Anytime! 🍎 I'm always here to support your healthy lifestyle.",
  ];

  /// Pool of predefined farewell responses
  static const List<String> _farewellResponses = [
    "Goodbye! 👋 Have a fantastic and healthy day ahead!",
    "See you later! 🥦 Remember to stay hydrated and eat well!",
    "Take care! 🥑 I'll be right here whenever you need food or health tips.",
  ];

  /// Checks if a message is a greeting offline (returns true if greeting/pleasantry, false if real question)
  static bool isGreeting(String userMessage) {
    final lower = userMessage.toLowerCase().trim();
    if (lower.isEmpty) return false;

    // Clean punctuation for matching
    final clean = lower.replaceAll(RegExp(r'[^\w\s]'), '');

    // List of exact greeting phrases
    const exactGreetings = [
      'hi', 'hello', 'hey', 'hlo', 'hii', 'hiii', 'heyy', 'yo', 'hola',
      'good morning', 'good afternoon', 'good evening', 'good night',
      'how are you', 'how are u', 'how do you do', "what's up", 'whats up', 'sup',
      'greetings', 'howdy', 'namaste', 'thanks', 'thank you', 'thx',
      'bye', 'goodbye', 'see you', 'see ya', 'later', 'cheers'
    ];

    // Check exact match or starts/ends with simple greeting
    for (final g in exactGreetings) {
      if (clean == g) return true;
    }

    // If message contains greeting word AND is very short (<= 4 words) without question keywords
    final words = clean.split(RegExp(r'\s+'));
    if (words.length <= 4) {
      const questionKeywords = ['what', 'why', 'how', 'can', 'is', 'are', 'should', 'which', 'where', 'tell', 'suggest', 'recommend', 'calorie', 'protein', 'diet', 'food', 'weight'];
      final hasQuestionWord = words.any((w) => questionKeywords.contains(w));
      
      // If no question keyword, check if any word is a greeting
      if (!hasQuestionWord) {
        for (final g in exactGreetings) {
          if (clean.contains(g)) return true;
        }
      }
    }

    return false;
  }

  /// Returns an offline natural response if the message is a greeting, or null if it's a real question.
  static String? getOfflineGreetingReply(String userMessage) {
    if (!isGreeting(userMessage)) return null;

    final lower = userMessage.toLowerCase().trim();

    // Check for thank-you
    if (lower.contains('thank') || lower.contains('thx') || lower == 'thanks') {
      return _thankYouResponses[_random.nextInt(_thankYouResponses.length)];
    }

    // Check for farewell
    if (lower.contains('bye') || lower.contains('see you') || lower.contains('later')) {
      return _farewellResponses[_random.nextInt(_farewellResponses.length)];
    }

    // Default greeting responses (randomly pick from at least 6 variants)
    return _greetingResponses[_random.nextInt(_greetingResponses.length)];
  }
}
