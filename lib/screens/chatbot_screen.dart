import 'package:flutter/material.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});
  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<String> _messages = [];
  int _questionsLeft = 3;

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    if (_questionsLeft <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No questions left today')));
      return;
    }
    setState(() {
      _messages.add('You: $text');
      _messages.add('IGRIS: (demo) I will answer based on your HIW data later.');
      _controller.clear();
      _questionsLeft--;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              const Text('IGRIS Chatbot', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const Spacer(),
              Chip(label: Text('Q left: $_questionsLeft'))
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: _messages.length,
            itemBuilder: (context, idx) {
              final msg = _messages[idx];
              final isUser = msg.startsWith('You:');
              return Align(
                alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isUser ? Colors.tealAccent.withOpacity(0.22) : Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(msg),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: 'Ask IGRIS (3 per day)...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.02),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(onPressed: _send, icon: const Icon(Icons.send)),
            ],
          ),
        )
      ],
    );
  }
}
