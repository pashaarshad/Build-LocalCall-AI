import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/call_assistant_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _ownerNameController;
  late TextEditingController _groqKeyController;
  late TextEditingController _botTokenController;
  late TextEditingController _chatIdController;
  late bool _telegramEnabled;
  bool _testingTelegram = false;

  @override
  void initState() {
    super.initState();
    final prov = context.read<CallAssistantProvider>();
    _ownerNameController = TextEditingController(text: prov.llmService.ownerName);
    _groqKeyController = TextEditingController(text: prov.llmService.groqApiKey);
    _botTokenController = TextEditingController(text: prov.telegramService.botToken);
    _chatIdController = TextEditingController(text: prov.telegramService.chatId);
    _telegramEnabled = prov.telegramService.isEnabled;
  }

  @override
  void dispose() {
    _ownerNameController.dispose();
    _groqKeyController.dispose();
    _botTokenController.dispose();
    _chatIdController.dispose();
    super.dispose();
  }

  void _save(BuildContext context) {
    context.read<CallAssistantProvider>().updateSettings(
          ownerName: _ownerNameController.text.trim(),
          groqApiKey: _groqKeyController.text.trim(),
          telegramBotToken: _botTokenController.text.trim(),
          telegramChatId: _chatIdController.text.trim(),
          telegramEnabled: _telegramEnabled,
        );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings saved successfully!'),
        backgroundColor: Color(0xFF10B981),
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<CallAssistantProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0F1D),
        elevation: 0,
        title: const Text('Assistant Settings & APIs', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => _save(context),
            child: const Text('Save', style: TextStyle(color: Color(0xFF22D3EE), fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Persona
            _buildSectionCard(
              title: 'Owner Persona',
              icon: Icons.person_outline_rounded,
              children: [
                _buildTextField(
                  controller: _ownerNameController,
                  label: 'Owner Name',
                  hint: 'Arshad',
                  helper: 'The AI will tell callers who it is attending for.',
                ),
                const SizedBox(height: 12),
                const Text(
                  'Primary Call Attendant Language:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8)),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: prov.selectedLanguage,
                  dropdownColor: const Color(0xFF1E293B),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFF0A0F1D),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'kn_IN', child: Text('🇮🇳 Kannada (ಕನ್ನಡ)')),
                    DropdownMenuItem(value: 'en_IN', child: Text('🇮🇳 English (India)')),
                    DropdownMenuItem(value: 'hi_IN', child: Text('🇮🇳 Hindi (हिंदी)')),
                    DropdownMenuItem(value: 'ta_IN', child: Text('🇮🇳 Tamil (தமிழ்)')),
                    DropdownMenuItem(value: 'te_IN', child: Text('🇮🇳 Telugu (తెలుగు)')),
                  ],
                  onChanged: (val) {
                    if (val != null) prov.setLanguage(val);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Telegram Notification Integration
            _buildSectionCard(
              title: 'Telegram Voice & Call Alerts',
              icon: Icons.send_rounded,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        'Send Call Transcripts to Telegram',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                    Switch(
                      value: _telegramEnabled,
                      activeThumbColor: const Color(0xFF06B6D4),
                      onChanged: (val) => setState(() => _telegramEnabled = val),
                    ),
                  ],
                ),
                if (_telegramEnabled) ...[
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _botTokenController,
                    label: 'Telegram Bot Token',
                    hint: '123456789:ABCdefGhIJKlmNoPQRsTUVwxyZ',
                    helper: 'Create a free bot via @BotFather on Telegram',
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _chatIdController,
                    label: 'Telegram Chat ID',
                    hint: '123456789 or @channelname',
                    helper: 'Your personal Telegram User ID or Channel ID',
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF06B6D4)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _testingTelegram
                        ? null
                        : () async {
                            setState(() => _testingTelegram = true);
                            prov.telegramService.botToken = _botTokenController.text.trim();
                            final ok = await prov.telegramService.testConnection();
                            setState(() => _testingTelegram = false);

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(ok ? 'Telegram Bot connected successfully!' : 'Connection failed. Check token.'),
                                  backgroundColor: ok ? const Color(0xFF10B981) : Colors.redAccent,
                                ),
                              );
                            }
                          },
                    icon: _testingTelegram
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.check_circle_outline_rounded, size: 16, color: Color(0xFF06B6D4)),
                    label: const Text('Test Telegram Connection', style: TextStyle(color: Color(0xFF06B6D4), fontSize: 12)),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),

            // LLM Configuration
            _buildSectionCard(
              title: 'AI Intelligence & LLM Engine',
              icon: Icons.psychology_rounded,
              children: [
                _buildTextField(
                  controller: _groqKeyController,
                  label: 'Groq API Key (Ultra-Fast Cloud Fallback)',
                  hint: 'gsk_...',
                  helper: 'Optional: provides 200ms ultra-low latency response',
                ),
                const SizedBox(height: 12),
                const Text(
                  'Local Ollama URL: http://localhost:11434\n(Falls back to on-device rule engine if unreachable)',
                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B), height: 1.4),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF131B2E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: const Color(0xFF22D3EE)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
              ),
            ],
          ),
          const Divider(height: 20, color: Color(0xFF1E293B)),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String helper,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          style: const TextStyle(fontSize: 13, color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
            filled: true,
            fillColor: const Color(0xFF0A0F1D),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF1E293B))),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        const SizedBox(height: 4),
        Text(helper, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
      ],
    );
  }
}
