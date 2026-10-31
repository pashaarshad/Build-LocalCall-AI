import 'package:flutter_test/flutter_test.dart';
import 'package:local_voice_app/models/voice_model.dart';
import 'package:local_voice_app/models/audio_generation.dart';
import 'package:local_voice_app/services/api_service.dart';

void main() {
  test('VoiceModel parsing and helper tests', () {
    const voice = VoiceModel(
      shortName: 'en-IN-NeerjaExpressiveNeural',
      friendlyName: 'Neerja Expressive (English - India)',
      locale: 'en-IN',
      gender: 'Female',
      isIndian: true,
      tier: 'recommended',
      tag: 'Recommended (Ultra-Realistic)',
      description: 'Conversational Indian English',
      langDisplay: 'English (India)',
    );

    expect(voice.isIndian, true);
    expect(voice.isFemale, true);
    expect(voice.flagEmoji, '🇮🇳');
    expect(voice.simpleName.contains('Neerja'), true);
  });

  test('AudioGeneration serialization and sizing tests', () {
    final audio = AudioGeneration(
      id: 'test-123',
      text: 'Hello test speech',
      voiceShortName: 'hi-IN-SwaraNeural',
      voiceFriendlyName: 'Swara (Hindi)',
      langDisplay: 'Hindi (India)',
      timestamp: DateTime.now(),
      fileSize: 1024 * 50, // 50 KB
      audioUrl: 'http://127.0.0.1:8000/api/audio/test-123',
      downloadUrl: 'http://127.0.0.1:8000/api/download/test-123',
    );

    expect(audio.formattedFileSize, '50.0 KB');
    expect(audio.shortSummary, 'Hello test speech');

    final json = audio.toJson();
    final reconstructed = AudioGeneration.fromJson(json);
    expect(reconstructed.id, 'test-123');
    expect(reconstructed.voiceShortName, 'hi-IN-SwaraNeural');
  });

  test('Fallback curated voices list contains Indian and Global models', () {
    final voices = ApiService.defaultFallbackVoices();
    expect(voices.isNotEmpty, true);

    final indianVoices = voices.where((v) => v.isIndian).toList();
    expect(indianVoices.length >= 10, true);

    final neerja = voices.firstWhere((v) => v.shortName.contains('Neerja'));
    expect(neerja.isIndian, true);
  });
}
