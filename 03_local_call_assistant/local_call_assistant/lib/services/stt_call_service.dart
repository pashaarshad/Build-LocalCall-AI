import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';

class SttCallService {
  final SpeechToText _speech = SpeechToText();
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;
  bool get isListening => _speech.isListening;

  Future<bool> initialize({
    Function(String)? onStatus,
    Function(dynamic)? onError,
  }) async {
    if (_isInitialized) return true;

    try {
      _isInitialized = await _speech.initialize(
        onStatus: onStatus,
        onError: onError,
        debugLogging: kDebugMode,
      );
      return _isInitialized;
    } catch (e) {
      debugPrint('SttCallService init error: $e');
      return false;
    }
  }

  Future<void> startListening({
    required Function(String recognizedWords, bool isFinal) onResult,
    Function(double soundLevel)? onSoundLevel,
    String? localeId,
  }) async {
    if (!_isInitialized) {
      final ok = await initialize();
      if (!ok) return;
    }

    final options = SpeechListenOptions(
      listenMode: ListenMode.dictation,
      cancelOnError: false,
      partialResults: true,
      onDevice: true,
      localeId: localeId,
      pauseFor: const Duration(seconds: 3),
    );

    await _speech.listen(
      onResult: (result) {
        onResult(result.recognizedWords, result.finalResult);
      },
      onSoundLevelChange: onSoundLevel,
      listenOptions: options,
    );
  }

  Future<void> stopListening() async {
    if (_speech.isListening) {
      await _speech.stop();
    }
  }

  Future<void> cancelListening() async {
    if (_speech.isListening) {
      await _speech.cancel();
    }
  }
}
