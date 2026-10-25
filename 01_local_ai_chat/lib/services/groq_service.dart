import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/chat_message.dart';
import 'llm_service.dart';

class GroqService implements LLMService {
  String apiKey;
  final http.Client _client;

  static const String endpoint = 'https://api.groq.com/openai/v1/chat/completions';

  GroqService({
    required this.apiKey,
    http.Client? client,
  }) : _client = client ?? http.Client();

  @override
  Future<bool> checkConnection() async {
    try {
      final res = await _client.get(
        Uri.parse('https://api.groq.com/openai/v1/models'),
        headers: {'Authorization': 'Bearer ${apiKey.trim()}'},
      ).timeout(const Duration(seconds: 5));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<List<String>> listAvailableModels() async {
    return [
      'qwen/qwen3.8-27b',
      'allam-2-7b',
      'openai/gpt-oss-20b',
    ];
  }

  @override
  Stream<String> generateStream({
    required List<ChatMessage> history,
    required String systemPrompt,
    required String model,
    double temperature = 0.7,
    int? maxTokens,
  }) async* {
    final effectiveModel = (model.contains('qwen') || model.contains('0.5b') || model.contains('1.5b'))
        ? 'qwen/qwen3.8-27b'
        : (model.contains('allam') ? 'allam-2-7b' : model);

    final messagesPayload = <Map<String, String>>[];

    if (systemPrompt.trim().isNotEmpty) {
      messagesPayload.add({
        'role': 'system',
        'content': systemPrompt.trim(),
      });
    }

    for (final msg in history) {
      if (msg.content.trim().isEmpty) continue;
      messagesPayload.add({
        'role': msg.role.name,
        'content': msg.content,
      });
    }

    final request = http.Request('POST', Uri.parse(endpoint));
    request.headers.addAll({
      'Authorization': 'Bearer ${apiKey.trim()}',
      'Content-Type': 'application/json',
    });

    request.body = jsonEncode({
      'model': effectiveModel,
      'messages': messagesPayload,
      'temperature': temperature,
      'stream': true,
      if (maxTokens != null) 'max_tokens': maxTokens,
    });

    http.StreamedResponse response;
    try {
      response = await _client.send(request);
    } catch (e) {
      yield 'Connection error: $e';
      return;
    }

    if (response.statusCode != 200) {
      final err = await response.stream.bytesToString();
      yield 'API Error (${response.statusCode}): $err';
      return;
    }

    // Process OpenAI-compatible SSE stream
    final lineStream = response.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter());

    await for (final line in lineStream) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      if (trimmed == 'data: [DONE]') break;

      if (trimmed.startsWith('data: ')) {
        final jsonStr = trimmed.substring(6).trim();
        try {
          final data = jsonDecode(jsonStr) as Map<String, dynamic>;
          final choices = data['choices'] as List<dynamic>?;
          if (choices != null && choices.isNotEmpty) {
            final delta = choices[0]['delta'] as Map<String, dynamic>?;
            final content = delta?['content'] as String?;
            if (content != null && content.isNotEmpty) {
              yield content;
            }
          }
        } catch (_) {}
      }
    }
  }
}
