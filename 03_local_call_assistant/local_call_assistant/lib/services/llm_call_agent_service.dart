import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/call_session.dart';

class LlmCallAgentService {
  String ollamaBaseUrl = 'http://localhost:11434';
  String groqApiKey = '';
  String groqModel = 'llama-3.3-70b-versatile';
  String ollamaModel = 'llama3.2:1b';
  String assistantName = 'Aura';
  String ownerName = 'Arshad';

  static const String systemPromptTemplate = '''
You are {assistantName}, the personal voice call assistant for {ownerName}.
{ownerName} is currently unavailable (driving, in an important meeting, or Do-Not-Disturb is on).
Your job is to courteously answer this phone call on {ownerName}'s behalf.

RULES:
1. Speak naturally like a real human assistant.
2. KEEP RESPONSES VERY SHORT (1 to 2 sentences maximum), since you are speaking on a live voice phone call.
3. Politely ask who is calling, what the call is regarding, and if they'd like to leave an urgent message.
4. If the caller speaks Kannada, respond in Kannada. If they speak Hindi, respond in Hindi. If English, respond in English.
5. NEVER recite long bullet points or markdown. Plain spoken conversational text only.
''';

  String _buildSystemPrompt() {
    return systemPromptTemplate
        .replaceAll('{assistantName}', assistantName)
        .replaceAll('{ownerName}', ownerName);
  }

  Future<String> generateCallReply({
    required List<CallTurn> history,
    required String lastCallerText,
    String language = 'kn_IN',
  }) async {
    // 1. Try Groq if API key is provided
    if (groqApiKey.isNotEmpty) {
      try {
        final reply = await _generateWithGroq(history, lastCallerText);
        if (reply.isNotEmpty) return reply;
      } catch (e) {
        debugPrint('Groq call error: $e');
      }
    }

    // 2. Try Local Ollama
    try {
      final reply = await _generateWithOllama(history, lastCallerText);
      if (reply.isNotEmpty) return reply;
    } catch (e) {
      debugPrint('Ollama call error: $e');
    }

    // 3. Fallback Smart Assistant Engine (Works 100% offline with zero dependencies)
    return _generateOfflineFallback(history, lastCallerText, language);
  }

  Future<String> _generateWithGroq(List<CallTurn> history, String lastCallerText) async {
    final messages = <Map<String, String>>[
      {'role': 'system', 'content': _buildSystemPrompt()},
    ];

    for (final turn in history) {
      messages.add({
        'role': turn.speaker == 'caller' ? 'user' : 'assistant',
        'content': turn.text,
      });
    }

    final response = await http.post(
      Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $groqApiKey',
      },
      body: jsonEncode({
        'model': groqModel,
        'messages': messages,
        'temperature': 0.6,
        'max_tokens': 120,
      }),
    ).timeout(const Duration(seconds: 4));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'].toString().trim();
    }
    return '';
  }

  Future<String> _generateWithOllama(List<CallTurn> history, String lastCallerText) async {
    final messages = <Map<String, String>>[
      {'role': 'system', 'content': _buildSystemPrompt()},
    ];

    for (final turn in history) {
      messages.add({
        'role': turn.speaker == 'caller' ? 'user' : 'assistant',
        'content': turn.text,
      });
    }

    final response = await http.post(
      Uri.parse('$ollamaBaseUrl/api/chat'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'model': ollamaModel,
        'messages': messages,
        'stream': false,
        'options': {'temperature': 0.6, 'num_predict': 100},
      }),
    ).timeout(const Duration(seconds: 4));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['message']['content'].toString().trim();
    }
    return '';
  }

  String _generateOfflineFallback(List<CallTurn> history, String text, String language) {
    final lower = text.toLowerCase();
    final isKannada = language.startsWith('kn') || text.contains(RegExp(r'[\u0C80-\u0CFF]'));
    final isHindi = language.startsWith('hi') || text.contains(RegExp(r'[\u0900-\u097F]'));

    if (isKannada) {
      if (lower.contains('ಹಲೋ') || lower.contains('ನಮಸ್ಕಾರ') || history.length <= 1) {
        return 'ನಮಸ್ಕಾರ, ನಾನು ಅರ್ಷದ್ ಅವರ AI ಅಸಿಸ್ಟೆಂಟ್. ಅರ್ಷದ್ ಅವರು ಸದ್ಯಕ್ಕೆ ಬ್ಯುಸಿ ಇದ್ದಾರೆ. ತಾವು ಯಾರು ಮತ್ತು ಯಾವ ವಿಷಯವಾಗಿ ಕರೆ ಮಾಡಿದ್ದೀರಿ ಎಂದು ತಿಳಿಸಬಹುದೇ?';
      }
      if (lower.contains('ಅರ್ಜೆಂಟ್') || lower.contains('ತುರ್ತು') || lower.contains('emergency')) {
        return 'ಸರಿ, ನಾನು ಇದನ್ನು ಅತೀ ತುರ್ತು ಎಂದು ಗುರುತಿಸಿ ತಕ್ಷಣವೇ ಅರ್ಷದ್ ಅವರಿಗೆ ತಲುಪಿಸುತ್ತೇನೆ.';
      }
      return 'ಖಂಡಿತ, ನಿಮ್ಮ ಸಂದೇಶವನ್ನು ನಾನು ಬರೆದುಕೊಂಡಿದ್ದೇನೆ. ಅರ್ಷದ್ ಅವರಿಗೆ ಕೂಡಲೇ ತಿಳಿಸುತ್ತೇನೆ. ಧನ್ಯವಾದಗಳು.';
    }

    if (isHindi) {
      if (lower.contains('नमस्ते') || lower.contains('हेलो') || history.length <= 1) {
        return 'नमस्ते, मैं अरशद का एआई असिस्टेंट हूँ। अरशद अभी व्यस्त हैं। कृपया बताएं आप कौन बोल रहे हैं और क्या काम है?';
      }
      if (lower.contains('urgent') || lower.contains('जरूरी')) {
        return 'जी ठीक है, मैं इसे बहुत महत्वपूर्ण मार्क करके तुरंत अरशद तक पहुँचा दूँगा।';
      }
      return 'बिल्कुल, मैंने आपका संदेश नोट कर लिया है। अरशद आपको जल्दी ही कॉल बैक करेंगे।';
    }

    // Default English
    if (lower.contains('hello') || lower.contains('hi') || history.length <= 1) {
      return 'Hello! I am Arshad\'s AI assistant. Arshad is currently tied up. May I know who is calling and what this is regarding?';
    }
    if (lower.contains('urgent') || lower.contains('emergency') || lower.contains('important')) {
      return 'Understood. I will flag this as high priority and notify Arshad immediately.';
    }
    return 'Got it. I have noted your message and will pass it along to Arshad right away. Have a wonderful day!';
  }

  Future<Map<String, dynamic>> summarizeCall(CallSession session) async {
    final transcript = session.turns.map((t) => '${t.speaker}: ${t.text}').join('\n');

    final prompt = '''
Summarize the following phone call in JSON format:
{
  "summary": "2-sentence executive summary of the call",
  "urgency": "low | medium | high",
  "actionItems": ["action item 1", "action item 2"]
}

Transcript:
$transcript
''';

    if (groqApiKey.isNotEmpty) {
      try {
        final res = await http.post(
          Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $groqApiKey',
          },
          body: jsonEncode({
            'model': 'llama-3.1-8b-instant',
            'messages': [
              {'role': 'user', 'content': prompt}
            ],
            'response_format': {'type': 'json_object'},
          }),
        ).timeout(const Duration(seconds: 5));

        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          final content = jsonDecode(data['choices'][0]['message']['content']);
          return content;
        }
      } catch (e) {
        debugPrint('Summary LLM error: $e');
      }
    }

    // Fallback Summary
    final isUrgent = transcript.toLowerCase().contains('urgent') || transcript.toLowerCase().contains('emergency') || transcript.toLowerCase().contains('ತುರ್ತು');
    return {
      'summary': 'Call from ${session.callerName} (${session.callerNumber}). Discussed: ${session.turns.isNotEmpty ? session.turns.last.text : "Brief greeting"}',
      'urgency': isUrgent ? 'high' : 'medium',
      'actionItems': ['Review call transcript', 'Follow up with caller if needed'],
    };
  }
}
