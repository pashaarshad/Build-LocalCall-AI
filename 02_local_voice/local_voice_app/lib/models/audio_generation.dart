class AudioGeneration {
  final String id;
  final String text;
  final String voiceShortName;
  final String voiceFriendlyName;
  final String langDisplay;
  final DateTime timestamp;
  final int fileSize;
  final String audioUrl;
  final String downloadUrl;
  final int rate;
  final int pitch;
  final int volume;
  String? localSavedPath;

  AudioGeneration({
    required this.id,
    required this.text,
    required this.voiceShortName,
    required this.voiceFriendlyName,
    required this.langDisplay,
    required this.timestamp,
    required this.fileSize,
    required this.audioUrl,
    required this.downloadUrl,
    this.rate = 0,
    this.pitch = 0,
    this.volume = 0,
    this.localSavedPath,
  });

  factory AudioGeneration.fromJson(Map<String, dynamic> json) {
    return AudioGeneration(
      id: json['id'] ?? '',
      text: json['text'] ?? '',
      voiceShortName: json['voice_short_name'] ?? '',
      voiceFriendlyName: json['voice_friendly_name'] ?? '',
      langDisplay: json['lang_display'] ?? '',
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
      fileSize: json['file_size'] ?? 0,
      audioUrl: json['audio_url'] ?? '',
      downloadUrl: json['download_url'] ?? '',
      rate: json['rate'] ?? 0,
      pitch: json['pitch'] ?? 0,
      volume: json['volume'] ?? 0,
      localSavedPath: json['local_saved_path'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'voice_short_name': voiceShortName,
    'voice_friendly_name': voiceFriendlyName,
    'lang_display': langDisplay,
    'timestamp': timestamp.toIso8601String(),
    'file_size': fileSize,
    'audio_url': audioUrl,
    'download_url': downloadUrl,
    'rate': rate,
    'pitch': pitch,
    'volume': volume,
    'local_saved_path': localSavedPath,
  };

  String get formattedFileSize {
    if (fileSize <= 0) return '0 KB';
    final kb = fileSize / 1024;
    if (kb < 1024) {
      return '${kb.toStringAsFixed(1)} KB';
    }
    final mb = kb / 1024;
    return '${mb.toStringAsFixed(2)} MB';
  }

  String get shortSummary {
    if (text.length <= 60) return text;
    return '${text.substring(0, 57)}...';
  }
}
