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

  bool get isFemale => gender.toLowerCase().contains('female');

  String get simpleName {
    // Extracts clean name from "en-IN-NeerjaExpressiveNeural" -> "Neerja (Expressive)"
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
    if (locale.contains('FR')) return '🇫🇷';
    if (locale.contains('DE')) return '🇩🇪';
    if (locale.contains('JP')) return '🇯🇵';
    if (locale.contains('CN')) return '🇨🇳';
    return '🌐';
  }
}
