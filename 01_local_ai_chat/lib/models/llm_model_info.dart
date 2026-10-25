class LLMModelInfo {
  final String id;
  final String name;
  final String provider;
  final String badge;
  final String description;
  final bool isDefault;

  const LLMModelInfo({
    required this.id,
    required this.name,
    required this.provider,
    required this.badge,
    required this.description,
    this.isDefault = false,
  });

  static const List<LLMModelInfo> curatedModels = [
    LLMModelInfo(
      id: 'qwen/qwen3.8-27b',
      name: 'Qwen 3.8 (27B)',
      provider: 'Groq Cloud',
      badge: 'Recommended',
      description: 'Ultra-smart multilingual reasoning with blazing fast token streaming (500+ tok/s).',
      isDefault: true,
    ),
    LLMModelInfo(
      id: 'allam-2-7b',
      name: 'Allam 2 (7B)',
      provider: 'Groq Cloud',
      badge: 'Conversational',
      description: 'Exceptional dialogue comprehension with fluent bilingual English and Arabic support.',
    ),
    LLMModelInfo(
      id: 'openai/gpt-oss-20b',
      name: 'GPT-OSS (20B)',
      provider: 'Groq Cloud',
      badge: 'Ultra Fast',
      description: 'High-speed reasoning model tuned for rapid assistant tasks and instant turn-taking.',
    ),
  ];

  static LLMModelInfo findById(String id) {
    return curatedModels.firstWhere(
      (m) => m.id == id,
      orElse: () => LLMModelInfo(
        id: id,
        name: id.split('/').last.toUpperCase(),
        provider: 'Custom',
        badge: 'Custom',
        description: 'Custom model endpoint configured in settings.',
      ),
    );
  }
}
