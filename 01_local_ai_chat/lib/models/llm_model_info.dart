class LLMModelInfo {
  final String id;
  final String name;
  final String parameterSize;
  final String minRam;
  final String description;
  final bool isDefault;
  final bool isRecommendedForMobile;

  const LLMModelInfo({
    required this.id,
    required this.name,
    required this.parameterSize,
    required this.minRam,
    required this.description,
    this.isDefault = false,
    this.isRecommendedForMobile = true,
  });

  static const List<LLMModelInfo> curatedModels = [
    LLMModelInfo(
      id: 'qwen2.5:0.5b',
      name: 'Qwen 2.5 (0.5B Instruct)',
      parameterSize: '0.5 Billion',
      minRam: '1 GB RAM',
      description: 'Ultra-compact & lightning fast. Runs smoothly on all low-end & mid-range Android & iOS devices.',
      isDefault: true,
      isRecommendedForMobile: true,
    ),
    LLMModelInfo(
      id: 'qwen2.5:1.5b',
      name: 'Qwen 2.5 (1.5B Instruct)',
      parameterSize: '1.5 Billion',
      minRam: '2 GB RAM',
      description: 'The golden balance between high response speed and superior conversational reasoning.',
      isRecommendedForMobile: true,
    ),
    LLMModelInfo(
      id: 'qwen2.5:3b',
      name: 'Qwen 2.5 (3B Instruct)',
      parameterSize: '3 Billion',
      minRam: '4 GB RAM',
      description: 'Deep reasoning, multilingual fluency, and high contextual comprehension for modern smartphones.',
      isRecommendedForMobile: true,
    ),
    LLMModelInfo(
      id: 'llama3.2:1b',
      name: 'Llama 3.2 (1B Instruct)',
      parameterSize: '1 Billion',
      minRam: '1.5 GB RAM',
      description: "Meta's highly optimized lightweight mobile assistant model.",
      isRecommendedForMobile: true,
    ),
    LLMModelInfo(
      id: 'llama3.2:3b',
      name: 'Llama 3.2 (3B Instruct)',
      parameterSize: '3 Billion',
      minRam: '3.5 GB RAM',
      description: 'Advanced dialogue handling and structured information extraction.',
      isRecommendedForMobile: true,
    ),
    LLMModelInfo(
      id: 'custom',
      name: 'Custom Model ID',
      parameterSize: 'Variable',
      minRam: 'Custom',
      description: 'Connect to any custom model tag present on your local Ollama server.',
      isRecommendedForMobile: false,
    ),
  ];

  static LLMModelInfo findById(String id) {
    return curatedModels.firstWhere(
      (m) => m.id == id,
      orElse: () => LLMModelInfo(
        id: id,
        name: id,
        parameterSize: 'Custom',
        minRam: 'Varies',
        description: 'Custom model configured in settings.',
      ),
    );
  }
}
