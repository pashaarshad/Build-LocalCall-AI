import 'package:flutter_test/flutter_test.dart';
import 'package:local_ai_chat/models/chat_message.dart';
import 'package:local_ai_chat/models/chat_session.dart';
import 'package:local_ai_chat/models/llm_model_info.dart';

void main() {
  test('ChatMessage serialization test', () {
    final msg = ChatMessage(
      role: MessageRole.user,
      content: 'Hello Local AI',
      modelName: 'qwen2.5:0.5b',
    );

    final json = msg.toJson();
    final reconstructed = ChatMessage.fromJson(json);

    expect(reconstructed.content, 'Hello Local AI');
    expect(reconstructed.role, MessageRole.user);
    expect(reconstructed.modelName, 'qwen2.5:0.5b');
  });

  test('ChatSession initialization test', () {
    final session = ChatSession(
      title: 'Meeting Notes',
      modelId: 'qwen2.5:1.5b',
    );

    expect(session.title, 'Meeting Notes');
    expect(session.modelId, 'qwen2.5:1.5b');
    expect(session.messages.isEmpty, true);
  });

  test('LLMModelInfo curated list includes Qwen 2.5', () {
    final defaultModel = LLMModelInfo.curatedModels.firstWhere((m) => m.isDefault);
    expect(defaultModel.id, 'qwen2.5:0.5b');

    final qwen15 = LLMModelInfo.findById('qwen2.5:1.5b');
    expect(qwen15.parameterSize, '1.5 Billion');
  });
}
