import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/chat_message.dart';
import 'llm_service.dart';

class OllamaService implements LLMService {
  String baseUrl;
  final http.Client _client;

  OllamaService({
    this.baseUrl = 'http://10.0.2.2:11434',
    http.Client? client,
  }) : _client = client ?? http.Client();

  String get _normalizedBaseUrl {
    var url = baseUrl.trim();
    if (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'http://$url';
    }
    return url;
  }

  @override
  Future<bool> checkConnection() async {
    try {
      final uri = Uri.parse('$_normalizedBaseUrl/api/tags');
      final res = await _client.get(uri).timeout(const Duration(seconds: 4));
      return res.statusCode == 200;
    } catch (_) {
      try {
        final rootUri = Uri.parse(_normalizedBaseUrl);
        final rootRes = await _client.get(rootUri).timeout(const Duration(seconds: 3));
        return rootRes.statusCode == 200;
      } catch (_) {
        return false;
      }
    }
  }

  @override
  Future<List<String>> listAvailableModels() async {
    try {
      final uri = Uri.parse('$_normalizedBaseUrl/api/tags');
      final res = await _client.get(uri).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final models = data['models'] as List<dynamic>?;
        if (models != null) {
          return models.map((m) => m['name'] as String).toList();
        }
      }
    } catch (_) {}
    return [];
  }

  @override
  Stream<String> generateStream({
    required List<ChatMessage> history,
    required String systemPrompt,
    required String model,
    double temperature = 0.7,
    int? maxTokens,
  }) async* {
    final uri = Uri.parse('$_normalizedBaseUrl/api/chat');

    // Build messages payload
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

    final requestBody = jsonEncode({
      'model': model,
      'messages': messagesPayload,
      'stream': true,
      'options': {
        'temperature': temperature,
        if (maxTokens != null) 'num_predict': maxTokens,
      },
    });

    final request = http.Request('POST', uri);
    request.headers['Content-Type'] = 'application/json';
    request.body = requestBody;

    http.StreamedResponse response;
    try {
      response = await _client.send(request);
    } catch (e) {
      // If server is unreachable, yield informative guidance
      yield* _fallbackOfflineStream(history, model, e.toString());
      return;
    }

    if (response.statusCode != 200) {
      final errBody = await response.stream.bytesToString();
      yield* _fallbackOfflineStream(
        history,
        model,
        'Server returned HTTP ${response.statusCode}: $errBody',
      );
      return;
    }

    // Process the streamed NDJSON chunks
    final lineStream = response.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter());

    await for (final line in lineStream) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      try {
        final parsed = jsonDecode(trimmed) as Map<String, dynamic>;
        final message = parsed['message'] as Map<String, dynamic>?;
        if (message != null && message.containsKey('content')) {
          final contentChunk = message['content'] as String;
          if (contentChunk.isNotEmpty) {
            yield contentChunk;
          }
        }
        if (parsed['done'] == true) {
          break;
        }
      } catch (_) {
        // Skip malformed chunk
      }
    }
  }

  /// Interactive fallback generator when local server is offline or unreachable
  Stream<String> _fallbackOfflineStream(
    List<ChatMessage> history,
    String model,
    String errorDetail,
  ) async* {
    final lastUserMsg = history.lastWhere(
      (m) => m.isUser,
      orElse: () => ChatMessage(role: MessageRole.user, content: 'Hello'),
    );

    final reply = StringBuffer();
    reply.writeln('### ⚠️ Local Ollama Host Unreachable\n');
    reply.writeln('Could not connect to **`$_normalizedBaseUrl`** with model **`$model`**.\n');
    reply.writeln('> **Diagnostics:** $errorDetail\n');
    reply.writeln('#### 🚀 How to connect on your phone:\n');
    reply.writeln('1. **On your computer**, start Ollama to accept network connections:');
    reply.writeln('   ```bash');
    reply.writeln('   # Windows PowerShell');
    reply.writeln(r'   $env:OLLAMA_HOST = "0.0.0.0:11434"');
    reply.writeln('   ollama run $model');
    reply.writeln('   ```');
    reply.writeln('2. **Pull the Qwen 2.5 mobile model:**');
    reply.writeln('   ```bash');
    reply.writeln('   ollama run qwen2.5:0.5b');
    reply.writeln('   ```');
    reply.writeln('3. In this app, tap **Settings (⚙️)** and enter your PC\'s Wi-Fi IP address (e.g., `http://192.168.1.xxx:11434`).');
    reply.writeln('\n---\n*Your prompt:* "${lastUserMsg.content}"');

    final fullText = reply.toString();
    // Simulate natural token-by-token streaming for smooth UX
    final words = fullText.split(' ');
    for (int i = 0; i < words.length; i++) {
      yield (i == 0 ? '' : ' ') + words[i];
      await Future.delayed(const Duration(milliseconds: 15));
    }
  }

  void dispose() {
    _client.close();
  }
}
