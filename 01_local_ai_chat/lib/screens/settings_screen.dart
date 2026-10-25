import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/llm_model_info.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _apiKeyController;
  late TextEditingController _systemPromptController;
  bool _obscureApiKey = true;

  final Map<String, String> _personaPresets = {
    'General Assistant':
        'You are LocalCall Assistant, a helpful, polite, and intelligent AI companion designed for mobile devices. Respond clearly, concisely, and accurately.',
    'Phone Screening Agent':
        'You are the autonomous AI phone agent for this device. A caller is reaching out because the owner is unavailable. Greet them warmly, state that you are an AI assistant taking a message, ask who is calling and the reason for their call, and reassure them that their message will be delivered with a structured summary.',
    'Meeting & Note Summarizer':
        'You are a business summarization assistant. Analyze notes or transcripts and generate: 1) Executive Summary, 2) Key Decisions, 3) Action Items with owners and deadlines.',
  };

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsProvider>();
    _apiKeyController = TextEditingController(text: settings.apiKey);
    _systemPromptController =
        TextEditingController(text: settings.systemPrompt);
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _systemPromptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI & API Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Section 1: Groq API Configuration
          Card(
            elevation: 0,
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.25),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: theme.colorScheme.primary.withValues(alpha: 0.35),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.bolt_rounded, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Groq AI Cloud Engine',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '100% Free API • Extreme Speed (500+ tok/s) • Multi-turn SQLite memory enabled.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _apiKeyController,
                    obscureText: _obscureApiKey,
                    decoration: InputDecoration(
                      labelText: 'Groq API Key',
                      hintText: 'gsk_...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      isDense: true,
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(_obscureApiKey
                                ? Icons.visibility_off
                                : Icons.visibility),
                            onPressed: () {
                              setState(() {
                                _obscureApiKey = !_obscureApiKey;
                              });
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.check_circle_outline),
                            onPressed: () {
                              settings.setApiKey(_apiKeyController.text.trim());
                            },
                          ),
                        ],
                      ),
                    ),
                    onSubmitted: (val) => settings.setApiKey(val.trim()),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      FilledButton.icon(
                        icon: settings.connectionStatus == ConnectionStatus.testing
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('Test Connection'),
                        onPressed: settings.connectionStatus ==
                                ConnectionStatus.testing
                            ? null
                            : () => settings.testConnection(),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          settings.statusMessage,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: settings.connectionStatus ==
                                    ConnectionStatus.connected
                                ? Colors.green
                                : Colors.orangeAccent,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Section 2: Active Model Picker
          Card(
            elevation: 0,
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.smart_toy_rounded, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Active AI Model',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: LLMModelInfo.curatedModels
                            .any((m) => m.id == settings.selectedModel)
                        ? settings.selectedModel
                        : LLMModelInfo.curatedModels.first.id,
                    decoration: InputDecoration(
                      labelText: 'Select Model',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      isDense: true,
                    ),
                    items: LLMModelInfo.curatedModels.map((m) {
                      return DropdownMenuItem(
                        value: m.id,
                        child: Text('${m.name} • ${m.badge}'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        settings.setSelectedModel(val);
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    settings.currentModelInfo.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Section 3: AI Persona & Role
          Card(
            elevation: 0,
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.psychology_rounded, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'AI Persona & Instructions',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: _personaPresets.entries.map((entry) {
                      return ChoiceChip(
                        label: Text(entry.key),
                        selected: settings.systemPrompt == entry.value,
                        onSelected: (selected) {
                          if (selected) {
                            _systemPromptController.text = entry.value;
                            settings.setSystemPrompt(entry.value);
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _systemPromptController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: 'Custom System Prompt',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (val) => settings.setSystemPrompt(val),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Section 4: Creativity / Temperature
          Card(
            elevation: 0,
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Creativity / Temperature: ${settings.temperature.toStringAsFixed(2)}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Slider(
                    value: settings.temperature,
                    min: 0.0,
                    max: 1.0,
                    divisions: 20,
                    label: settings.temperature.toStringAsFixed(2),
                    onChanged: (val) => settings.setTemperature(val),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Section 5: App & Privacy Info
          Card(
            elevation: 0,
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'LocalCall AI v1.0.0',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Conversations and context are stored locally on-device in encrypted SQLite storage. Inference powered by Groq Cloud API.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
