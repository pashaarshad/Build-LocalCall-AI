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
  late TextEditingController _urlController;
  late TextEditingController _systemPromptController;

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
    _urlController = TextEditingController(text: settings.serverUrl);
    _systemPromptController =
        TextEditingController(text: settings.systemPrompt);
  }

  @override
  void dispose() {
    _urlController.dispose();
    _systemPromptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Local AI Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Section 0: Inference Mode & SQLite Storage Status
          Card(
            elevation: 0,
            color: theme.colorScheme.primaryContainer.withOpacity(0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: theme.colorScheme.primary.withOpacity(0.4),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.phone_android_rounded,
                          color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'AI Execution & Database Mode',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'SQLite on-device storage is active. All chats and context memory are kept 100% private in local_ai_chat.db on this phone.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<InferenceMode>(
                    segments: const [
                      ButtonSegment(
                        value: InferenceMode.onDevice,
                        label: Text('On-Device (Offline)'),
                        icon: Icon(Icons.bolt_rounded, size: 16),
                      ),
                      ButtonSegment(
                        value: InferenceMode.localNetwork,
                        label: Text('Local Network / Ollama'),
                        icon: Icon(Icons.wifi_rounded, size: 16),
                      ),
                    ],
                    selected: {settings.inferenceMode},
                    onSelectionChanged: (set) {
                      settings.setInferenceMode(set.first);
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),
          // Section 1: Server Connection
          Card(
            elevation: 0,
            color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: theme.colorScheme.outlineVariant.withOpacity(0.5),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.dns_rounded, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Ollama / Local LLM Server',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _urlController,
                    decoration: InputDecoration(
                      labelText: 'Server URL',
                      hintText: 'http://192.168.1.xxx:11434',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      isDense: true,
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.check_circle_outline),
                        onPressed: () {
                          settings.setServerUrl(_urlController.text.trim());
                        },
                      ),
                    ),
                    onSubmitted: (val) => settings.setServerUrl(val.trim()),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: [
                      ActionChip(
                        label: const Text('Emulator (10.0.2.2)'),
                        onPressed: () {
                          _urlController.text = 'http://10.0.2.2:11434';
                          settings.setServerUrl('http://10.0.2.2:11434');
                        },
                      ),
                      ActionChip(
                        label: const Text('Localhost (127.0.0.1)'),
                        onPressed: () {
                          _urlController.text = 'http://127.0.0.1:11434';
                          settings.setServerUrl('http://127.0.0.1:11434');
                        },
                      ),
                    ],
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

          // Section 2: Model Configuration
          Card(
            elevation: 0,
            color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: theme.colorScheme.outlineVariant.withOpacity(0.5),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.smart_toy_rounded,
                          color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Active Model',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: settings.selectedModel,
                    decoration: InputDecoration(
                      labelText: 'Model Selection',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      isDense: true,
                    ),
                    items: [
                      ...LLMModelInfo.curatedModels.map((m) {
                        return DropdownMenuItem(
                          value: m.id,
                          child: Text('${m.name} (${m.parameterSize})'),
                        );
                      }),
                      // Add any server-discovered models not in curated list
                      ...settings.availableServerModels
                          .where((name) =>
                              !LLMModelInfo.curatedModels.any((c) => c.id == name))
                          .map((name) => DropdownMenuItem(
                                value: name,
                                child: Text('Local Tag: $name'),
                              )),
                    ],
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

          // Section 3: Persona / System Prompt
          Card(
            elevation: 0,
            color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: theme.colorScheme.outlineVariant.withOpacity(0.5),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.psychology_rounded,
                          color: theme.colorScheme.primary),
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
                        selected:
                            settings.systemPrompt == entry.value,
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

          // Section 4: Generation Parameters
          Card(
            elevation: 0,
            color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: theme.colorScheme.outlineVariant.withOpacity(0.5),
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

          // Section 5: Setup Guide Card
          Card(
            color: theme.colorScheme.primaryContainer.withOpacity(0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: theme.colorScheme.primary.withOpacity(0.3),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Running Qwen 2.5 Locally',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'To connect your physical Android phone to Ollama on your computer:\n\n'
                    '1. Start Ollama with network binding:\n'
                    '   set OLLAMA_HOST=0.0.0.0:11434 (Windows CMD)\n'
                    r'   $env:OLLAMA_HOST="0.0.0.0:11434" (PowerShell)' '\n\n'
                    '2. Run Qwen 2.5 lightweight model:\n'
                    '   ollama run qwen2.5:0.5b\n\n'
                    '3. In this screen, enter your computer\'s Wi-Fi IP (e.g., http://192.168.1.15:11434).',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                      height: 1.4,
                    ),
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
