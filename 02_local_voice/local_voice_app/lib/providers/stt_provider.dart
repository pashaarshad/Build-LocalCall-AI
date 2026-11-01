import 'package:flutter/foundation.dart';
import '../services/stt_service.dart';

class SttLanguage {
  final String id;
  final String name;
  final String nativeName;
  final String flag;

  const SttLanguage({
    required this.id,
    required this.name,
    required this.nativeName,
    required this.flag,
  });
}

class SttProvider with ChangeNotifier {
  final SttService _sttService = SttService();

  bool _isListening = false;
  bool _isAvailable = false;
  String _recognizedText = '';
  double _soundLevel = 0.0;
  String? _errorMessage;

  static const List<SttLanguage> supportedLanguages = [
    SttLanguage(id: 'kn_IN', name: 'Kannada', nativeName: 'ಕನ್ನಡ', flag: '🇮🇳'),
    SttLanguage(id: 'en_IN', name: 'English (India)', nativeName: 'English', flag: '🇮🇳'),
    SttLanguage(id: 'hi_IN', name: 'Hindi', nativeName: 'हिंदी', flag: '🇮🇳'),
    SttLanguage(id: 'ta_IN', name: 'Tamil', nativeName: 'தமிழ்', flag: '🇮🇳'),
    SttLanguage(id: 'te_IN', name: 'Telugu', nativeName: 'తెలుగు', flag: '🇮🇳'),
    SttLanguage(id: 'ml_IN', name: 'Malayalam', nativeName: 'മലയാളം', flag: '🇮🇳'),
    SttLanguage(id: 'bn_IN', name: 'Bengali', nativeName: 'বাংলা', flag: '🇮🇳'),
    SttLanguage(id: 'mr_IN', name: 'Marathi', nativeName: 'मराठी', flag: '🇮🇳'),
    SttLanguage(id: 'gu_IN', name: 'Gujarati', nativeName: 'ગુજરાતી', flag: '🇮🇳'),
    SttLanguage(id: 'ur_IN', name: 'Urdu', nativeName: 'اردو', flag: '🇮🇳'),
    SttLanguage(id: 'en_US', name: 'English (US)', nativeName: 'English', flag: '🇺🇸'),
    SttLanguage(id: 'en_GB', name: 'English (UK)', nativeName: 'English', flag: '🇬🇧'),
  ];

  late SttLanguage _selectedLanguage;

  SttProvider() {
    _selectedLanguage = supportedLanguages.first; // Kannada default as highlighted by user!
    init();
  }

  bool get isListening => _isListening;
  bool get isAvailable => _isAvailable;
  String get recognizedText => _recognizedText;
  double get soundLevel => _soundLevel;
  String? get errorMessage => _errorMessage;
  SttLanguage get selectedLanguage => _selectedLanguage;

  Future<void> init() async {
    _isAvailable = await _sttService.initialize(
      onStatus: (status) {
        if (status == 'notListening' || status == 'done') {
          _isListening = false;
          _soundLevel = 0.0;
          notifyListeners();
        }
      },
      onError: (err) {
        debugPrint('STT Provider error: $err');
        _isListening = false;
        _soundLevel = 0.0;
        notifyListeners();
      },
    );
    notifyListeners();
  }

  void selectLanguage(SttLanguage lang) {
    if (_selectedLanguage.id == lang.id) return;
    _selectedLanguage = lang;
    if (_isListening) {
      stopListening();
    }
    notifyListeners();
  }

  Future<void> toggleListening() async {
    if (_isListening) {
      await stopListening();
    } else {
      await startListening();
    }
  }

  Future<void> startListening() async {
    _errorMessage = null;

    if (!_isAvailable) {
      final ok = await _sttService.initialize();
      _isAvailable = ok;
      if (!ok) {
        _errorMessage = 'Speech recognition unavailable or microphone permission denied';
        notifyListeners();
        return;
      }
    }

    _isListening = true;
    notifyListeners();

    try {
      await _sttService.startListening(
        localeId: _selectedLanguage.id,
        onResult: (words, isFinal) {
          _recognizedText = words;
          notifyListeners();
        },
        onSoundLevel: (level) {
          // Normalize sound level (-10 to 10 dB into 0.0 to 1.0)
          final normalized = ((level + 10) / 20).clamp(0.0, 1.0);
          _soundLevel = normalized;
          notifyListeners();
        },
      );
    } catch (e) {
      _errorMessage = 'Failed to listen: $e';
      _isListening = false;
      notifyListeners();
    }
  }

  Future<void> stopListening() async {
    await _sttService.stopListening();
    _isListening = false;
    _soundLevel = 0.0;
    notifyListeners();
  }

  void clearText() {
    _recognizedText = '';
    notifyListeners();
  }

  void appendText(String text) {
    if (_recognizedText.isEmpty) {
      _recognizedText = text;
    } else {
      _recognizedText += ' $text';
    }
    notifyListeners();
  }
}
