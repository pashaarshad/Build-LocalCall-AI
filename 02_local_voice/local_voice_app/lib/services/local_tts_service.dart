import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';
import '../models/voice_model.dart';
import '../models/audio_generation.dart';
import 'universal_tts_service.dart';

class LocalTtsService {
  final FlutterTts _tts = FlutterTts();
  bool _isInitialized = false;

  FlutterTts get tts => _tts;

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      await _tts.awaitSpeakCompletion(true);

      if (!kIsWeb) {
        try {
          if (Platform.isAndroid) {
            await _tts.setEngine('com.google.android.tts');
          }
        } catch (_) {}
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint('LocalTtsService init warning: $e');
    }
  }

  Future<void> speakDirectly({
    required String text,
    VoiceModel? voice,
    int rate = 0,    // -50 to 100
    int pitch = 0,   // -50 to 50
    int volume = 0,  // -50 to 50
  }) async {
    await init();
    await _tts.stop();

    final isMale = voice != null && !voice.isFemale;
    final langCode = UniversalTtsService.detectLanguageCode(
      text,
      voice ??
          const VoiceModel(
            shortName: 'en-IN',
            friendlyName: 'English',
            locale: 'en-IN',
            gender: 'Female',
            isIndian: true,
            tier: 'standard',
            tag: '',
            description: '',
            langDisplay: 'English',
          ),
    );

    // Speed calculation
    final double flutterRate = (0.5 + (rate / 200.0)).clamp(0.1, 1.0);

    // Pitch modulation: Male voices use deeper, lower resonant pitch (0.75-0.82), Female use natural pitch (1.0-1.1)
    double basePitch = isMale ? 0.78 : 1.05;
    final double flutterPitch = (basePitch + (pitch / 100.0)).clamp(0.5, 2.0);

    // Volume calculation
    final double flutterVolume = (1.0 + (volume / 100.0)).clamp(0.1, 1.0);

    await _tts.setSpeechRate(flutterRate);
    await _tts.setPitch(flutterPitch);
    await _tts.setVolume(flutterVolume);

    try {
      if (langCode == 'hi') {
        await _tts.setLanguage('hi-IN');
      } else if (langCode == 'ta') {
        await _tts.setLanguage('ta-IN');
      } else if (langCode == 'te') {
        await _tts.setLanguage('te-IN');
      } else if (langCode == 'bn') {
        await _tts.setLanguage('bn-IN');
      } else if (langCode == 'gu') {
        await _tts.setLanguage('gu-IN');
      } else if (langCode == 'kn') {
        await _tts.setLanguage('kn-IN');
      } else if (langCode == 'ml') {
        await _tts.setLanguage('ml-IN');
      } else if (langCode == 'mr') {
        await _tts.setLanguage('mr-IN');
      } else if (langCode == 'ur') {
        await _tts.setLanguage('ur-IN');
      } else {
        await _tts.setLanguage(voice?.locale.isNotEmpty == true ? voice!.locale : 'en-IN');
      }
    } catch (_) {}

    await _tts.speak(text);
  }

  Future<void> pause() async {
    await _tts.pause();
  }

  Future<void> stop() async {
    await _tts.stop();
  }

  Future<AudioGeneration> synthesizeLocalFile({
    required String text,
    required VoiceModel voice,
    int rate = 0,
    int pitch = 0,
    int volume = 0,
  }) async {
    await init();
    final audioId = DateTime.now().millisecondsSinceEpoch.toString();
    final fileName = 'LocalVoice_$audioId.wav';

    final isMale = !voice.isFemale;
    final double flutterRate = (0.5 + (rate / 200.0)).clamp(0.1, 1.0);
    final double basePitch = isMale ? 0.78 : 1.05;
    final double flutterPitch = (basePitch + (pitch / 100.0)).clamp(0.5, 2.0);
    final double flutterVolume = (1.0 + (volume / 100.0)).clamp(0.1, 1.0);

    await _tts.setSpeechRate(flutterRate);
    await _tts.setPitch(flutterPitch);
    await _tts.setVolume(flutterVolume);

    final langCode = UniversalTtsService.detectLanguageCode(text, voice);
    try {
      if (langCode == 'hi') {
        await _tts.setLanguage('hi-IN');
      } else if (langCode == 'ta') {
        await _tts.setLanguage('ta-IN');
      } else if (langCode == 'te') {
        await _tts.setLanguage('te-IN');
      } else if (langCode == 'bn') {
        await _tts.setLanguage('bn-IN');
      } else if (langCode == 'kn') {
        await _tts.setLanguage('kn-IN');
      } else {
        await _tts.setLanguage(voice.locale.isNotEmpty ? voice.locale : 'en-IN');
      }
    } catch (_) {}

    String filePath = '';
    if (!kIsWeb) {
      try {
        final dir = await getApplicationDocumentsDirectory();
        filePath = '${dir.path}/$fileName';
        await _tts.synthesizeToFile(text, fileName);
      } catch (_) {
        filePath = fileName;
      }
    }

    return AudioGeneration(
      id: audioId,
      text: text,
      voiceShortName: voice.shortName,
      voiceFriendlyName: voice.friendlyName,
      langDisplay: voice.langDisplay,
      timestamp: DateTime.now(),
      fileSize: 1024 * 48,
      audioUrl: filePath.isNotEmpty ? filePath : voice.sampleAssetPath,
      downloadUrl: filePath.isNotEmpty ? filePath : voice.sampleAssetPath,
      rate: rate,
      pitch: pitch,
      volume: volume,
      localSavedPath: filePath.isNotEmpty ? filePath : null,
    );
  }
}
