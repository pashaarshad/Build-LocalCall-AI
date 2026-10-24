import '../models/chat_message.dart';

abstract class LLMService {
  /// Stream response chunks from the model.
  Stream<String> generateStream({
    required List<ChatMessage> history,
    required String systemPrompt,
    required String model,
    double temperature = 0.7,
    int? maxTokens,
  });

  /// Check whether the local LLM server / engine is reachable.
  Future<bool> checkConnection();

  /// Retrieve available models from the engine if supported.
  Future<List<String>> listAvailableModels();
}
