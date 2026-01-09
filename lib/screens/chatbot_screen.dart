import 'package:flutter/material.dart';
import '../services/ai_service.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _controller = TextEditingController();
  final List<String> _messages = [];

  int _questionsLeft = 3;
  bool _loading = false;

  @override
  bool get wantKeepAlive => true; // 🔒 keep state across tab switches

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _loading) return;

    if (_questionsLeft <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No questions left today')),
      );
      return;
    }

    setState(() {
      _messages.add("You: $text");
      _questionsLeft--;
      _loading = true;
      _controller.clear();
    });

    final reply = await AIService.ask(text);

    setState(() {
      _messages.add("IGRIS: $reply");
      _messages.add(
        "⚠️ Demo note: Final HIW chatbot will respond "
        "based on your food & health data (under construction).",
      );
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // REQUIRED for keep-alive

    return Column(
      children: [
        // 🔹 Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              const Text(
                'IGRIS Chatbot',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Chip(label: Text('Q left: $_questionsLeft')),
            ],
          ),
        ),

        // 🔹 Messages
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _messages.length,
            itemBuilder: (context, i) {
              final msg = _messages[i];
              final isUser = msg.startsWith("You:");
              return Align(
                alignment:
                    isUser ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isUser
                        ? Colors.tealAccent.withOpacity(0.22)
                        : Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(msg),
                ),
              );
            },
          ),
        ),

        // 🔹 Loader
        if (_loading)
          const Padding(
            padding: EdgeInsets.all(8),
            child: CircularProgressIndicator(),
          ),

        // 🔹 Input
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText:
                        'Ask IGRIS — demo chatbot "UNDER CONSTRUCTION"',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _send,
                icon: const Icon(Icons.send),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
