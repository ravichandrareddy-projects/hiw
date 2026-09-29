import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart'; // 🆕 Hive for chat persistence
import '../services/gemini_service.dart';

import '../services/greeting_detection_service.dart'; // 🆕 AI greeting detection
import '../widgets/premium_glass_card.dart';
import '../core/history_store.dart';
import '../core/food_item.dart';
import '../core/subscription/entitlement.dart';
import '../core/subscription/plan.dart';
import '../core/subscription/usage_store.dart';
import '../services/analytics_service.dart';
import '../widgets/limit_sheet.dart';
import '../avatar/avatar_store.dart';
import '../config/ai_config.dart';
import '../hive/chat_hive_model.dart'; // 🆕 Chat model
import 'mood_support_screen.dart'; // 🆕 Mood support chatbot
import '../themes/hiw_theme.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _controller = TextEditingController();
  final List<String> _messages = [];
  bool _loading = false;
  // Unified quota: single source is UsageStore daily chat (Free 5/day,
  // Pro fair use). Legacy per-session qs_left_* counters removed (P2 ending).
  int _chatLeft = PlanConfig.freeChatPerDay;
  bool _isPro = false;
  String? _currentSessionId; // 🆕 Tracks the active chat session

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initChatSystem();
  }

  Future<void> _initChatSystem() async {
    await _loadDailyLimit();
    await _loadChatHistory();
    await _refreshQuota();
  }

  // 🆕 Load chat history from Hive
  Future<void> _loadChatHistory({String? sessionIdToLoad}) async {
    final box = await Hive.openBox<ChatHive>('chat_history');
    final today = DateTime.now().toIso8601String().split('T')[0];

    // Clear old messages from previous days
    final oldKeys = box.keys.where((key) {
      final chat = box.get(key);
      return chat != null && chat.date != today;
    }).toList();

    for (final key in oldKeys) {
      await box.delete(key);
    }

    // Load today's messages for the given session (or default to none if new)
    List<ChatHive> todayChats = box.values
        .where((chat) => chat.date == today)
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    if (sessionIdToLoad != null) {
      _currentSessionId = sessionIdToLoad;
      todayChats =
          todayChats.where((c) => c.sessionId == sessionIdToLoad).toList();
    } else {
      // Find the most recent session if none specified
      if (todayChats.isNotEmpty) {
        _currentSessionId = todayChats.last.sessionId;
        todayChats =
            todayChats.where((c) => c.sessionId == _currentSessionId).toList();
      } else {
        _currentSessionId = null; // Fresh start
      }
    }

    setState(() {
      _messages.clear();
      for (final chat in todayChats) {
        if (chat.sender == 'user') {
          _messages.add('You: ${chat.text}');
        } else {
          _messages
              .add(chat.text); // Already has "Foodity:" or "💙 Support:" prefix
        }
      }
    });
  }

  // 🆕 Create new chat session (unlimited sessions; quota is per-message/day)
  void _startNewChat() async {
    final newSessionId = DateTime.now().millisecondsSinceEpoch.toString();
    setState(() {
      _currentSessionId = newSessionId;
      _messages.clear();
    });
    if (mounted && Scaffold.of(context).isDrawerOpen) {
      Navigator.pop(context);
    }
  }

  // 🆕 Save message to Hive
  Future<void> _saveMessage(String text, String sender) async {
    final box = await Hive.openBox<ChatHive>('chat_history');
    final today = DateTime.now().toIso8601String().split('T')[0];

    // Assign a new session ID if this is the first message of a new chat
    _currentSessionId ??= DateTime.now().millisecondsSinceEpoch.toString();

    final chat = ChatHive(
      text: text,
      sender: sender,
      timestamp: DateTime.now(),
      date: today,
      sessionId: _currentSessionId!,
    );

    await box.add(chat);
  }

  Future<void> _loadDailyLimit() async {
    // Midnight reset: Hive holds only today's chats (UsageStore day-key
    // resets the quota automatically — no counters here).
    final prefs = await SharedPreferences.getInstance();
    final lastDate = prefs.getString('last_chat_date') ?? '';
    final today = DateTime.now().toIso8601String().split('T')[0];
    if (lastDate != today) {
      await prefs.setString('last_chat_date', today);
      _messages.clear();
      try {
        final box = await Hive.openBox<ChatHive>('chat_history');
        await box.clear();
      } catch (_) {}
      _currentSessionId = DateTime.now().millisecondsSinceEpoch.toString();
    }
  }

  Future<void> _refreshQuota() async {
    final pro = (await EntitlementStore.current()).isPro;
    if (mounted) {
      setState(() {
        _isPro = pro;
        _chatLeft = UsageStore.chatLeft();
      });
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _loading) return;

    // 🛠️ DEV COMMANDS (SAFE & WORKING & BYPASS LIMITS)
    if (text.startsWith('/')) {
      final avatarStore = AvatarStore();
      String? devReply;

      if (text == '/streak') {
        setState(() => _loading = true);
        final store = HistoryStore();
        await store.clearHistory();
        store.seedStreak(10);
        setState(() {
          _loading = false;
          devReply =
              "Foodity: 🪄 Streak Hack Activated! 100% Hacker mode. Check your History screen! 🔥";
        });
      } else if (text == '/max' || text == '/mid' || text == '/min') {
        if (text == '/max') {
          avatarStore.hackStats(h: 100, e: 100, s: 100);
          devReply =
              "Foodity: 🚀 STATS MAXED! Avatar is at 100% peak performance! 💪";
        } else if (text == '/mid') {
          avatarStore.hackStats(h: 50, e: 50, s: 50);
          devReply =
              "Foodity: ⚖️ STATS BALANCED! Avatar is at 50% across the board.";
        } else if (text == '/min') {
          avatarStore.hackStats(h: 0, e: 0, s: 0);
          devReply =
              "Foodity: 💀 STATS MINIMIZED! Avatar is at 0%. Emergency! 🚨";
        }
      } else if (text == '/reset' || text == '/reste') {
        setState(() {
          _messages.clear();
          devReply =
              "Foodity: 🔄 System Reset. Memory cleared. Energy restored.";
        });
      } else if (text.startsWith('/remove_chat ')) {
        final chatNameToRemove =
            text.substring('/remove_chat '.length).trim().toLowerCase();

        final box = await Hive.openBox<ChatHive>('chat_history');

        // Find all sessions
        final Map<String, List<ChatHive>> sessions = {};
        for (final chat in box.values) {
          sessions.putIfAbsent(chat.sessionId, () => []).add(chat);
        }

        String? targetSessionId;
        for (final entry in sessions.entries) {
          final firstUserMsg = entry.value
              .firstWhere((c) => c.sender == 'user',
                  orElse: () => entry.value.first)
              .text;

          final titleStr = firstUserMsg.length > 25
              ? '${firstUserMsg.substring(0, 25)}...'
              : firstUserMsg;

          if (titleStr.toLowerCase() == chatNameToRemove ||
              firstUserMsg.toLowerCase() == chatNameToRemove) {
            targetSessionId = entry.key;
            break;
          }
        }

        if (targetSessionId != null) {
          final keysToDelete = box.keys.where((key) {
            final chat = box.get(key);
            return chat != null && chat.sessionId == targetSessionId;
          }).toList();

          for (final key in keysToDelete) {
            await box.delete(key);
          }

          if (_currentSessionId == targetSessionId) {
            setState(() {
              _messages.clear();
            });
            _startNewChat();
          }
          devReply = "Foodity: 🗑️ Chat removed successfully.";
        } else {
          devReply =
              "Foodity: ❌ Could not find chat matching '$chatNameToRemove'. Please try the exact name from the sidebar.";
        }
      } else if (text == '/clean') {
        final box = await Hive.openBox<ChatHive>('chat_history');
        await box.clear();
        setState(() {
          _messages.clear();
          devReply = "Foodity: 🧹 Database Cleaned. Total wipeout complete.";
        });
      } else {
        // 🆕 ABSOLUTE STAT COMMANDS (e.g., /50H, /10E, /5S)
        final regExp = RegExp(r'^\/(\d+)([HES])$', caseSensitive: false);
        final match = regExp.firstMatch(text);

        if (match != null) {
          final value = double.tryParse(match.group(1)!) ?? 0;
          final stat = match.group(2)!.toUpperCase();
          avatarStore.setStat(stat, value);

          String statName =
              stat == 'H' ? 'Health' : (stat == 'E' ? 'Energy' : 'Stamina');
          devReply = "Foodity: 🛠️ $statName set to $value%!";
        }
      }

      if (devReply != null) {
        setState(() => _messages.add(devReply!));
        _controller.clear();
        return;
      }
    }

    // Unified daily quota is the ONLY gate (legacy session counters removed).
    setState(() {
      _messages.add("You: $text");
      _loading = true;
      _controller.clear();
    });

    // 🆕 Save user message to Hive
    await _saveMessage(text, 'user');

    // 🆕 Auto-trigger Mood Support if user mentions feeling bad
    final lowerText = text.toLowerCase();
    if (lowerText.contains("feeling bad") ||
        lowerText.contains("stressed") ||
        lowerText.contains("not good") ||
        lowerText.contains("im bad") ||
        lowerText.contains("unhappy")) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MoodSupportScreen(
            initialMessage: text, // Pass their current text
          ),
        ),
      );
      _loading = false;
      return;
    }

    // ⚡ 1. ZERO-CREDIT OFFLINE GREETING CHECK
    final offlineGreeting =
        GreetingDetectionService.getOfflineGreetingReply(text);

    if (offlineGreeting != null) {
      if (mounted) {
        final botMessage = "Foodity: $offlineGreeting";
        setState(() {
          _messages.add(botMessage);
          _loading = false;
        });
        await _saveMessage(botMessage, 'bot');
        // Greetings do NOT decrease the daily question limit & do NOT burn API tokens!
      }
      return;
    }

    // 🤖 2. Real Question -> daily quota (Free 5/day, Pro fair use)
    final isPro = (await EntitlementStore.current()).isPro;
    if (!isPro && UsageStore.chatLeft() <= 0) {
      if (mounted) {
        setState(() => _loading = false);
        AnalyticsService().log('chat_quota_hit');
        await showLimitSheet(
          context,
          title: 'Daily answers used up',
          usedLabel:
              '${PlanConfig.freeChatPerDay}/${PlanConfig.freeChatPerDay} answers today',
          resetLabel: 'tomorrow',
          freeAlternativeLabel: 'Keep chatting with greetings (free)',
        );
        if (mounted) await _refreshQuota();
      }
      return;
    }
    final idem =
        'chat_${_currentSessionId ?? 'new'}_${text.hashCode}';
    final String reply = await GeminiService.ask(text);
    UsageStore.consumeChat(idem: idem);
    AnalyticsService().log('chat_sent');

    if (mounted) {
      final botMessage = "Foodity: $reply";

      setState(() {
        _messages.add(botMessage);
        _loading = false;
      });

      await _saveMessage(botMessage, 'bot');
      await _refreshQuota();
    }
  }

  // 🆕 Drawer UI Logic
  Widget _buildSidebarDrawer() {
    final t = HiwTheme.of(context);
    final accent = Theme.of(context).primaryColor;
    return Drawer(
      backgroundColor: t.isMinimal
          ? Colors.white
          : Colors.black.withValues(alpha: 0.9), // Dark glass feel
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(16.r),
              child: ElevatedButton.icon(
                onPressed: _startNewChat,
                icon: Icon(Icons.add, color: accent),
                label: Text("New Chat",
                    style: TextStyle(
                        color: t.inkColor, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent.withValues(alpha: 0.15),
                  minimumSize: Size(double.infinity, 50.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    side: BorderSide(
                        color: accent.withValues(alpha: 0.5)),
                  ),
                ),
              ),
            ),
            Divider(color: t.isMinimal ? t.cardStroke : Colors.white24),
            Expanded(
              child: FutureBuilder<Box<ChatHive>>(
                future: Hive.openBox<ChatHive>('chat_history'),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(
                        child: CircularProgressIndicator(
                            color: accent));
                  }

                  final box = snapshot.data!;
                  final today = DateTime.now().toIso8601String().split('T')[0];

                  // Group by sessionId
                  final Map<String, List<ChatHive>> sessions = {};
                  for (final chat in box.values.where((c) => c.date == today)) {
                    sessions.putIfAbsent(chat.sessionId, () => []).add(chat);
                  }

                  if (sessions.isEmpty) {
                    return Center(
                        child: Text("No previous chats today.",
                            style: TextStyle(color: t.mutedColor)));
                  }

                  // Sort sessions by the timestamp of their first message (newest first)
                  final sortedSessionIds = sessions.keys.toList()
                    ..sort((a, b) {
                      final timeA = sessions[a]!.first.timestamp;
                      final timeB = sessions[b]!.first.timestamp;
                      return timeB.compareTo(timeA); // Descending
                    });

                  return ListView.builder(
                    itemCount: sortedSessionIds.length,
                    itemBuilder: (context, index) {
                      final sessionId = sortedSessionIds[index];
                      final sessionChats = sessions[sessionId]!;

                      // Get the first user message as the title, or a default
                      final firstUserMsg = sessionChats
                          .firstWhere((c) => c.sender == 'user',
                              orElse: () => sessionChats.first)
                          .text;

                      final title = firstUserMsg.length > 25
                          ? '${firstUserMsg.substring(0, 25)}...'
                          : firstUserMsg;

                      final isSelected = _currentSessionId == sessionId;

                      return ListTile(
                        leading: Icon(Icons.chat_bubble_outline,
                            color: isSelected
                                ? accent
                                : t.mutedColor),
                        title: Text(
                          title,
                          style: TextStyle(
                            color:
                                isSelected ? accent : t.inkColor,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () {
                          Navigator.pop(context); // Close drawer
                          if (!isSelected) {
                            _loadChatHistory(sessionIdToLoad: sessionId);
                          }
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final t = HiwTheme.of(context);
    final accent = Theme.of(context).primaryColor;

    // 🆕 Scaffold wrap needed to support the Drawer
    return Scaffold(
      backgroundColor: Colors.transparent, // Inherit outer gradient if any
      drawer: _buildSidebarDrawer(),
      body: Column(
        children: [
          // 🔹 Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Column(
              // Changed to Column to hold the new header Row and Divider
              children: [
                // Header with Logo
                Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: 0,
                      vertical: 8
                          .h), // Adjusted padding to fit the original outer padding
                  child: Row(
                    children: [
                      // 🆕 Menu button to open sidebar
                      Builder(
                        builder: (ctx) => IconButton(
                          icon: Icon(Icons.menu,
                              color: t.inkColor, size: 28),
                          onPressed: () => Scaffold.of(ctx).openDrawer(),
                        ),
                      ),
                      SizedBox(width: 4.w),
                      // 🆕 Foodity AI Logo
                      Container(
                        padding: EdgeInsets.all(8.r),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                              color: accent.withValues(alpha: 0.2)),
                        ),
                        child: Icon(
                          Icons
                              .restaurant_menu, // Restaurant menu icon for Foodity
                          color: accent,
                          size: 24,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Foodity AI',
                            style: TextStyle(
                              fontSize: 20.sp,
                              fontWeight: FontWeight.bold,
                              color: t.inkColor,
                              letterSpacing: 1.2,
                            ),
                          ),
                          Text(
                            'Health Expert',
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: accent.withValues(alpha: 0.8),
                              fontWeight: FontWeight.w500,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      // Question counter (unified daily quota; Pro = fair use)
                      PremiumGlassCard(
                        padding: EdgeInsets.symmetric(
                            horizontal: 10.w, vertical: 6.h),
                        borderRadius: 12,
                        isInnerPill: true,
                        child: Row(
                          children: [
                            Icon(Icons.bolt,
                                color: accent, size: 14),
                            SizedBox(width: 4.w),
                            Text(
                              _isPro
                                  ? 'Pro • unlimited'
                                  : '$_chatLeft/${PlanConfig.freeChatPerDay} answers',
                              style: TextStyle(
                                color: accent,
                                fontWeight: FontWeight.bold,
                                fontSize: 10.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                Divider(
                    color: t.isMinimal ? t.cardStroke : Colors.white10),
              ],
            ),
          ),

          // 🔹 Messages
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Text(
                        "Greetings! I am Foodity. How can I assist you today?",
                        style: TextStyle(color: t.mutedColor)))
                : ListView.builder(
                    padding: EdgeInsets.all(16.r),
                    itemCount: _messages.length,
                    itemBuilder: (context, i) {
                      final msg = _messages[i];
                      final isUser = msg.startsWith("You:");
                      return Padding(
                        padding: EdgeInsets.only(
                            bottom: 12.h), // 🆕 Spacing between bubbles
                        child: Align(
                          alignment: isUser
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth:
                                  MediaQuery.of(context).size.width * 0.75,
                            ),
                            child: PremiumGlassCard(
                              padding: EdgeInsets.all(12.r),
                              borderRadius: 16,
                              isInnerPill: isUser,
                              child: Text(
                                msg,
                                style: TextStyle(
                                  color: t.inkColor,
                                  fontWeight: isUser
                                      ? FontWeight.w500
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // 🔹 Loader
          if (_loading)
            Padding(
              padding: EdgeInsets.all(8.r),
              child: CircularProgressIndicator(color: accent),
            ),

          // 🔹 Input
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: PremiumGlassCard(
                    borderRadius: 25,
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    isInnerPill: true,
                    child: TextField(
                      controller: _controller,
                      style: TextStyle(color: t.inkColor),
                      decoration: InputDecoration(
                        hintText: 'Message Foodity...',
                        hintStyle: TextStyle(color: t.mutedColor),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 12.h),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                PremiumGlassCard(
                  borderRadius: 50,
                  width: 50.w,
                  height: 50.h,
                  padding: EdgeInsets.zero,
                  child: IconButton(
                    onPressed: _send,
                    icon: Icon(Icons.send_rounded,
                        color: accent),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 70.h),
        ],
      ),
    );
  }
}
