import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/chat_message.dart';
import '../models/chat_session.dart';
import '../services/database_helper.dart';
import '../services/storage_service.dart';
import 'settings_provider.dart';

class ChatProvider with ChangeNotifier {
  final StorageService _storage;
  final SettingsProvider _settingsProvider;
  final DatabaseHelper _dbHelper;

  List<ChatSession> _sessions = [];
  late ChatSession _currentSession;
  bool _isGenerating = false;
  bool _isDbReady = false;
  StreamSubscription<String>? _streamSub;

  ChatProvider(this._storage, this._settingsProvider, [DatabaseHelper? dbHelper])
      : _dbHelper = dbHelper ?? DatabaseHelper() {
    _initDatabaseAndSessions();
  }

  List<ChatSession> get sessions => _sessions;
  ChatSession get currentSession => _currentSession;
  List<ChatMessage> get messages => _currentSession.messages;
  bool get isGenerating => _isGenerating;
  bool get isDbReady => _isDbReady;

  Future<void> _initDatabaseAndSessions() async {
    try {
      final dbSessions = await _dbHelper.getSessions();
      if (dbSessions.isNotEmpty) {
        _sessions = dbSessions;
      } else {
        // Fall back to SharedPreferences if database is empty
        _sessions = _storage.loadSessions();
        for (final s in _sessions) {
          await _dbHelper.insertSession(s);
          for (final m in s.messages) {
            await _dbHelper.insertMessage(s.id, m);
          }
        }
      }

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
        await _dbHelper.insertSession(_currentSession);
        await _storage.setActiveSessionId(_currentSession.id);
      }
      _isDbReady = true;
      notifyListeners();
    } catch (_) {
      // In-memory fallback if SQLite fails on certain desktop test environments
      _currentSession = _createNewSessionInstance();
      _sessions = [_currentSession];
      _isDbReady = true;
      notifyListeners();
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

    try {
      await _dbHelper.insertSession(newSession);
      await _storage.setActiveSessionId(newSession.id);
    } catch (_) {}

    notifyListeners();
  }

  Future<void> switchSession(String sessionId) async {
    if (_isGenerating) {
      await cancelGeneration();
    }
    final target = _sessions.firstWhere((s) => s.id == sessionId);
    _currentSession = target;

    try {
      await _storage.setActiveSessionId(target.id);
    } catch (_) {}

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

    try {
      await _dbHelper.deleteSession(sessionId);
    } catch (_) {}

    notifyListeners();
  }

  Future<void> clearCurrentSession() async {
    if (_isGenerating) {
      await cancelGeneration();
    }
    _currentSession.messages.clear();
    _currentSession.title = 'New Conversation';
    _currentSession.updatedAt = DateTime.now();

    try {
      await _dbHelper.clearMessagesForSession(_currentSession.id);
      await _dbHelper.updateSession(_currentSession);
    } catch (_) {}

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
      _currentSession.title =
          clean.length > 32 ? '${clean.substring(0, 32)}...' : clean;
    }
    _currentSession.updatedAt = DateTime.now();

    // Insert user message into SQLite
    try {
      await _dbHelper.insertMessage(_currentSession.id, userMessage);
      await _dbHelper.updateSession(_currentSession);
    } catch (_) {}

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
      final stream = _settingsProvider.activeService.generateStream(
        history: _currentSession.messages
            .sublist(0, _currentSession.messages.length - 1),
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
          final index = _currentSession.messages
              .indexWhere((m) => m.id == assistantMessage.id);
          if (index != -1) {
            _currentSession.messages[index] = assistantMessage.copyWith(
              isStreaming: false,
              latencyMs: stopwatch.elapsedMilliseconds,
            );
          }
          _isGenerating = false;

          // Save completed assistant message to SQLite
          try {
            await _dbHelper.insertMessage(
                _currentSession.id, _currentSession.messages[index]);
            await _dbHelper.updateSession(_currentSession);
          } catch (_) {}

          notifyListeners();
        },
        cancelOnError: true,
      );
    } catch (e) {
      assistantMessage.content = 'Failed to generate response: $e';
      assistantMessage.isStreaming = false;
      _isGenerating = false;
      notifyListeners();
    }
  }

  Future<void> regenerateLastResponse() async {
    if (_isGenerating || _currentSession.messages.isEmpty) return;

    if (_currentSession.messages.last.isAssistant) {
      final lastMsg = _currentSession.messages.removeLast();
      try {
        final db = await _dbHelper.database;
        await db.delete(
          DatabaseHelper.tableMessages,
          where: 'id = ?',
          whereArgs: [lastMsg.id],
        );
      } catch (_) {}
    }

    if (_currentSession.messages.isEmpty) return;

    final lastUserMsg = _currentSession.messages.lastWhere(
      (m) => m.isUser,
      orElse: () => ChatMessage(role: MessageRole.user, content: ''),
    );

    if (lastUserMsg.content.isEmpty) return;

    final text = lastUserMsg.content;
    _currentSession.messages.removeLast();
    await sendMessage(text);
  }

  Future<void> cancelGeneration() async {
    if (_streamSub != null) {
      await _streamSub?.cancel();
      _streamSub = null;
    }
    if (_currentSession.messages.isNotEmpty &&
        _currentSession.messages.last.isStreaming) {
      _currentSession.messages.last.isStreaming = false;
      try {
        await _dbHelper.insertMessage(
            _currentSession.id, _currentSession.messages.last);
      } catch (_) {}
    }
    _isGenerating = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _streamSub?.cancel();
    super.dispose();
  }
}
