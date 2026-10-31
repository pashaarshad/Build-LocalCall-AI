import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/voice_model.dart';
import '../models/audio_generation.dart';
import 'download_helper.dart';

class ApiService {
  String _baseUrl;

  ApiService({String? initialBaseUrl})
      : _baseUrl = initialBaseUrl ?? defaultBaseUrl();

  static String defaultBaseUrl() {
    if (kIsWeb) return 'http://127.0.0.1:8000';
    try {
      if (Platform.isAndroid) {
        // Default emulator host; can be updated to Wi-Fi IP in settings
        return 'http://10.0.2.2:8000';
      }
    } catch (_) {}
    return 'http://127.0.0.1:8000';
  }

  String get baseUrl => _baseUrl;

  void updateBaseUrl(String url) {
    var clean = url.trim();
    if (clean.endsWith('/')) {
      clean = clean.substring(0, clean.length - 1);
    }
    if (!clean.startsWith('http://') && !clean.startsWith('https://')) {
      clean = 'http://$clean';
    }
    _baseUrl = clean;
  }

  Future<bool> checkHealth() async {
    try {
      final res = await http
          .get(Uri.parse('$_baseUrl/api/health'))
          .timeout(const Duration(seconds: 4));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<List<VoiceModel>> fetchVoices() async {
    try {
      final res = await http
          .get(Uri.parse('$_baseUrl/api/voices'))
          .timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        final list = (data['voices'] as List)
            .map((item) => VoiceModel.fromJson(item))
            .toList();
        return list;
      }
    } catch (e) {
      debugPrint('fetchVoices error: $e. Falling back to default list.');
    }
    return defaultFallbackVoices();
  }

  Future<AudioGeneration> synthesize({
    required String text,
    required VoiceModel voice,
    int rate = 0,
    int pitch = 0,
    int volume = 0,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/tts');
    final response = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'text': text,
            'voice': voice.shortName,
            'rate': rate,
            'pitch': pitch,
            'volume': volume,
          }),
        )
        .timeout(const Duration(seconds: 45));

    if (response.statusCode != 200) {
      final err = jsonDecode(response.body);
      throw Exception(err['detail'] ?? 'TTS synthesis failed (${response.statusCode})');
    }

    final data = jsonDecode(utf8.decode(response.bodyBytes));
    final audioId = data['audio_id'] as String;
    final fileSize = data['file_size'] as int? ?? 0;

    return AudioGeneration(
      id: audioId,
      text: text,
      voiceShortName: voice.shortName,
      voiceFriendlyName: voice.friendlyName,
      langDisplay: voice.langDisplay,
      timestamp: DateTime.now(),
      fileSize: fileSize,
      audioUrl: '$_baseUrl/api/audio/$audioId',
      downloadUrl: '$_baseUrl/api/download/$audioId',
      rate: rate,
      pitch: pitch,
      volume: volume,
    );
  }

  Future<String> downloadAudioToDevice(AudioGeneration audio) async {
    try {
      final safeId = audio.id.length > 8 ? audio.id.substring(0, 8) : audio.id;
      final filename = 'LocalCall_Voice_$safeId.mp3';
      return await downloadAudioFile(
        url: audio.downloadUrl.isNotEmpty ? audio.downloadUrl : audio.audioUrl,
        filename: filename,
      );
    } catch (e) {
      throw Exception('Failed to save audio: $e');
    }
  }

  static List<VoiceModel> defaultFallbackVoices() {
    return const [
      VoiceModel(
        shortName: 'en-IN-NeerjaExpressiveNeural',
        friendlyName: 'Neerja Expressive (English - India)',
        locale: 'en-IN',
        gender: 'Female',
        isIndian: true,
        tier: 'recommended',
        tag: 'Recommended (Ultra-Realistic)',
        description: 'Most expressive and natural conversational Indian English voice',
        langDisplay: 'English (India)',
      ),
      VoiceModel(
        shortName: 'hi-IN-SwaraNeural',
        friendlyName: 'Swara (Hindi - India)',
        locale: 'hi-IN',
        gender: 'Female',
        isIndian: true,
        tier: 'recommended',
        tag: 'Recommended (Expressive)',
        description: 'Warm, emotional, realistic female Hindi speaker',
        langDisplay: 'Hindi (India)',
      ),
      VoiceModel(
        shortName: 'en-IN-PrabhatNeural',
        friendlyName: 'Prabhat (English - India)',
        locale: 'en-IN',
        gender: 'Male',
        isIndian: true,
        tier: 'recommended',
        tag: 'Recommended',
        description: 'Calm, confident male corporate voice',
        langDisplay: 'English (India)',
      ),
      VoiceModel(
        shortName: 'hi-IN-MadhurNeural',
        friendlyName: 'Madhur (Hindi - India)',
        locale: 'hi-IN',
        gender: 'Male',
        isIndian: true,
        tier: 'recommended',
        tag: 'Recommended',
        description: 'Deep, authoritative, pleasant male Hindi speaker',
        langDisplay: 'Hindi (India)',
      ),
      VoiceModel(
        shortName: 'ta-IN-PallaviNeural',
        friendlyName: 'Pallavi (Tamil - India)',
        locale: 'ta-IN',
        gender: 'Female',
        isIndian: true,
        tier: 'recommended',
        tag: 'Recommended',
        description: 'Clear, natural female Tamil speaker',
        langDisplay: 'Tamil (India)',
      ),
      VoiceModel(
        shortName: 'ta-IN-ValluvarNeural',
        friendlyName: 'Valluvar (Tamil - India)',
        locale: 'ta-IN',
        gender: 'Male',
        isIndian: true,
        tier: 'recommended',
        tag: 'Recommended',
        description: 'Classic, articulate male Tamil voice',
        langDisplay: 'Tamil (India)',
      ),
      VoiceModel(
        shortName: 'te-IN-ShrutiNeural',
        friendlyName: 'Shruti (Telugu - India)',
        locale: 'te-IN',
        gender: 'Female',
        isIndian: true,
        tier: 'recommended',
        tag: 'Recommended',
        description: 'Friendly, fluid female Telugu speaker',
        langDisplay: 'Telugu (India)',
      ),
      VoiceModel(
        shortName: 'te-IN-MohanNeural',
        friendlyName: 'Mohan (Telugu - India)',
        locale: 'te-IN',
        gender: 'Male',
        isIndian: true,
        tier: 'recommended',
        tag: 'Recommended',
        description: 'Professional male Telugu voice',
        langDisplay: 'Telugu (India)',
      ),
      VoiceModel(
        shortName: 'kn-IN-SapnaNeural',
        friendlyName: 'Sapna (Kannada - India)',
        locale: 'kn-IN',
        gender: 'Female',
        isIndian: true,
        tier: 'recommended',
        tag: 'Recommended',
        description: 'Natural, expressive female Kannada voice',
        langDisplay: 'Kannada (India)',
      ),
      VoiceModel(
        shortName: 'kn-IN-GaganNeural',
        friendlyName: 'Gagan (Kannada - India)',
        locale: 'kn-IN',
        gender: 'Male',
        isIndian: true,
        tier: 'recommended',
        tag: 'Recommended',
        description: 'Clear male Kannada voice',
        langDisplay: 'Kannada (India)',
      ),
      VoiceModel(
        shortName: 'ml-IN-SobhanaNeural',
        friendlyName: 'Sobhana (Malayalam - India)',
        locale: 'ml-IN',
        gender: 'Female',
        isIndian: true,
        tier: 'recommended',
        tag: 'Recommended',
        description: 'Graceful female Malayalam speaker',
        langDisplay: 'Malayalam (India)',
      ),
      VoiceModel(
        shortName: 'mr-IN-AarohiNeural',
        friendlyName: 'Aarohi (Marathi - India)',
        locale: 'mr-IN',
        gender: 'Female',
        isIndian: true,
        tier: 'recommended',
        tag: 'Recommended',
        description: 'Polite female Marathi voice',
        langDisplay: 'Marathi (India)',
      ),
      VoiceModel(
        shortName: 'bn-IN-TanishaaNeural',
        friendlyName: 'Tanishaa (Bengali - India)',
        locale: 'bn-IN',
        gender: 'Female',
        isIndian: true,
        tier: 'recommended',
        tag: 'Recommended',
        description: 'Melodic female Bengali voice',
        langDisplay: 'Bengali (India)',
      ),
      VoiceModel(
        shortName: 'gu-IN-DhwaniNeural',
        friendlyName: 'Dhwani (Gujarati - India)',
        locale: 'gu-IN',
        gender: 'Female',
        isIndian: true,
        tier: 'recommended',
        tag: 'Recommended',
        description: 'Lively female Gujarati speaker',
        langDisplay: 'Gujarati (India)',
      ),
      VoiceModel(
        shortName: 'en-US-JennyMultilingualNeural',
        friendlyName: 'Jenny Multilingual (English - US)',
        locale: 'en-US',
        gender: 'Female',
        isIndian: false,
        tier: 'recommended',
        tag: 'Best Human (Multilingual)',
        description: 'Hollywood-grade conversational voice',
        langDisplay: 'English (US)',
      ),
      VoiceModel(
        shortName: 'en-US-GuyNeural',
        friendlyName: 'Guy (English - US)',
        locale: 'en-US',
        gender: 'Male',
        isIndian: false,
        tier: 'recommended',
        tag: 'Best Human',
        description: 'Dynamic, natural male conversationalist',
        langDisplay: 'English (US)',
      ),
    ];
  }
}
