class VoiceModel {
  final String shortName;
  final String friendlyName;
  final String locale;
  final String gender;
  final bool isIndian;
  final String tier;
  final String tag;
  final String description;
  final String langDisplay;

  const VoiceModel({
    required this.shortName,
    required this.friendlyName,
    required this.locale,
    required this.gender,
    required this.isIndian,
    required this.tier,
    required this.tag,
    required this.description,
    required this.langDisplay,
  });

  factory VoiceModel.fromJson(Map<String, dynamic> json) {
    return VoiceModel(
      shortName: json['short_name'] ?? '',
      friendlyName: json['friendly_name'] ?? json['short_name'] ?? '',
      locale: json['locale'] ?? '',
      gender: json['gender'] ?? 'Unknown',
      isIndian: json['is_indian'] ?? false,
      tier: json['tier'] ?? 'standard',
      tag: json['tag'] ?? 'Standard Neural',
      description: json['description'] ?? '',
      langDisplay: json['lang_display'] ?? json['locale'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'short_name': shortName,
    'friendly_name': friendlyName,
    'locale': locale,
    'gender': gender,
    'is_indian': isIndian,
    'tier': tier,
    'tag': tag,
    'description': description,
    'lang_display': langDisplay,
  };

  bool get isFemale => gender.toLowerCase().contains('female') || gender.toLowerCase().contains('woman');

  String get simpleName {
    final parts = shortName.split('-');
    if (parts.length >= 3) {
      final nameWithNeural = parts[2];
      final clean = nameWithNeural.replaceAll('Neural', '');
      return clean.replaceAll('Expressive', ' (Expressive)');
    }
    return shortName;
  }

  String get flagEmoji {
    if (isIndian) return '🇮🇳';
    if (locale.contains('US')) return '🇺🇸';
    if (locale.contains('GB')) return '🇬🇧';
    if (locale.contains('AU')) return '🇦🇺';
    if (locale.contains('CA')) return '🇨🇦';
    return '🌐';
  }

  String get sampleAssetPath {
    final s = shortName.toLowerCase();
    if (s.contains('swara')) return 'assets/samples/hi_swara.mp3';
    if (s.contains('madhur')) return 'assets/samples/hi_madhur.mp3';
    if (s.contains('neerja')) return 'assets/samples/en_in_neerja.mp3';
    if (s.contains('prabhat')) return 'assets/samples/en_in_prabhat.mp3';
    if (s.contains('pallavi')) return 'assets/samples/ta_pallavi.mp3';
    if (s.contains('valluvar')) return 'assets/samples/ta_valluvar.mp3';
    if (s.contains('shruti')) return 'assets/samples/te_shruti.mp3';
    if (s.contains('mohan')) return 'assets/samples/te_mohan.mp3';
    if (s.contains('sapna')) return 'assets/samples/kn_sapna.mp3';
    if (s.contains('gagan')) return 'assets/samples/kn_gagan.mp3';
    if (s.contains('tanishaa')) return 'assets/samples/bn_tanishaa.mp3';
    if (s.contains('bashkar')) return 'assets/samples/bn_bashkar.mp3';
    if (s.contains('dhwani')) return 'assets/samples/gu_dhwani.mp3';
    if (s.contains('aarohi')) return 'assets/samples/mr_aarohi.mp3';
    if (s.contains('gul')) return 'assets/samples/ur_gul.mp3';
    if (s.contains('jenny')) return 'assets/samples/en_us_jenny.mp3';
    if (s.contains('guy')) return 'assets/samples/en_us_guy.mp3';
    if (s.contains('sonia')) return 'assets/samples/en_gb_sonia.mp3';
    return isFemale ? 'assets/samples/hi_swara.mp3' : 'assets/samples/hi_madhur.mp3';
  }

  String get sampleTranscript {
    final s = shortName.toLowerCase();
    if (s.contains('swara')) return 'नमस्ते, मैं स्वरा हूँ। आपकी हिंदी वॉयस असिस्टेंट।';
    if (s.contains('madhur')) return 'नमस्कार, मैं मधुर हूँ। आपकी सेवा में तत्पर स्पष्ट हिंदी आवाज़।';
    if (s.contains('neerja')) return 'Hello, I am Neerja, your expressive Indian English voice assistant.';
    if (s.contains('prabhat')) return 'Hello, I am Prabhat, a confident male Indian English corporate voice.';
    if (s.contains('pallavi')) return 'வணக்கம், நான் பல்லவி. உங்கள் தமிழ் குரல் உதவியாளர்.';
    if (s.contains('valluvar')) return 'வணக்கம், நான் வள்ளுவர். தெளிவான ஆண் தமிழ் குரல்.';
    if (s.contains('shruti')) return 'నమస్కారం, నేను శృతి. మీ తెలుగు వాయిస్ అసిస్టెంట్.';
    if (s.contains('mohan')) return 'నమస్కారం, నేను మోహన్. స్పష్టమైన తెలుగు పురుష వాయిస్.';
    if (s.contains('sapna')) return 'ನಮಸ್ಕಾರ, ನಾನು ಸಪ್ನಾ. ನಿಮ್ಮ ಕನ್ನಡ ವಾಯ್ಸ್ ಅಸಿಸ್ಟೆಂಟ್.';
    if (s.contains('gagan')) return 'ನಮಸ್ಕಾರ, ನಾನು ಗಗನ್. ನಿಮ್ಮ ಕನ್ನಡ ವಾಯ್ಸ್.';
    if (s.contains('tanishaa')) return 'নমস্কার, আমি তানিশা। আপনার বাংলা ভয়েস অ্যাসিস্ট্যান্ট।';
    if (s.contains('bashkar')) return 'নমস্কার, আমি ভাস্কর। আপনার বাংলা পুরুষ ভয়েস।';
    if (s.contains('dhwani')) return 'નમસ્તે, હું ધ્વનિ છું. તમારી ગુજરાતી અવાજ સહાયક.';
    if (s.contains('aarohi')) return 'नमस्कार, मी आरोही आहे. तुमची मराठी व्हॉईस असिस्टंट.';
    if (s.contains('gul')) return 'السلام علیکم، میں گل ہوں۔ آپ کی اردو وائس اسسٹنٹ۔';
    if (s.contains('jenny')) return 'Hello! I am Jenny, a natural and friendly conversational voice.';
    if (s.contains('guy')) return 'Hey there! I am Guy, a warm and dynamic male voice.';
    if (s.contains('sonia')) return 'Hello, I am Sonia, a polished British English voice.';
    return 'Hello, this is a sample preview of this voice agent.';
  }
}
