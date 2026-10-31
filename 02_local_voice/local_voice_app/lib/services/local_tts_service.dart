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
  List<VoiceModel> _cachedDeviceVoices = [];

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

  Future<List<VoiceModel>> getDeviceVoices() async {
    await init();
    if (_cachedDeviceVoices.isNotEmpty) return _cachedDeviceVoices;

    try {
      final rawVoices = await _tts.getVoices;
      if (rawVoices is List && rawVoices.isNotEmpty) {
        final List<VoiceModel> list = [];
        for (final item in rawVoices) {
          if (item is Map) {
            final name = (item['name'] ?? item['voiceURI'] ?? '').toString();
            final locale = (item['locale'] ?? item['lang'] ?? '').toString();
            final isIndian = locale.contains('IN') ||
                locale.contains('hi') ||
                locale.contains('ta') ||
                locale.contains('te') ||
                locale.contains('kn') ||
                locale.contains('mr') ||
                locale.contains('gu') ||
                locale.contains('bn');

            final gender = name.toLowerCase().contains('female') ||
                    name.toLowerCase().contains('woman') ||
                    name.toLowerCase().contains('#female')
                ? 'Female'
                : 'Male';

            list.add(
              VoiceModel(
                shortName: name,
                friendlyName: '$name ($locale)',
                locale: locale,
                gender: gender,
                isIndian: isIndian,
                tier: isIndian ? 'indian' : 'standard',
                tag: 'Device On-Board TTS',
                description: '100% Offline Local Device Engine',
                langDisplay: locale,
              ),
            );
          }
        }

        if (list.isNotEmpty) {
          _cachedDeviceVoices = list;
          return list;
        }
      }
    } catch (e) {
      debugPrint('Failed to query device voices: $e');
    }

    _cachedDeviceVoices = [
      const VoiceModel(
        shortName: 'hi-IN-Local',
        friendlyName: 'Hindi (Swara - India)',
        locale: 'hi-IN',
        gender: 'Female',
        isIndian: true,
        tier: 'recommended',
        tag: 'Recommended (Ultra-Human)',
        description: 'Natural Hindi voice for conversation & announcements',
        langDisplay: 'Hindi (India)',
      ),
      const VoiceModel(
        shortName: 'en-IN-Local',
        friendlyName: 'Indian English (Neerja)',
        locale: 'en-IN',
        gender: 'Female',
        isIndian: true,
        tier: 'recommended',
        tag: 'Recommended (Expressive)',
        description: 'Articulate, conversational Indian English voice',
        langDisplay: 'English (India)',
      ),
      const VoiceModel(
        shortName: 'en-IN-Prabhat',
        friendlyName: 'Indian English (Prabhat)',
        locale: 'en-IN',
        gender: 'Male',
        isIndian: true,
        tier: 'recommended',
        tag: 'Recommended',
        description: 'Confident corporate male Indian English',
        langDisplay: 'English (India)',
      ),
      const VoiceModel(
        shortName: 'ta-IN-Local',
        friendlyName: 'Tamil (Pallavi)',
        locale: 'ta-IN',
        gender: 'Female',
        isIndian: true,
        tier: 'recommended',
        tag: 'Recommended',
        description: 'Fluent natural Tamil speaker',
        langDisplay: 'Tamil (India)',
      ),
      const VoiceModel(
        shortName: 'te-IN-Local',
        friendlyName: 'Telugu (Shruti)',
        locale: 'te-IN',
        gender: 'Female',
        isIndian: true,
        tier: 'recommended',
        tag: 'Recommended',
        description: 'Expressive female Telugu voice',
        langDisplay: 'Telugu (India)',
      ),
    ];
    return _cachedDeviceVoices;
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

    // Correctly map language code so Hindi, Tamil, Telugu pronounce accurately
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

    // Map rate (-50 to 100) to FlutterTts (0.2 to 1.0, default 0.5)
    final double flutterRate = (0.5 + (rate / 200.0)).clamp(0.1, 1.0);
    // Map pitch (-50 to 50) to FlutterTts (0.5 to 1.5, default 1.0)
    final double flutterPitch = (1.0 + (pitch / 100.0)).clamp(0.5, 2.0);
    // Map volume (-50 to 50) to FlutterTts (0.0 to 1.0, default 1.0)
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

    final double flutterRate = (0.5 + (rate / 200.0)).clamp(0.1, 1.0);
    final double flutterPitch = (1.0 + (pitch / 100.0)).clamp(0.5, 2.0);
    final double flutterVolume = (1.0 + (volume / 100.0)).clamp(0.1, 1.0);

    await _tts.setSpeechRate(flutterRate);
    await _tts.setPitch(flutterPitch);
    await _tts.setVolume(flutterVolume);

    final langCode = UniversalTtsService.detectLanguageCode(text, voice);
    try {
      if (langCode == 'hi') {
        await _tts.setLanguage('hi-IN');
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
      fileSize: 1024 * 35,
      audioUrl: filePath,
      downloadUrl: filePath,
      rate: rate,
      pitch: pitch,
      volume: volume,
      localSavedPath: filePath.isNotEmpty ? filePath : null,
    );
  }
}
