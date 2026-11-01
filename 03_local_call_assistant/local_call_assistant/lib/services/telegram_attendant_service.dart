import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/call_session.dart';

class TelegramAttendantService {
  String botToken = '';
  String chatId = '';
  bool isEnabled = false;

  Future<bool> sendCallReport(CallSession session) async {
    if (!isEnabled || botToken.isEmpty || chatId.isEmpty) {
      debugPrint('Telegram Attendant is not configured or disabled');
      return false;
    }

    final urgencyEmoji = switch (session.urgency) {
      UrgencyLevel.high => '🚨 *HIGH PRIORITY CALL*',
      UrgencyLevel.medium => '⚡ *NORMAL PRIORITY*',
      UrgencyLevel.low => 'ℹ️ *LOW PRIORITY*',
    };

    final transcriptText = session.turns
        .map((t) => '${t.speaker == "caller" ? "👤 Caller" : "🤖 AI"}: ${t.text}')
        .join('\n');

    final actionItemsText = session.actionItems.isEmpty
        ? 'None'
        : session.actionItems.map((a) => '• $a').join('\n');

    final message = '''
📞 *LocalCall AI Assistant Attended Call*

$urgencyEmoji
*Caller:* ${session.callerName} (${session.callerNumber})
*Duration:* ${session.formattedDuration}
*Language:* ${session.language}

📝 *Summary:*
${session.summary ?? "Call completed"}

✅ *Action Items:*
$actionItemsText

💬 *Full Conversation Transcript:*
```
$transcriptText
```
''';

    try {
      final url = Uri.parse('https://api.telegram.org/bot$botToken/sendMessage');
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'chat_id': chatId,
          'text': message,
          'parse_mode': 'Markdown',
        }),
      );

      return res.statusCode == 200;
    } catch (e) {
      debugPrint('Telegram send error: $e');
      return false;
    }
  }

  Future<bool> testConnection() async {
    if (botToken.isEmpty) return false;
    try {
      final url = Uri.parse('https://api.telegram.org/bot$botToken/getMe');
      final res = await http.get(url);
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
