import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/call_session.dart';
import '../services/stt_call_service.dart';
import '../services/tts_call_service.dart';
import '../services/llm_call_agent_service.dart';
import '../services/telegram_attendant_service.dart';

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

  bool _isAttendantActive = true;
  String _assistantMode = 'Do Not Disturb'; // 'Do Not Disturb', 'Meeting', 'Driving', 'Custom'
  String _selectedLanguage = 'kn_IN'; // Kannada default
  CallSession? _currentCall;
  List<CallSession> _history = [];
  TurnStatus _turnStatus = TurnStatus.idle;
  double _soundLevel = 0.0;
  String _liveCallerWords = '';

  CallAssistantProvider() {
    _init();
  }

  bool get isAttendantActive => _isAttendantActive;
  String get assistantMode => _assistantMode;
  String get selectedLanguage => _selectedLanguage;
  CallSession? get currentCall => _currentCall;
  List<CallSession> get history => _history;
  TurnStatus get turnStatus => _turnStatus;
  double get soundLevel => _soundLevel;
  String get liveCallerWords => _liveCallerWords;
  LlmCallAgentService get llmService => _llmService;
  TelegramAttendantService get telegramService => _telegramService;

  Future<void> _init() async {
    await _ttsService.init(onCompletion: () {
      if (_currentCall != null && _currentCall!.status == CallStatus.connected) {
        // AI finished speaking -> resume listening for caller!
        _startListeningToCaller();
      }
    });

    await _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _isAttendantActive = prefs.getBool('isAttendantActive') ?? true;
    _assistantMode = prefs.getString('assistantMode') ?? 'Do Not Disturb';
    _selectedLanguage = prefs.getString('selectedLanguage') ?? 'kn_IN';
    _llmService.groqApiKey = prefs.getString('groqApiKey') ?? '';
    _llmService.ownerName = prefs.getString('ownerName') ?? 'Arshad';
    _telegramService.botToken = prefs.getString('telegramBotToken') ?? '';
    _telegramService.chatId = prefs.getString('telegramChatId') ?? '';
    _telegramService.isEnabled = prefs.getBool('telegramEnabled') ?? false;

    final historyJson = prefs.getStringList('callHistory') ?? [];
    _history = historyJson.map((e) => CallSession.fromJson(e)).toList();
    notifyListeners();
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isAttendantActive', _isAttendantActive);
    await prefs.setString('assistantMode', _assistantMode);
    await prefs.setString('selectedLanguage', _selectedLanguage);
    await prefs.setString('groqApiKey', _llmService.groqApiKey);
    await prefs.setString('ownerName', _llmService.ownerName);
    await prefs.setString('telegramBotToken', _telegramService.botToken);
    await prefs.setString('telegramChatId', _telegramService.chatId);
    await prefs.setBool('telegramEnabled', _telegramService.isEnabled);

    final historyJson = _history.map((e) => e.toJson()).toList();
    await prefs.setStringList('callHistory', historyJson);
  }

  void toggleAttendant(bool value) {
    _isAttendantActive = value;
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
  }) {
    _llmService.ownerName = ownerName;
    _llmService.groqApiKey = groqApiKey;
    _telegramService.botToken = telegramBotToken;
    _telegramService.chatId = telegramChatId;
    _telegramService.isEnabled = telegramEnabled;
    _savePreferences();
    notifyListeners();
  }

  // Simulate an Incoming Phone Call
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
    notifyListeners();

    // If auto-attendant is ACTIVE, auto-answer after 2 seconds ringing!
    if (_isAttendantActive) {
      Future.delayed(const Duration(milliseconds: 1800), () {
        if (_currentCall?.id == session.id && _currentCall?.status == CallStatus.incoming) {
          answerCall();
        }
      });
    }
  }

  // Answer call and trigger AI Assistant greeting
  Future<void> answerCall() async {
    if (_currentCall == null) return;
    _currentCall!.status = CallStatus.connected;
    _turnStatus = TurnStatus.speaking;
    notifyListeners();

    // Greeting in selected language
    String greeting;
    if (_selectedLanguage.startsWith('kn')) {
      greeting = 'ನಮಸ್ಕಾರ, ನಾನು ಅರ್ಷದ್ ಅವರ AI ಅಸಿಸ್ಟೆಂಟ್. ಅರ್ಷದ್ ಅವರು ಸದ್ಯಕ್ಕೆ ಲಭ್ಯವಿಲ್ಲ. ತಾವು ಯಾರು ಮತ್ತು ಯಾವ ವಿಷಯವಾಗಿ ಕರೆ ಮಾಡಿದ್ದೀರಿ ಎಂದು ತಿಳಿಸಬಹುದೇ?';
    } else if (_selectedLanguage.startsWith('hi')) {
      greeting = 'नमस्ते, मैं अरशद का एआई असिस्टेंट बोल रहा हूँ। अरशद अभी उपलब्ध नहीं हैं। कृपया बताएं आप कौन बोल रहे हैं?';
    } else {
      greeting = 'Hello! You have reached Arshad\'s AI Call Assistant. Arshad is currently unavailable. May I ask who is calling and how I can help you?';
    }

    _currentCall!.turns.add(
      CallTurn(
        speaker: 'assistant',
        text: greeting,
        timestamp: DateTime.now(),
      ),
    );
    notifyListeners();

    await _ttsService.speak(greeting, language: _selectedLanguage);
  }

  // Start continuous millisecond listening to caller
  Future<void> _startListeningToCaller() async {
    if (_currentCall == null || _currentCall!.status != CallStatus.connected) return;

    _turnStatus = TurnStatus.listening;
    _liveCallerWords = '';
    notifyListeners();

    await _sttService.startListening(
      localeId: _selectedLanguage,
      onResult: (words, isFinal) {
        _liveCallerWords = words;
        notifyListeners();

        if (isFinal && words.trim().isNotEmpty) {
          _handleCallerFinishedSpeaking(words);
        }
      },
      onSoundLevel: (level) {
        _soundLevel = ((level + 10) / 20).clamp(0.0, 1.0);
        notifyListeners();
      },
    );
  }

  // Process caller speech -> LLM -> TTS
  Future<void> _handleCallerFinishedSpeaking(String callerWords) async {
    if (_currentCall == null || _currentCall!.status != CallStatus.connected) return;

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

    // Generate AI response
    final reply = await _llmService.generateCallReply(
      history: _currentCall!.turns,
      lastCallerText: callerWords,
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

    // Speak AI response back to caller
    await _ttsService.speak(reply, language: _selectedLanguage);
  }

  // Manual caller speech submission for testing / typing in simulator
  void submitTestCallerSpeech(String text) {
    if (text.trim().isEmpty) return;
    _handleCallerFinishedSpeaking(text.trim());
  }

  // End Call & Debrief
  Future<void> endCall() async {
    if (_currentCall == null) return;

    await _sttService.stopListening();
    await _ttsService.stop();

    _currentCall!.status = CallStatus.ended;
    _currentCall!.endTime = DateTime.now();
    _turnStatus = TurnStatus.idle;
    _soundLevel = 0.0;
    _liveCallerWords = '';
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
