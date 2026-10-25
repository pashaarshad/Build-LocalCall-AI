import 'package:flutter_test/flutter_test.dart';
import 'package:local_ai_chat/models/chat_message.dart';
import 'package:local_ai_chat/models/chat_session.dart';
import 'package:local_ai_chat/models/llm_model_info.dart';

void main() {
  test('ChatMessage serialization test', () {
    final msg = ChatMessage(
      role: MessageRole.user,
      content: 'Hello LocalCall AI',
      modelName: 'qwen/qwen3.8-27b',
    );

    final json = msg.toJson();
    final reconstructed = ChatMessage.fromJson(json);

    expect(reconstructed.content, 'Hello LocalCall AI');
    expect(reconstructed.role, MessageRole.user);
    expect(reconstructed.modelName, 'qwen/qwen3.8-27b');
  });

  test('ChatSession initialization test', () {
    final session = ChatSession(
      title: 'Meeting Notes',
      modelId: 'qwen/qwen3.8-27b',
    );

    expect(session.title, 'Meeting Notes');
    expect(session.modelId, 'qwen/qwen3.8-27b');
    expect(session.messages.isEmpty, true);
  });

  test('LLMModelInfo curated list includes Groq models', () {
    final defaultModel = LLMModelInfo.curatedModels.firstWhere((m) => m.isDefault);
    expect(defaultModel.id, 'qwen/qwen3.8-27b');

    final qwen = LLMModelInfo.findById('qwen/qwen3.8-27b');
    expect(qwen.name, 'Qwen 3.8 (27B)');
  });
}
