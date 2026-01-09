import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/ai_config.dart';

class AIService {
  static Future<String> ask(String question) async {
    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Authorization': 'Bearer ${AIConfig.openAIKey}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "model": "gpt-3.5-turbo",
        "messages": [
          {"role": "user", "content": question}
        ],
        "temperature": 0.7,
      }),
    );

    if (response.statusCode != 200) {
  print("STATUS: ${response.statusCode}");
  print("BODY: ${response.body}");
  return "⚠️ AI is unavailable right now.";
}

    final data = jsonDecode(response.body);
    return data['choices'][0]['message']['content'];
  }
}
