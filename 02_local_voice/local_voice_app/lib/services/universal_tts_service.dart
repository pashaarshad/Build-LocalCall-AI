import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../models/voice_model.dart';
import '../models/audio_generation.dart';

class UniversalTtsService {
  static String detectLanguageCode(String text, VoiceModel voice) {
    // Check script by Unicode range
    final hasHindi = RegExp(r'[\u0900-\u097F]').hasMatch(text);
    if (hasHindi) return 'hi';

    final hasTamil = RegExp(r'[\u0B80-\u0BFF]').hasMatch(text);
    if (hasTamil) return 'ta';

    final hasTelugu = RegExp(r'[\u0C00-\u0C7F]').hasMatch(text);
    if (hasTelugu) return 'te';

    final hasBengali = RegExp(r'[\u0980-\u09FF]').hasMatch(text);
    if (hasBengali) return 'bn';

    final hasGujarati = RegExp(r'[\u0A80-\u0AFF]').hasMatch(text);
    if (hasGujarati) return 'gu';

    final hasKannada = RegExp(r'[\u0C80-\u0CFF]').hasMatch(text);
    if (hasKannada) return 'kn';

    final hasMalayalam = RegExp(r'[\u0D00-\u0D7F]').hasMatch(text);
    if (hasMalayalam) return 'ml';

    final hasUrdu = RegExp(r'[\u0600-\u06FF]').hasMatch(text);
    if (hasUrdu) return 'ur';

    // Check voice locale
    final loc = voice.locale.toLowerCase();
    if (loc.startsWith('hi')) return 'hi';
    if (loc.startsWith('ta')) return 'ta';
    if (loc.startsWith('te')) return 'te';
    if (loc.startsWith('bn')) return 'bn';
    if (loc.startsWith('gu')) return 'gu';
    if (loc.startsWith('kn')) return 'kn';
    if (loc.startsWith('ml')) return 'ml';
    if (loc.startsWith('mr')) return 'mr';
    if (loc.startsWith('ur')) return 'ur';
    if (loc.startsWith('en')) return 'en';

    return 'en';
  }

  static String getAudioStreamUrl(String text, String langCode) {
    final clean = text.trim();
    final encoded = Uri.encodeComponent(clean);
    return 'https://translate.google.com/translate_tts?ie=UTF-8&q=$encoded&tl=$langCode&client=tw-ob';
  }

  static Future<AudioGeneration> synthesizeUniversal({
    required String text,
    required VoiceModel voice,
    int rate = 0,
    int pitch = 0,
    int volume = 0,
    String? customServerUrl,
  }) async {
    final langCode = detectLanguageCode(text, voice);
    final audioId = DateTime.now().millisecondsSinceEpoch.toString();
    final streamUrl = getAudioStreamUrl(text, langCode);

    // If text is within standard single-call length (~200 chars), direct stream URL is instant
    if (text.length <= 250) {
      return AudioGeneration(
        id: audioId,
        text: text,
        voiceShortName: voice.shortName,
        voiceFriendlyName: voice.friendlyName,
        langDisplay: voice.langDisplay,
        timestamp: DateTime.now(),
        fileSize: text.length * 450,
        audioUrl: streamUrl,
        downloadUrl: streamUrl,
        rate: rate,
        pitch: pitch,
        volume: volume,
      );
    }

    // For longer / unlimited text: download chunks & merge locally into an MP3 file
    try {
      final chunks = _splitIntoSentences(text, 180);
      final List<int> combinedBytes = [];

      for (final chunk in chunks) {
        if (chunk.trim().isEmpty) continue;
        final url = getAudioStreamUrl(chunk, langCode);
        final res = await http.get(
          Uri.parse(url),
          headers: {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'},
        ).timeout(const Duration(seconds: 10));

        if (res.statusCode == 200 && res.bodyBytes.isNotEmpty) {
          combinedBytes.addAll(res.bodyBytes);
        }
      }

      String localFilePath = '';
      if (!kIsWeb && combinedBytes.isNotEmpty) {
        try {
          final dir = await getApplicationDocumentsDirectory();
          final file = File('${dir.path}/LocalVoice_$audioId.mp3');
          await file.writeAsBytes(combinedBytes);
          localFilePath = file.path;
        } catch (_) {}
      }

      return AudioGeneration(
        id: audioId,
        text: text,
        voiceShortName: voice.shortName,
        voiceFriendlyName: voice.friendlyName,
        langDisplay: voice.langDisplay,
        timestamp: DateTime.now(),
        fileSize: combinedBytes.isNotEmpty ? combinedBytes.length : text.length * 400,
        audioUrl: localFilePath.isNotEmpty ? localFilePath : streamUrl,
        downloadUrl: localFilePath.isNotEmpty ? localFilePath : streamUrl,
        rate: rate,
        pitch: pitch,
        volume: volume,
        localSavedPath: localFilePath.isNotEmpty ? localFilePath : null,
      );
    } catch (e) {
      debugPrint('Chunked synthesis fallback: $e');
      // Graceful fallback to single stream URL
      return AudioGeneration(
        id: audioId,
        text: text,
        voiceShortName: voice.shortName,
        voiceFriendlyName: voice.friendlyName,
        langDisplay: voice.langDisplay,
        timestamp: DateTime.now(),
        fileSize: text.length * 400,
        audioUrl: streamUrl,
        downloadUrl: streamUrl,
        rate: rate,
        pitch: pitch,
        volume: volume,
      );
    }
  }

  static List<String> _splitIntoSentences(String text, int maxChunkLen) {
    final List<String> chunks = [];
    final sentences = text.split(RegExp(r'(?<=[.!?|।\n])\s+'));
    var current = StringBuffer();

    for (final s in sentences) {
      if ((current.length + s.length) < maxChunkLen) {
        current.write('$s ');
      } else {
        if (current.isNotEmpty) {
          chunks.add(current.toString().trim());
          current = StringBuffer();
        }
        if (s.length >= maxChunkLen) {
          // Break oversized sentence by words
          final words = s.split(' ');
          for (final w in words) {
            if ((current.length + w.length) < maxChunkLen) {
              current.write('$w ');
            } else {
              chunks.add(current.toString().trim());
              current = StringBuffer();
              current.write('$w ');
            }
          }
        } else {
          current.write('$s ');
        }
      }
    }
    if (current.isNotEmpty) {
      chunks.add(current.toString().trim());
    }
    return chunks;
  }
}
