import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/chat_message.dart';
import '../models/chat_session.dart';
import '../services/storage_service.dart';
import 'settings_provider.dart';

class ChatProvider with ChangeNotifier {
  final StorageService _storage;
  final SettingsProvider _settingsProvider;

  List<ChatSession> _sessions = [];
  late ChatSession _currentSession;
  bool _isGenerating = false;
  StreamSubscription<String>? _streamSub;

  ChatProvider(this._storage, this._settingsProvider) {
    _loadInitialSessions();
  }

  List<ChatSession> get sessions => _sessions;
  ChatSession get currentSession => _currentSession;
  List<ChatMessage> get messages => _currentSession.messages;
  bool get isGenerating => _isGenerating;

  void _loadInitialSessions() {
    _sessions = _storage.loadSessions();
    final savedActiveId = _storage.getActiveSessionId();

    if (_sessions.isNotEmpty) {
      if (savedActiveId != null) {
        _currentSession = _sessions.firstWhere(
          (s) => s.id == savedActiveId,
          orElse: () => _sessions.first,
        );
      } else {
        _currentSession = _sessions.first;
      }
    } else {
      _currentSession = _createNewSessionInstance();
      _sessions.add(_currentSession);
      _storage.saveSessions(_sessions);
      _storage.setActiveSessionId(_currentSession.id);
    }
  }

  ChatSession _createNewSessionInstance() {
    return ChatSession(
      modelId: _settingsProvider.selectedModel,
      systemPrompt: _settingsProvider.systemPrompt,
    );
  }

  Future<void> createNewSession() async {
    if (_isGenerating) {
      await cancelGeneration();
    }
    final newSession = _createNewSessionInstance();
    _sessions.insert(0, newSession);
    _currentSession = newSession;
    await _storage.saveSessions(_sessions);
    await _storage.setActiveSessionId(newSession.id);
    notifyListeners();
  }

  Future<void> switchSession(String sessionId) async {
    if (_isGenerating) {
      await cancelGeneration();
    }
    final target = _sessions.firstWhere((s) => s.id == sessionId);
    _currentSession = target;
    await _storage.setActiveSessionId(target.id);
    notifyListeners();
  }

  Future<void> deleteSession(String sessionId) async {
    _sessions.removeWhere((s) => s.id == sessionId);
    if (_currentSession.id == sessionId) {
      if (_sessions.isNotEmpty) {
        _currentSession = _sessions.first;
      } else {
        _currentSession = _createNewSessionInstance();
        _sessions.add(_currentSession);
      }
      await _storage.setActiveSessionId(_currentSession.id);
    }
    await _storage.saveSessions(_sessions);
    notifyListeners();
  }

  Future<void> clearCurrentSession() async {
    if (_isGenerating) {
      await cancelGeneration();
    }
    _currentSession.messages.clear();
    _currentSession.title = 'New Conversation';
    _currentSession.updatedAt = DateTime.now();
    await _saveCurrentState();
    notifyListeners();
  }

  Future<void> sendMessage(String text) async {
    final clean = text.trim();
    if (clean.isEmpty || _isGenerating) return;

    // Add user message
    final userMessage = ChatMessage(
      role: MessageRole.user,
      content: clean,
    );
    _currentSession.messages.add(userMessage);

    // Update conversation title if first message
    if (_currentSession.messages.where((m) => m.isUser).length == 1) {
      _currentSession.title = clean.length > 32 ? '${clean.substring(0, 32)}...' : clean;
    }
    _currentSession.updatedAt = DateTime.now();

    // Prepare assistant streaming placeholder
    final assistantMessage = ChatMessage(
      role: MessageRole.assistant,
      content: '',
      isStreaming: true,
      modelName: _settingsProvider.selectedModel,
    );
    _currentSession.messages.add(assistantMessage);

    _isGenerating = true;
    notifyListeners();

    final stopwatch = Stopwatch()..start();

    try {
      final stream = _settingsProvider.ollamaService.generateStream(
        history: _currentSession.messages.sublist(0, _currentSession.messages.length - 1),
        systemPrompt: _currentSession.systemPrompt.isNotEmpty
            ? _currentSession.systemPrompt
            : _settingsProvider.systemPrompt,
        model: _settingsProvider.selectedModel,
        temperature: _settingsProvider.temperature,
      );

      _streamSub = stream.listen(
        (chunk) {
          assistantMessage.content += chunk;
          notifyListeners();
        },
        onError: (err) {
          assistantMessage.content += '\n\n*(Error during generation: $err)*';
          assistantMessage.isStreaming = false;
          _isGenerating = false;
          notifyListeners();
        },
        onDone: () async {
          stopwatch.stop();
          final index = _currentSession.messages.indexWhere((m) => m.id == assistantMessage.id);
          if (index != -1) {
            _currentSession.messages[index] = assistantMessage.copyWith(
              isStreaming: false,
              latencyMs: stopwatch.elapsedMilliseconds,
            );
          }
          _isGenerating = false;
          await _saveCurrentState();
          notifyListeners();
        },
        cancelOnError: true,
      );
    } catch (e) {
      assistantMessage.content = 'Failed to generate response: $e';
      assistantMessage.isStreaming = false;
      _isGenerating = false;
      await _saveCurrentState();
      notifyListeners();
    }
  }

  Future<void> regenerateLastResponse() async {
    if (_isGenerating || _currentSession.messages.isEmpty) return;

    // Remove last assistant message if present
    if (_currentSession.messages.last.isAssistant) {
      _currentSession.messages.removeLast();
    }

    if (_currentSession.messages.isEmpty) return;

    final lastUserMsg = _currentSession.messages.lastWhere(
      (m) => m.isUser,
      orElse: () => ChatMessage(role: MessageRole.user, content: ''),
    );

    if (lastUserMsg.content.isEmpty) return;

    // Resend
    final text = lastUserMsg.content;
    _currentSession.messages.removeLast(); // remove to re-add cleanly via sendMessage
    await sendMessage(text);
  }

  Future<void> cancelGeneration() async {
    if (_streamSub != null) {
      await _streamSub?.cancel();
      _streamSub = null;
    }
    if (_currentSession.messages.isNotEmpty && _currentSession.messages.last.isStreaming) {
      _currentSession.messages.last.isStreaming = false;
    }
    _isGenerating = false;
    await _saveCurrentState();
    notifyListeners();
  }

  Future<void> _saveCurrentState() async {
    _currentSession.updatedAt = DateTime.now();
    await _storage.saveSessions(_sessions);
  }

  @override
  void dispose() {
    _streamSub?.cancel();
    super.dispose();
  }
}
