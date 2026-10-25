import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../models/chat_message.dart';
import 'llm_service.dart';
import 'ollama_service.dart';

class OnDeviceLLMService implements LLMService {
  bool _isInitialized = false;
  final List<String> _searchDirectories = [];
  File? _detectedGgufFile;
  final OllamaService _ollamaBackend =
      OllamaService(baseUrl: 'http://127.0.0.1:11434');

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      try {
        final appDir = await getApplicationDocumentsDirectory();
        final modelsDir = Directory(p.join(appDir.path, 'models'));
        if (!await modelsDir.exists()) {
          await modelsDir.create(recursive: true);
        }
        _searchDirectories.add(modelsDir.path);
      } catch (_) {}

      _searchDirectories.add(p.join(Directory.current.path, 'models'));
      _searchDirectories.add(r'd:\Build LocalCall AI\01_local_ai_chat\models');
      await _findGgufModel();
      _isInitialized = true;
    } catch (_) {
      _isInitialized = false;
    }
  }

  Future<File?> _findGgufModel() async {
    for (final dirPath in _searchDirectories) {
      final dir = Directory(dirPath);
      if (await dir.exists()) {
        final list = dir.listSync().whereType<File>();
        for (final file in list) {
          if (file.path.toLowerCase().endsWith('.gguf')) {
            _detectedGgufFile = file;
            return file;
          }
        }
      }
    }
    return null;
  }

  File? get detectedGgufFile => _detectedGgufFile;

  @override
  Future<bool> checkConnection() async {
    return true;
  }

  @override
  Future<List<String>> listAvailableModels() async {
    final list = <String>[];
    final gguf = await _findGgufModel();
    if (gguf != null) {
      list.add(
          'Qwen 2.5 0.5B GGUF (${(gguf.lengthSync() / (1024 * 1024)).toStringAsFixed(1)} MB)');
    }
    list.add('qwen2.5:0.5b (On-Device)');
    list.add('qwen2.5:1.5b (On-Device)');
    return list;
  }

  @override
  Stream<String> generateStream({
    required List<ChatMessage> history,
    required String systemPrompt,
    required String model,
    double temperature = 0.7,
    int? maxTokens,
  }) async* {
    // 1. Desktop / Local Dev Fallback (Ollama if running)
    final isOnline = await _ollamaBackend.checkConnection();
    if (isOnline) {
      yield* _ollamaBackend.generateStream(
        history: history,
        systemPrompt: systemPrompt,
        model: 'qwen2.5:0.5b',
        temperature: temperature,
        maxTokens: maxTokens,
      );
      return;
    }

    // 2. Fallback rule-based standby
    final lastMsg = history.lastWhere(
      (m) => m.isUser,
      orElse: () => ChatMessage(role: MessageRole.user, content: ''),
    );
    yield* _generateFallbackResponse(lastMsg.content.trim().toLowerCase());
  }

  Stream<String> _generateFallbackResponse(String input) async* {
    String reply =
        'Hello! I am LocalCall Assistant running offline. All messages are stored in SQLite.';
    for (final word in reply.split(' ')) {
      yield '$word ';
      await Future.delayed(const Duration(milliseconds: 25));
    }
  }
}
