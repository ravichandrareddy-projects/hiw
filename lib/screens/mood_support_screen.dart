import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/mood_service.dart';
import '../widgets/premium_glass_card.dart';
import '../themes/hiw_theme.dart';
import '../hive/chat_hive_model.dart';
import '../avatar/avatar_store.dart';
import '../core/history_store.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Also likely needed for commands

/// Dedicated Mood Support Chatbot - Unlimited, empathetic AI support
class MoodSupportScreen extends StatefulWidget {
  final String? initialMessage; // Auto-send this message on open

  const MoodSupportScreen({
    super.key,
    this.initialMessage,
  });

  @override
  State<MoodSupportScreen> createState() => _MoodSupportScreenState();
}

class _MoodSupportScreenState extends State<MoodSupportScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<String> _messages = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadChatHistory();

    // Auto-send initial message if provided
    if (widget.initialMessage != null && widget.initialMessage!.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 500), () {
        _sendAutoMessage(widget.initialMessage!);
      });
    }
  }

  Future<void> _loadChatHistory() async {
    final box = await Hive.openBox<ChatHive>('mood_chat_history');
    final today = DateTime.now().toIso8601String().split('T')[0];

    // Clear all messages if it's a new day
    final hasOldMessages = box.values.any((chat) => chat.date != today);
    if (hasOldMessages) {
      await box.clear();
    }

    // Load today's messages
    final todayChats = box.values.where((chat) => chat.date == today).toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    setState(() {
      _messages.clear();
      for (final chat in todayChats) {
        if (chat.sender == 'user') {
          _messages.add('You: ${chat.text}');
        } else {
          _messages.add(chat.text);
        }
      }
    });
  }

  Future<void> _saveMessage(String text, String sender) async {
    final box = await Hive.openBox<ChatHive>('mood_chat_history');
    final today = DateTime.now().toIso8601String().split('T')[0];

    final chat = ChatHive(
      text: text,
      sender: sender,
      timestamp: DateTime.now(),
      date: today,
      sessionId: 'mood_chat', // 🆕 Mood chats don't need grouped sessions yet
    );

    await box.add(chat);
  }

  Future<void> _sendAutoMessage(String text) async {
    if (text.isEmpty || _loading || !mounted) return;

    setState(() {
      _messages.add("You: $text");
      _loading = true;
    });

    try {
      await _saveMessage(text, 'user');

      final reply = await MoodService.askMoodCheck(text).timeout(
        const Duration(seconds: 30),
        onTimeout: () =>
            "I'm here for you. There seems to be a connection issue. Please try again.",
      );

      if (mounted) {
        final botMessage = "💙 Support: $reply";

        setState(() {
          _messages.add(botMessage);
          _loading = false;
        });

        await _saveMessage(botMessage, 'bot');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(
              "💙 Support: I'm here for you. There was a technical issue, but I'm ready to listen.");
          _loading = false;
        });
      }
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _loading) return;

    // 🛠️ DEV COMMANDS (SAFE & WORKING)
    if (text.startsWith('/')) {
      final avatarStore = AvatarStore();
      String? devReply;

      if (text == '/clean') {
        final box = await Hive.openBox<ChatHive>('mood_chat_history');
        await box.clear();
        devReply = "💙 Support: Clean sweep. History cleared.";
      } else if (text == '/streak') {
        final store = HistoryStore();
        await store.clearHistory();
        store.seedStreak(10);
        devReply = "💙 Support: 🪄 Streak Hack Activated! (10 Days Seeded)";
      } else if (text == '/max' || text == '/mid' || text == '/min') {
        if (text == '/max') {
          avatarStore.hackStats(h: 100, e: 100, s: 100);
          devReply = "💙 Support: 🚀 Stats Maxed!";
        } else if (text == '/mid') {
          avatarStore.hackStats(h: 50, e: 50, s: 50);
          devReply = "💙 Support: ⚖️ Stats Balanced!";
        } else if (text == '/min') {
          avatarStore.hackStats(h: 0, e: 0, s: 0);
          devReply = "💙 Support: 💀 Stats Minimized!";
        }
      } else {
        // 🆕 ABSOLUTE STAT COMMANDS (e.g., /50H)
        final regExp = RegExp(r'^\/(\d+)([HES])$', caseSensitive: false);
        final match = regExp.firstMatch(text);
        if (match != null) {
          final value = double.tryParse(match.group(1)!) ?? 0;
          final stat = match.group(2)!.toUpperCase();
          avatarStore.setStat(stat, value);
          String statName =
              stat == 'H' ? 'Health' : (stat == 'E' ? 'Energy' : 'Stamina');
          devReply = "💙 Support: 🛠️ $statName set to $value%!";
        }
      }

      if (devReply != null) {
        setState(() {
          _messages.add(devReply!);
        });
        _controller.clear();
        return;
      }
    }

    setState(() {
      _messages.add("You: $text");
      _loading = true;
      _controller.clear();
    });

    try {
      await _saveMessage(text, 'user');

      final reply = await MoodService.askMoodCheck(text).timeout(
        const Duration(seconds: 30),
        onTimeout: () =>
            "I'm here for you. There seems to be a connection issue. Please try again.",
      );

      if (mounted) {
        final botMessage = "💙 Support: $reply";

        setState(() {
          _messages.add(botMessage);
          _loading = false;
        });

        await _saveMessage(botMessage, 'bot');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(
              "💙 Support: I'm here for you. There was a technical issue, but I'm ready to listen.");
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = HiwTheme.of(context);
    final accent = Theme.of(context).primaryColor;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: t.isMinimal
            ? null
            : const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF0F172A), // Deep navy
                    Color(0xFF020617), // Near black
                  ],
                ),
              ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom Header
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back_ios_new,
                          color: t.inkColor, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Text(
                      '💙 Mood Support',
                      style: TextStyle(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.bold,
                        color: accent,
                      ),
                    ),
                  ],
                ),
              ),

              Divider(
                  color: t.isMinimal ? t.cardStroke : Colors.white10),
              // Messages
              Expanded(
                child: _messages.isEmpty
                    ? Center(
                        child: Text(
                          "I'm here to support you. 💙\nHow are you feeling?",
                          textAlign: TextAlign.center,
                          style:
                              TextStyle(color: t.mutedColor, fontSize: 16.sp),
                        ),
                      )
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

              // Loader
              if (_loading)
                Padding(
                  padding: EdgeInsets.all(8.r),
                  child: CircularProgressIndicator(
                      color: accent),
                ),

              // Input
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
                            hintText: 'Share your feelings...',
                            hintStyle: TextStyle(color: t.mutedColor),
                            border: InputBorder.none,
                            contentPadding:
                                EdgeInsets.symmetric(vertical: 12.h),
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
            ],
          ),
        ),
      ),
    );
  }
}
