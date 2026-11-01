import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TtsCallService {
  final FlutterTts _tts = FlutterTts();
  bool _isSpeaking = false;

  bool get isSpeaking => _isSpeaking;

  Future<void> init({VoidCallback? onCompletion}) async {
    try {
      await _tts.awaitSpeakCompletion(true);
      await _tts.setSpeechRate(0.5);
      await _tts.setPitch(1.0);
      await _tts.setVolume(1.0);

      _tts.setCompletionHandler(() {
        _isSpeaking = false;
        onCompletion?.call();
      });

      _tts.setErrorHandler((msg) {
        debugPrint('TTS Error: $msg');
        _isSpeaking = false;
        onCompletion?.call();
      });
    } catch (e) {
      debugPrint('TtsCallService init error: $e');
    }
  }

  Future<void> setLanguage(String langCode) async {
    try {
      await _tts.setLanguage(langCode);
    } catch (e) {
      debugPrint('Set language error: $e');
    }
  }

  Future<void> speak(String text, {String? language}) async {
    if (text.trim().isEmpty) return;
    try {
      _isSpeaking = true;
      if (language != null) {
        await setLanguage(language);
      }
      await _tts.speak(text);
    } catch (e) {
      debugPrint('TtsCallService speak error: $e');
      _isSpeaking = false;
    }
  }

  Future<void> stop() async {
    try {
      _isSpeaking = false;
      await _tts.stop();
    } catch (e) {
      debugPrint('TtsCallService stop error: $e');
    }
  }
}
