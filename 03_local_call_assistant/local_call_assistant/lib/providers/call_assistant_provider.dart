import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/call_session.dart';
import '../services/stt_call_service.dart';
import '../services/tts_call_service.dart';
import '../services/llm_call_agent_service.dart';
import '../services/telegram_attendant_service.dart';
import '../services/telephony_native_service.dart';

enum TurnStatus {
  idle,
  listening,
  generating,
  speaking,
}

class CallAssistantProvider with ChangeNotifier {
  final SttCallService _sttService = SttCallService();
  final TtsCallService _ttsService = TtsCallService();
  final LlmCallAgentService _llmService = LlmCallAgentService();
  final TelegramAttendantService _telegramService = TelegramAttendantService();
  final TelephonyNativeService _telephonyService = TelephonyNativeService();

  bool _isAttendantActive = true;
  int _ringsThreshold = 3; // Auto-answers real phone calls after 3 rings!
  int _currentRingCount = 0;
  String _assistantMode = 'Do Not Disturb';
  String _selectedLanguage = 'kn_IN'; // Kannada default
  CallSession? _currentCall;
  List<CallSession> _history = [];
  TurnStatus _turnStatus = TurnStatus.idle;
  double _soundLevel = 0.0;
  String _liveCallerWords = '';
  Timer? _silencePauseTimer;
  bool _permissionsGranted = false;

  CallAssistantProvider() {
    _init();
  }

  bool get isAttendantActive => _isAttendantActive;
  int get ringsThreshold => _ringsThreshold;
  int get currentRingCount => _currentRingCount;
  String get assistantMode => _assistantMode;
  String get selectedLanguage => _selectedLanguage;
  CallSession? get currentCall => _currentCall;
  List<CallSession> get history => _history;
  TurnStatus get turnStatus => _turnStatus;
  double get soundLevel => _soundLevel;
  String get liveCallerWords => _liveCallerWords;
  bool get permissionsGranted => _permissionsGranted;
  LlmCallAgentService get llmService => _llmService;
  TelegramAttendantService get telegramService => _telegramService;

  Future<void> _init() async {
    // Setup Native Telephony Call Interception
    _telephonyService.onIncomingCallRinging = (number, ringCount) {
      _currentRingCount = ringCount;
      if (_currentCall == null && _isAttendantActive) {
        _currentCall = CallSession(
          id: 'real_call_${DateTime.now().millisecondsSinceEpoch}',
          callerName: 'Incoming Cellular Call',
          callerNumber: number,
          startTime: DateTime.now(),
          status: CallStatus.incoming,
          language: _selectedLanguage,
        );
      }
      notifyListeners();
    };

    _telephonyService.onIncomingCallAnswered = (number) {
      debugPrint('Real phone call answered by AI Assistant: $number');
      if (_currentCall == null) {
        _currentCall = CallSession(
          id: 'real_call_${DateTime.now().millisecondsSinceEpoch}',
          callerName: 'Incoming Cellular Call',
          callerNumber: number,
          startTime: DateTime.now(),
          status: CallStatus.connected,
          language: _selectedLanguage,
        );
      } else {
        _currentCall!.status = CallStatus.connected;
      }
      _currentRingCount = 0;
      notifyListeners();
      answerCall();
    };

    _telephonyService.onCallEnded = () {
      debugPrint('Real phone call ended');
      _currentRingCount = 0;
      if (_currentCall != null && _currentCall!.status != CallStatus.ended) {
        endCall();
      }
    };

    await _ttsService.init(onCompletion: () {
      if (_currentCall != null && _currentCall!.status == CallStatus.connected) {
        // AI finished speaking -> resume listening for caller!
        _startListeningToCaller();
      }
    });

    await _loadPreferences();
    await checkPermissions();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _isAttendantActive = prefs.getBool('isAttendantActive') ?? true;
    _ringsThreshold = prefs.getInt('ringsThreshold') ?? 3;
    _assistantMode = prefs.getString('assistantMode') ?? 'Do Not Disturb';
    _selectedLanguage = prefs.getString('selectedLanguage') ?? 'kn_IN';
    final savedKey = prefs.getString('groqApiKey');
    if (savedKey != null && savedKey.trim().isNotEmpty) {
      _llmService.groqApiKey = savedKey.trim();
    }
    _llmService.ownerName = prefs.getString('ownerName') ?? 'Arshad';
    _telegramService.botToken = prefs.getString('telegramBotToken') ?? '';
    _telegramService.chatId = prefs.getString('telegramChatId') ?? '';
    _telegramService.isEnabled = prefs.getBool('telegramEnabled') ?? false;

    final historyJson = prefs.getStringList('callHistory') ?? [];
    _history = historyJson.map((e) => CallSession.fromJson(e)).toList();

    await _telephonyService.setAttendantActive(_isAttendantActive);
    await _telephonyService.setRingsThreshold(_ringsThreshold);
    notifyListeners();
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isAttendantActive', _isAttendantActive);
    await prefs.setInt('ringsThreshold', _ringsThreshold);
    await prefs.setString('assistantMode', _assistantMode);
    await prefs.setString('selectedLanguage', _selectedLanguage);
    await prefs.setString('groqApiKey', _llmService.groqApiKey);
    await prefs.setString('ownerName', _llmService.ownerName);
    await prefs.setString('telegramBotToken', _telegramService.botToken);
    await prefs.setString('telegramChatId', _telegramService.chatId);
    await prefs.setBool('telegramEnabled', _telegramService.isEnabled);

    final historyJson = _history.map((e) => e.toJson()).toList();
    await prefs.setStringList('callHistory', historyJson);

    await _telephonyService.setAttendantActive(_isAttendantActive);
    await _telephonyService.setRingsThreshold(_ringsThreshold);
  }

  Future<void> checkPermissions() async {
    final status = await _telephonyService.checkPermissions();
    _permissionsGranted = status['allGranted'] ?? false;
    notifyListeners();
  }

  Future<void> requestPermissions() async {
    final status = await _telephonyService.requestPermissions();
    _permissionsGranted = status['allGranted'] ?? false;
    notifyListeners();
  }

  Future<void> openAppSettings() async {
    await _telephonyService.openAppSettings();
  }

  void toggleAttendant(bool value) {
    _isAttendantActive = value;
    _savePreferences();
    notifyListeners();
  }

  void setRingsThreshold(int rings) {
    _ringsThreshold = rings;
    _savePreferences();
    notifyListeners();
  }

  void setMode(String mode) {
    _assistantMode = mode;
    _savePreferences();
    notifyListeners();
  }

  void setLanguage(String lang) {
    _selectedLanguage = lang;
    _savePreferences();
    notifyListeners();
  }

  void updateSettings({
    required String ownerName,
    required String groqApiKey,
    required String telegramBotToken,
    required String telegramChatId,
    required bool telegramEnabled,
    int? ringsThreshold,
  }) {
    _llmService.ownerName = ownerName;
    _llmService.groqApiKey = groqApiKey;
    _telegramService.botToken = telegramBotToken;
    _telegramService.chatId = telegramChatId;
    _telegramService.isEnabled = telegramEnabled;
    if (ringsThreshold != null) _ringsThreshold = ringsThreshold;
    _savePreferences();
    notifyListeners();
  }

  // Simulate an Incoming Phone Call with 3 Rings Cadence
  void simulateIncomingCall({String? callerName, String? callerNumber}) {
    final session = CallSession(
      id: 'call_${DateTime.now().millisecondsSinceEpoch}',
      callerName: callerName ?? 'Vijay Kumar',
      callerNumber: callerNumber ?? '+91 98450 12345',
      startTime: DateTime.now(),
      status: CallStatus.incoming,
      language: _selectedLanguage,
    );

    _currentCall = session;
    _turnStatus = TurnStatus.idle;
    _liveCallerWords = '';
    _currentRingCount = 1;
    notifyListeners();

    // Ring 2 after 2.8 seconds
    Timer(const Duration(milliseconds: 2800), () {
      if (_currentCall?.id == session.id && _currentCall?.status == CallStatus.incoming) {
        _currentRingCount = 2;
        notifyListeners();
      }
    });

    // Ring 3 after 5.6 seconds
    Timer(const Duration(milliseconds: 5600), () {
      if (_currentCall?.id == session.id && _currentCall?.status == CallStatus.incoming) {
        _currentRingCount = 3;
        notifyListeners();
      }
    });

    // Auto-answer after 3 rings (~8 seconds) if Attendant is ACTIVE!
    if (_isAttendantActive) {
      Timer(const Duration(milliseconds: 8000), () {
        if (_currentCall?.id == session.id && _currentCall?.status == CallStatus.incoming) {
          _currentRingCount = 0;
          answerCall();
        }
      });
    }
  }

  // Answer call and trigger AI Assistant greeting
  Future<void> answerCall() async {
    if (_currentCall == null) return;
    _currentCall!.status = CallStatus.connected;
    _currentRingCount = 0;
    _turnStatus = TurnStatus.speaking;
    notifyListeners();

    // Courteous initial greeting
    String greeting;
    if (_selectedLanguage.startsWith('kn')) {
      greeting = 'ನಮಸ್ಕಾರ, ನಾನು ${_llmService.ownerName} ಅವರ AI ಅಸಿಸ್ಟೆಂಟ್. ${_llmService.ownerName} ಅವರು ಸದ್ಯಕ್ಕೆ ಲಭ್ಯವಿಲ್ಲ. ತಾವು ಯಾರೆಂದು ತಿಳಿಸಬಹುದೇ?';
    } else if (_selectedLanguage.startsWith('hi')) {
      greeting = 'नमस्ते, मैं ${_llmService.ownerName} का AI असिस्टेंट हूँ। ${_llmService.ownerName} अभी व्यस्त हैं। कृपया बताएं आप कौन बोल रहे हैं?';
    } else {
      greeting = 'Hello! You have reached ${_llmService.ownerName}\'s AI Assistant. ${_llmService.ownerName} is currently unavailable. May I ask who is calling?';
    }

    _currentCall!.turns.add(
      CallTurn(
        speaker: 'assistant',
        text: greeting,
        timestamp: DateTime.now(),
      ),
    );
    notifyListeners();

    // Start barge-in listening while speaking
    _startSimultaneousListening();

    await _ttsService.speak(greeting, language: _selectedLanguage);
  }

  // Simultaneous listening (Barge-in capability) while AI speaks
  Future<void> _startSimultaneousListening() async {
    await _sttService.startListening(
      localeId: _selectedLanguage,
      onResult: (words, isFinal) {
        if (_turnStatus == TurnStatus.speaking && words.trim().isNotEmpty) {
          // Caller interrupted the AI!
          debugPrint('Caller interrupted AI with words: $words');
          _ttsService.stop();
          _turnStatus = TurnStatus.listening;
          _liveCallerWords = words;
          notifyListeners();
        }
      },
      onSoundLevel: (level) {
        _soundLevel = ((level + 10) / 20).clamp(0.0, 1.0);
        notifyListeners();
      },
    );
  }

  // Start continuous millisecond listening with Smart Sentence & Full-Stop Detection
  Future<void> _startListeningToCaller() async {
    if (_currentCall == null || _currentCall!.status != CallStatus.connected) return;

    _turnStatus = TurnStatus.listening;
    _liveCallerWords = '';
    _silencePauseTimer?.cancel();
    notifyListeners();

    await _sttService.startListening(
      localeId: _selectedLanguage,
      onResult: (words, isFinal) {
        _liveCallerWords = words;
        notifyListeners();

        // Check if caller mentions their name dynamically
        final detectedName = _llmService.extractCallerName(words);
        if (detectedName != null &&
            (_currentCall!.callerName == 'Unknown Caller' ||
                _currentCall!.callerName == 'Incoming Cellular Call' ||
                _currentCall!.callerName.startsWith('+'))) {
          _currentCall = CallSession(
            id: _currentCall!.id,
            callerName: detectedName,
            callerNumber: _currentCall!.callerNumber,
            startTime: _currentCall!.startTime,
            endTime: _currentCall!.endTime,
            status: _currentCall!.status,
            turns: _currentCall!.turns,
            summary: _currentCall!.summary,
            actionItems: _currentCall!.actionItems,
            urgency: _currentCall!.urgency,
            language: _currentCall!.language,
          );
          notifyListeners();
        }

        // Smart Turn-Taking: Sentence Boundary Detection
        final trimmed = words.trim();
        final isSentenceTerminated = trimmed.endsWith('.') ||
            trimmed.endsWith('?') ||
            trimmed.endsWith('!') ||
            trimmed.endsWith('।') ||
            trimmed.endsWith('?');

        if (isSentenceTerminated && trimmed.length > 5) {
          debugPrint('Sentence boundary detected via punctuation: "$trimmed"');
          _silencePauseTimer?.cancel();
          _handleCallerFinishedSpeaking(trimmed);
          return;
        }

        // Natural speech pause debounce: 1.4 seconds of silence after speaking
        _silencePauseTimer?.cancel();
        if (trimmed.split(RegExp(r'\s+')).length >= 2) {
          _silencePauseTimer = Timer(const Duration(milliseconds: 1400), () {
            if (_turnStatus == TurnStatus.listening && _liveCallerWords.trim().isNotEmpty) {
              debugPrint('Natural speech pause detected: "$_liveCallerWords"');
              _handleCallerFinishedSpeaking(_liveCallerWords.trim());
            }
          });
        }

        if (isFinal && trimmed.isNotEmpty) {
          _silencePauseTimer?.cancel();
          _handleCallerFinishedSpeaking(trimmed);
        }
      },
      onSoundLevel: (level) {
        _soundLevel = ((level + 10) / 20).clamp(0.0, 1.0);
        notifyListeners();
      },
    );
  }

  // Process caller speech -> LLM with context -> TTS reply
  Future<void> _handleCallerFinishedSpeaking(String callerWords) async {
    if (_currentCall == null || _currentCall!.status != CallStatus.connected) return;

    _silencePauseTimer?.cancel();
    await _sttService.stopListening();
    _turnStatus = TurnStatus.generating;
    _soundLevel = 0.0;

    _currentCall!.turns.add(
      CallTurn(
        speaker: 'caller',
        text: callerWords,
        timestamp: DateTime.now(),
      ),
    );
    _liveCallerWords = '';
    notifyListeners();

    // Check again for caller name
    final detectedName = _llmService.extractCallerName(callerWords);
    final activeCallerName = detectedName ?? _currentCall!.callerName;

    // Generate context-aware AI response
    final reply = await _llmService.generateCallReply(
      history: _currentCall!.turns,
      lastCallerText: callerWords,
      callerName: activeCallerName,
      language: _selectedLanguage,
    );

    _currentCall!.turns.add(
      CallTurn(
        speaker: 'assistant',
        text: reply,
        timestamp: DateTime.now(),
      ),
    );

    _turnStatus = TurnStatus.speaking;
    notifyListeners();

    // Keep microphone listening for barge-in interruptions
    _startSimultaneousListening();

    // Speak AI response back to caller
    await _ttsService.speak(reply, language: _selectedLanguage);
  }

  // Manual caller speech submission for simulator testing
  void submitTestCallerSpeech(String text) {
    if (text.trim().isEmpty) return;
    _handleCallerFinishedSpeaking(text.trim());
  }

  // End Call & Debrief
  Future<void> endCall() async {
    if (_currentCall == null) return;

    _silencePauseTimer?.cancel();
    await _sttService.stopListening();
    await _ttsService.stop();

    _currentCall!.status = CallStatus.ended;
    _currentCall!.endTime = DateTime.now();
    _turnStatus = TurnStatus.idle;
    _soundLevel = 0.0;
    _liveCallerWords = '';
    _currentRingCount = 0;
    notifyListeners();

    // Summarize call
    final summaryData = await _llmService.summarizeCall(_currentCall!);
    _currentCall!.summary = summaryData['summary'] as String?;
    _currentCall!.actionItems = (summaryData['actionItems'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
    final urgencyStr = summaryData['urgency'] as String? ?? 'medium';
    _currentCall!.urgency = UrgencyLevel.values.firstWhere(
      (e) => e.name == urgencyStr,
      orElse: () => UrgencyLevel.medium,
    );

    final extractedName = summaryData['callerName'] as String?;
    if (extractedName != null && extractedName.isNotEmpty && _currentCall!.callerName == 'Incoming Cellular Call') {
      _currentCall = CallSession(
        id: _currentCall!.id,
        callerName: extractedName,
        callerNumber: _currentCall!.callerNumber,
        startTime: _currentCall!.startTime,
        endTime: _currentCall!.endTime,
        status: _currentCall!.status,
        turns: _currentCall!.turns,
        summary: _currentCall!.summary,
        actionItems: _currentCall!.actionItems,
        urgency: _currentCall!.urgency,
        language: _currentCall!.language,
      );
    }

    // Send Telegram alert
    if (_telegramService.isEnabled) {
      await _telegramService.sendCallReport(_currentCall!);
    }

    _history.insert(0, _currentCall!);
    await _savePreferences();
    notifyListeners();
  }

  void clearHistory() {
    _history.clear();
    _savePreferences();
    notifyListeners();
  }
}
