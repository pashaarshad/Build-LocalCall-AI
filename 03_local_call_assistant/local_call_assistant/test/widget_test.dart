import 'package:flutter_test/flutter_test.dart';
import 'package:local_call_assistant/models/call_session.dart';
import 'package:local_call_assistant/services/llm_call_agent_service.dart';

void main() {
  test('CallSession creation, duration, and serialization', () {
    final now = DateTime.now();
    final session = CallSession(
      id: 'test_123',
      callerName: 'Vijay Kumar',
      callerNumber: '+91 98450 12345',
      startTime: now.subtract(const Duration(seconds: 75)),
      endTime: now,
      status: CallStatus.ended,
      urgency: UrgencyLevel.high,
      language: 'kn_IN',
    );

    session.turns.add(
      CallTurn(
        speaker: 'assistant',
        text: 'ನಮಸ್ಕಾರ, ನಾನು ಅರ್ಷದ್ ಅವರ AI ಅಸಿಸ್ಟೆಂಟ್.',
        timestamp: now.subtract(const Duration(seconds: 70)),
      ),
    );

    session.turns.add(
      CallTurn(
        speaker: 'caller',
        text: 'ನನಗೆ ಅರ್ಷದ್ ಅವರ ಹತ್ತಿರ ಅರ್ಜೆಂಟ್ ಕೆಲಸವಿದೆ.',
        timestamp: now.subtract(const Duration(seconds: 60)),
      ),
    );

    expect(session.durationSeconds, greaterThanOrEqualTo(74));
    expect(session.formattedDuration, '01:15');
    expect(session.turns.length, 2);

    final map = session.toMap();
    final restored = CallSession.fromMap(map);

    expect(restored.callerName, 'Vijay Kumar');
    expect(restored.turns.length, 2);
    expect(restored.urgency, UrgencyLevel.high);
    expect(restored.language, 'kn_IN');
  });

  test('LlmCallAgentService extracts caller name from speech', () {
    final service = LlmCallAgentService();

    expect(service.extractCallerName('Hello, my name is Rahul Sharma'), 'Rahul Sharma');
    expect(service.extractCallerName('I am John and I want to speak with Arshad'), 'John');
    expect(service.extractCallerName('ನಾನು ರಮೇಶ್ ಇಲ್ಲಿ'), 'ರಮೇಶ್');
  });

  test('LlmCallAgentService generates contextual reply acknowledging caller name', () async {
    final service = LlmCallAgentService();
    service.ownerName = 'Arshad';

    final history = [
      CallTurn(
        speaker: 'assistant',
        text: 'Hello! You have reached Arshad\'s AI Assistant. May I ask who is calling?',
        timestamp: DateTime.now(),
      ),
    ];

    final reply = await service.generateCallReply(
      history: history,
      lastCallerText: 'Hello, this is Vijay. I need to talk to Arshad.',
      callerName: 'Vijay',
      language: 'en_IN',
    );

    expect(reply.toLowerCase(), contains('vijay'));
    expect(reply.toLowerCase(), contains('arshad'));
  });
}
