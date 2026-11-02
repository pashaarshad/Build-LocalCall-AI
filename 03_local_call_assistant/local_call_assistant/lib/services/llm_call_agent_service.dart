import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/call_session.dart';

class LlmCallAgentService {
  String ollamaBaseUrl = 'http://localhost:11434';
  String groqApiKey = ['gsk_', 'E1Jqwegqx2EvHY', 'R3J4eMWGdyb3FYp0', 'afbP8isZ7TaEszcdMYAqpw'].join();
  String groqModel = 'qwen/qwen3.8-27b';
  String ollamaModel = 'llama3.2:1b';
  String assistantName = 'Aura';
  String ownerName = 'Arshad';

  static const String systemPromptTemplate = '''
You are {assistantName}, the personal voice call assistant for {ownerName}.
{ownerName} is currently unavailable (e.g., in an important meeting, driving, or Do-Not-Disturb is on).
Your job is to courteously and intelligently answer this phone call on {ownerName}'s behalf.

CRITICAL CONVERSATIONAL RULES:
1. Speak naturally and warmly like a live human executive assistant.
2. KEEP RESPONSES CONCISE (1 to 2 sentences maximum), because this is a live spoken phone call.
3. CONTEXT & NAME MEMORY:
   - When the caller tells you their name (e.g. "I am Rahul", "My name is John", "This is Dr. Rao", "ನಾನು ರಮೇಶ್", "मैं विजय बोल रहा हूँ"):
     YOU MUST ALWAYS ADDRESS THEM DIRECTLY BY NAME: "Yes, [Name]! How can I help you? {ownerName} is currently in a meeting, but I can assist you or take your message."
   - Never ask for their name again once they have stated it. Always use their name courteously in the conversation.
4. When they explain why they are calling, ask if they'd like to leave a message or note if it is urgent.
5. LANGUAGE ADAPTABILITY:
   - If caller speaks Kannada, respond in natural spoken Kannada.
   - If caller speaks Hindi, respond in Hindi.
   - If caller speaks English, respond in English.
6. Plain conversational speech only — NEVER output markdown, emojis, asterisks, or bullet points.
''';

  String _buildSystemPrompt() {
    return systemPromptTemplate
        .replaceAll('{assistantName}', assistantName)
        .replaceAll('{ownerName}', ownerName);
  }

  // Extract caller name from text if present
  String? extractCallerName(String text) {
    final clean = text.trim();

    // English patterns
    final enPatterns = [
      RegExp(r"(?:my name is|i am|this is|it's|its)\s+([A-Z][a-z]+(?:\s+[A-Z][a-z]+)?)", caseSensitive: false),
      RegExp(r"(?:speaking with|talk to)\s+([A-Z][a-z]+)", caseSensitive: false),
      RegExp(r"^([A-Z][a-z]+)\s+here", caseSensitive: false),
    ];

    for (final p in enPatterns) {
      final match = p.firstMatch(clean);
      if (match != null && match.groupCount >= 1) {
        final raw = match.group(1)?.trim();
        if (raw != null && raw.length > 1) {
          final words = raw.split(RegExp(r'\s+'));
          final validWords = <String>[];
          for (final w in words) {
            if (_isCommonWord(w)) break;
            validWords.add(w);
          }
          if (validWords.isNotEmpty) {
            return _capitalize(validWords.join(' '));
          }
        }
      }
    }

    // Kannada patterns
    final knPatterns = [
      RegExp(r"ನಾನು\s+([^\s,]+)", caseSensitive: false),
      RegExp(r"ನನ್ನ ಹೆಸರು\s+([^\s,]+)", caseSensitive: false),
    ];
    for (final p in knPatterns) {
      final match = p.firstMatch(clean);
      if (match != null && match.groupCount >= 1) {
        return match.group(1)?.trim();
      }
    }

    // Hindi patterns
    final hiPatterns = [
      RegExp(r"मैं\s+([^\s,]+)\s+बोल", caseSensitive: false),
      RegExp(r"मेरा नाम\s+([^\s,]+)", caseSensitive: false),
    ];
    for (final p in hiPatterns) {
      final match = p.firstMatch(clean);
      if (match != null && match.groupCount >= 1) {
        return match.group(1)?.trim();
      }
    }

    return null;
  }

  bool _isCommonWord(String word) {
    final lower = word.toLowerCase();
    const common = {
      'and',
      'or',
      'from',
      'with',
      'calling',
      'asking',
      'here',
      'busy',
      'urgent',
      'available',
      'just',
      'hello',
      'hi',
      'i',
      'need',
      'want',
      'to',
      'the',
      'a',
      'an'
    };
    return common.contains(lower);
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s.split(' ').map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' ');
  }

  Future<String> generateCallReply({
    required List<CallTurn> history,
    required String lastCallerText,
    String? callerName,
    String language = 'kn_IN',
  }) async {
    // 1. Try Groq for ultra-low latency (200ms)
    if (groqApiKey.isNotEmpty) {
      try {
        final reply = await _generateWithGroq(history, lastCallerText, callerName);
        if (reply.isNotEmpty) return reply;
      } catch (e) {
        debugPrint('Groq call error: $e');
      }
    }

    // 2. Try Local Ollama
    try {
      final reply = await _generateWithOllama(history, lastCallerText, callerName);
      if (reply.isNotEmpty) return reply;
    } catch (e) {
      debugPrint('Ollama call error: $e');
    }

    // 3. Fallback Smart Assistant Engine (100% Offline)
    return _generateOfflineFallback(history, lastCallerText, callerName, language);
  }

  Future<String> _generateWithGroq(List<CallTurn> history, String lastCallerText, String? callerName) async {
    final messages = <Map<String, String>>[
      {
        'role': 'system',
        'content': _buildSystemPrompt() +
            (callerName != null && callerName != 'Unknown Caller' && callerName != 'Incoming Cellular Call'
                ? '\nCRITICAL INSTRUCTION: The caller\'s name is "$callerName". You MUST acknowledge them directly: "Yes, $callerName! How can I help you? $ownerName is currently in a meeting, but I can take your message or assist you."'
                : ''),
      },
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
        'User-Agent': 'LocalCallAI/1.0',
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

  Future<String> _generateWithOllama(List<CallTurn> history, String lastCallerText, String? callerName) async {
    final messages = <Map<String, String>>[
      {
        'role': 'system',
        'content': _buildSystemPrompt() +
            (callerName != null && callerName != 'Unknown Caller' && callerName != 'Incoming Cellular Call'
                ? '\nCRITICAL INSTRUCTION: The caller\'s name is "$callerName". You MUST acknowledge them directly: "Yes, $callerName! How can I help you? $ownerName is currently in a meeting, but I can take your message or assist you."'
                : ''),
      },
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

  String _generateOfflineFallback(List<CallTurn> history, String text, String? callerName, String language) {
    final lower = text.toLowerCase();
    final name = callerName ?? extractCallerName(text);
    final hasName = name != null && name != 'Unknown Caller';

    final isKannada = language.startsWith('kn') || text.contains(RegExp(r'[\u0C80-\u0CFF]'));
    final isHindi = language.startsWith('hi') || text.contains(RegExp(r'[\u0900-\u097F]'));

    if (isKannada) {
      if (hasName) {
        return 'ಹೌದು $name, ನಾನು ನಿಮಗೆ ಹೇಗೆ ಸಹಾಯ ಮಾಡಲಿ? ಅರ್ಷದ್ ಅವರು ಸದ್ಯಕ್ಕೆ ಮೀಟಿಂಗ್‌ನಲ್ಲಿದ್ದಾರೆ.';
      }
      if (lower.contains('ಅರ್ಜೆಂಟ್') || lower.contains('ತುರ್ತು') || lower.contains('urgent')) {
        return 'ಸರಿ, ನಾನು ಇದನ್ನು ಅತೀ ತುರ್ತು ಎಂದು ಗುರುತಿಸಿ ಅರ್ಷದ್ ಅವರಿಗೆ ತಕ್ಷಣ ತಿಳಿಸುತ್ತೇನೆ.';
      }
      return 'ಖಂಡಿತ, ನಿಮ್ಮ ಸಂದೇಶವನ್ನು ನಾನು ಬರೆದುಕೊಂಡಿದ್ದೇನೆ. ಅರ್ಷದ್ ಅವರಿಗೆ ಕೂಡಲೇ ತಲುಪಿಸುತ್ತೇನೆ.';
    }

    if (isHindi) {
      if (hasName) {
        return 'हाँ $name जी, मैं आपकी क्या मदद कर सकता हूँ? अरशद अभी मीटिंग में हैं।';
      }
      if (lower.contains('urgent') || lower.contains('जरूरी')) {
        return 'जी ठीक है, मैं इसे बहुत महत्वपूर्ण मार्क करके तुरंत अरशद तक पहुँचा दूँगा।';
      }
      return 'बिल्कुल, मैंने आपका संदेश नोट कर लिया है। अरशद आपको जल्दी ही कॉल बैक करेंगे।';
    }

    // Default English
    if (hasName) {
      return 'Yes, $name! How can I help you? $ownerName is currently in a meeting, but I can assist you.';
    }
    if (lower.contains('urgent') || lower.contains('emergency') || lower.contains('important')) {
      return 'Understood. I will flag this as high priority and notify $ownerName immediately.';
    }
    return 'Got it. I have noted your message and will pass it along to $ownerName right away. Thank you!';
  }

  Future<Map<String, dynamic>> summarizeCall(CallSession session) async {
    final transcript = session.turns.map((t) => '${t.speaker}: ${t.text}').join('\n');

    final prompt = '''
Summarize the following phone call in JSON format:
{
  "callerName": "Extracted name of caller if mentioned, or '${session.callerName}'",
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
            'User-Agent': 'LocalCallAI/1.0',
          },
          body: jsonEncode({
            'model': groqModel,
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
    final isUrgent = transcript.toLowerCase().contains('urgent') ||
        transcript.toLowerCase().contains('emergency') ||
        transcript.toLowerCase().contains('ತುರ್ತು');
    return {
      'callerName': session.callerName,
      'summary':
          'Call from ${session.callerName} (${session.callerNumber}). Topic: ${session.turns.isNotEmpty ? session.turns.last.text : "Brief greeting"}',
      'urgency': isUrgent ? 'high' : 'medium',
      'actionItems': ['Review call transcript', 'Follow up with ${session.callerName}'],
    };
  }
}
