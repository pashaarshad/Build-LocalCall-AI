import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/voice_model.dart';
import '../models/audio_generation.dart';
import '../services/api_service.dart';
import '../services/local_tts_service.dart';
import '../services/universal_tts_service.dart';

class VoiceProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final LocalTtsService _localTts = LocalTtsService();
  final SharedPreferences _prefs;

  List<VoiceModel> _allVoices = [];
  VoiceModel _selectedVoice = ApiService.defaultFallbackVoices().first;

  // Voice tuning settings
  int _rate = 0;       // -50% to +100%
  int _pitch = 0;      // -50Hz to +50Hz
  int _volume = 0;     // -50% to +50%

  // Filter and search
  String _activeCategory = 'recommended'; // 'recommended', 'indian', 'all', 'female', 'male'
  String _searchQuery = '';

  // UI state
  bool _isGenerating = false;
  bool _isLoadingVoices = false;
  bool _isSpeakingLocal = false;
  String? _errorMessage;

  AudioGeneration? _currentAudio;
  List<AudioGeneration> _history = [];

  static const String _prefKeyHistory = 'voice_studio_history_v1';
  static const String _prefKeyVoice = 'voice_studio_selected_voice_v1';
  static const String _prefKeyRate = 'voice_studio_rate_v1';
  static const String _prefKeyPitch = 'voice_studio_pitch_v1';

  VoiceProvider(this._prefs) {
    _loadSettings();
    initVoices();
  }

  // Getters
  List<VoiceModel> get allVoices => _allVoices;
  VoiceModel get selectedVoice => _selectedVoice;
  int get rate => _rate;
  int get pitch => _pitch;
  int get volume => _volume;
  String get activeCategory => _activeCategory;
  String get searchQuery => _searchQuery;
  bool get isGenerating => _isGenerating;
  bool get isLoadingVoices => _isLoadingVoices;
  bool get isSpeakingLocal => _isSpeakingLocal;
  String? get errorMessage => _errorMessage;
  AudioGeneration? get currentAudio => _currentAudio;
  List<AudioGeneration> get history => _history;

  List<VoiceModel> get filteredVoices {
    return _allVoices.where((v) {
      if (_activeCategory == 'recommended') {
        if (v.tier != 'recommended') return false;
      } else if (_activeCategory == 'indian') {
        if (!v.isIndian) return false;
      } else if (_activeCategory == 'female') {
        if (!v.isFemale) return false;
      } else if (_activeCategory == 'male') {
        if (v.isFemale) return false;
      }

      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchesName = v.friendlyName.toLowerCase().contains(q) ||
            v.shortName.toLowerCase().contains(q);
        final matchesLang = v.langDisplay.toLowerCase().contains(q) ||
            v.locale.toLowerCase().contains(q);
        final matchesDesc = v.description.toLowerCase().contains(q);
        if (!matchesName && !matchesLang && !matchesDesc) return false;
      }

      return true;
    }).toList();
  }

  void _loadSettings() {
    _rate = _prefs.getInt(_prefKeyRate) ?? 0;
    _pitch = _prefs.getInt(_prefKeyPitch) ?? 0;

    final historyJson = _prefs.getStringList(_prefKeyHistory);
    if (historyJson != null) {
      try {
        _history = historyJson
            .map((str) => AudioGeneration.fromJson(jsonDecode(str)))
            .toList();
        if (_history.isNotEmpty) {
          _currentAudio = _history.first;
        }
      } catch (e) {
        debugPrint('Failed to load history: $e');
      }
    }
  }

  Future<void> initVoices() async {
    _isLoadingVoices = true;
    _allVoices = ApiService.defaultFallbackVoices();
    notifyListeners();

    await _localTts.init();

    try {
      final remoteVoices = await _apiService.fetchVoices();
      if (remoteVoices.isNotEmpty) {
        _allVoices = remoteVoices;
      }
    } catch (_) {}

    final savedVoiceName = _prefs.getString(_prefKeyVoice);
    if (savedVoiceName != null) {
      final found = _allVoices.firstWhere(
        (v) => v.shortName == savedVoiceName,
        orElse: () => _allVoices.first,
      );
      _selectedVoice = found;
    } else {
      _selectedVoice = _allVoices.first;
    }

    _isLoadingVoices = false;
    notifyListeners();
  }

  void selectVoice(VoiceModel voice) {
    _selectedVoice = voice;
    _prefs.setString(_prefKeyVoice, voice.shortName);
    notifyListeners();
  }

  void setCategory(String category) {
    _activeCategory = category;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query.trim();
    notifyListeners();
  }

  void setRate(int newRate) {
    _rate = newRate.clamp(-50, 100);
    _prefs.setInt(_prefKeyRate, _rate);
    notifyListeners();
  }

  void setPitch(int newPitch) {
    _pitch = newPitch.clamp(-50, 50);
    _prefs.setInt(_prefKeyPitch, _pitch);
    notifyListeners();
  }

  void setVolume(int newVolume) {
    _volume = newVolume.clamp(-50, 50);
    notifyListeners();
  }

  void resetTuning() {
    _rate = 0;
    _pitch = 0;
    _volume = 0;
    _prefs.setInt(_prefKeyRate, 0);
    _prefs.setInt(_prefKeyPitch, 0);
    notifyListeners();
  }

  Future<AudioGeneration?> convertTextToVoice(String text) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty) {
      _errorMessage = 'Please enter some text to convert';
      notifyListeners();
      return null;
    }

    _isGenerating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Automatic language detection & voice matching for Indian & Global languages
      VoiceModel voiceToUse = _selectedVoice;
      final hasHindi = RegExp(r'[\u0900-\u097F]').hasMatch(cleanText);
      final hasTamil = RegExp(r'[\u0B80-\u0BFF]').hasMatch(cleanText);
      final hasTelugu = RegExp(r'[\u0C00-\u0C7F]').hasMatch(cleanText);
      final hasBengali = RegExp(r'[\u0980-\u09FF]').hasMatch(cleanText);
      final hasGujarati = RegExp(r'[\u0A80-\u0AFF]').hasMatch(cleanText);
      final hasKannada = RegExp(r'[\u0C80-\u0CFF]').hasMatch(cleanText);
      final hasMalayalam = RegExp(r'[\u0D00-\u0D7F]').hasMatch(cleanText);
      final hasUrdu = RegExp(r'[\u0600-\u06FF]').hasMatch(cleanText);

      if (hasHindi && !voiceToUse.locale.startsWith('hi')) {
        voiceToUse = _allVoices.firstWhere(
          (v) => v.shortName == 'hi-IN-SwaraNeural' || v.locale.startsWith('hi'),
          orElse: () => _selectedVoice,
        );
      } else if (hasTamil && !voiceToUse.locale.startsWith('ta')) {
        voiceToUse = _allVoices.firstWhere(
          (v) => v.shortName == 'ta-IN-PallaviNeural' || v.locale.startsWith('ta'),
          orElse: () => _selectedVoice,
        );
      } else if (hasTelugu && !voiceToUse.locale.startsWith('te')) {
        voiceToUse = _allVoices.firstWhere(
          (v) => v.shortName == 'te-IN-ShrutiNeural' || v.locale.startsWith('te'),
          orElse: () => _selectedVoice,
        );
      } else if (hasBengali && !voiceToUse.locale.startsWith('bn')) {
        voiceToUse = _allVoices.firstWhere(
          (v) => v.shortName == 'bn-IN-TanishaaNeural' || v.locale.startsWith('bn'),
          orElse: () => _selectedVoice,
        );
      } else if (hasGujarati && !voiceToUse.locale.startsWith('gu')) {
        voiceToUse = _allVoices.firstWhere(
          (v) => v.shortName == 'gu-IN-DhwaniNeural' || v.locale.startsWith('gu'),
          orElse: () => _selectedVoice,
        );
      } else if (hasKannada && !voiceToUse.locale.startsWith('kn')) {
        voiceToUse = _allVoices.firstWhere(
          (v) => v.shortName == 'kn-IN-SapnaNeural' || v.locale.startsWith('kn'),
          orElse: () => _selectedVoice,
        );
      } else if (hasMalayalam && !voiceToUse.locale.startsWith('ml')) {
        voiceToUse = _allVoices.firstWhere(
          (v) => v.shortName == 'ml-IN-SobhanaNeural' || v.locale.startsWith('ml'),
          orElse: () => _selectedVoice,
        );
      } else if (hasUrdu && !voiceToUse.locale.startsWith('ur')) {
        voiceToUse = _allVoices.firstWhere(
          (v) => v.shortName == 'ur-IN-GulNeural' || v.locale.startsWith('ur'),
          orElse: () => _selectedVoice,
        );
      }

      AudioGeneration? gen;

      // 1. Primary: High-fidelity Neural Synthesis via local engine
      try {
        gen = await _apiService.synthesize(
          text: cleanText,
          voice: voiceToUse,
          rate: _rate,
          pitch: _pitch,
          volume: _volume,
        );
      } catch (primaryErr) {
        debugPrint('Primary local synthesizer exception: $primaryErr. Using fallback...');
        // 2. Fallback: Universal direct stream synthesis
        try {
          gen = await UniversalTtsService.synthesizeUniversal(
            text: cleanText,
            voice: voiceToUse,
            rate: _rate,
            pitch: _pitch,
            volume: _volume,
          );
        } catch (fbErr) {
          debugPrint('Fallback synthesis exception: $fbErr');
          // 3. Fallback: Native device TTS
          gen = await _localTts.synthesizeLocalFile(
            text: cleanText,
            voice: voiceToUse,
            rate: _rate,
            pitch: _pitch,
            volume: _volume,
          );
        }
      }

      _currentAudio = gen;
      _history.insert(0, gen);
      if (_history.length > 50) {
        _history = _history.sublist(0, 50);
      }
      _saveHistory();
      _isGenerating = false;
      notifyListeners();
      return gen;
    } catch (e) {
      _isGenerating = false;
      _errorMessage = 'Speech conversion: $e';
      notifyListeners();
      return null;
    }
  }

  Future<void> pauseSpeaking() async {
    await _localTts.pause();
    _isSpeakingLocal = false;
    notifyListeners();
  }

  Future<void> stopSpeaking() async {
    await _localTts.stop();
    _isSpeakingLocal = false;
    notifyListeners();
  }

  Future<void> speakAgain(AudioGeneration audio) async {
    _isSpeakingLocal = true;
    notifyListeners();
    await _localTts.speakDirectly(
      text: audio.text,
      voice: _selectedVoice,
      rate: audio.rate,
      pitch: audio.pitch,
      volume: audio.volume,
    );
    _isSpeakingLocal = false;
    notifyListeners();
  }

  Future<String?> downloadAudio(AudioGeneration audio) async {
    try {
      if (audio.localSavedPath != null && audio.localSavedPath!.isNotEmpty) {
        return audio.localSavedPath;
      }
      final path = await _apiService.downloadAudioToDevice(audio);
      audio.localSavedPath = path;
      _saveHistory();
      notifyListeners();
      return path;
    } catch (e) {
      _errorMessage = 'Download: $e';
      notifyListeners();
      return null;
    }
  }

  void deleteFromHistory(String id) {
    _history.removeWhere((item) => item.id == id);
    if (_currentAudio?.id == id) {
      _currentAudio = _history.isNotEmpty ? _history.first : null;
    }
    _saveHistory();
    notifyListeners();
  }

  void clearAllHistory() {
    _history.clear();
    _currentAudio = null;
    _saveHistory();
    notifyListeners();
  }

  void setCurrentAudio(AudioGeneration audio) {
    _currentAudio = audio;
    notifyListeners();
  }

  Future<void> _saveHistory() async {
    final list = _history.map((a) => jsonEncode(a.toJson())).toList();
    await _prefs.setStringList(_prefKeyHistory, list);
  }
}
