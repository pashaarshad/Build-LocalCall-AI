import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/voice_provider.dart';
import '../providers/audio_player_provider.dart';
import '../widgets/audio_player_card.dart';
import '../widgets/voice_selector_modal.dart';
import '../widgets/voice_tuning_sheet.dart';
import '../widgets/server_config_dialog.dart';
import 'history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _textController = TextEditingController(
    text:
        'नमस्ते, लोकल कॉल एआई में आपका स्वागत है। मैं आपकी बुद्धिमान वॉयस असिस्टेंट हूँ। आप आज क्या जानना चाहते हैं?',
  );

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  int get _wordCount {
    final t = _textController.text.trim();
    if (t.isEmpty) return 0;
    return t.split(RegExp(r'\s+')).length;
  }

  void _applySample(String sampleText) {
    setState(() {
      _textController.text = sampleText;
    });
  }

  @override
  Widget build(BuildContext context) {
    final voiceProv = context.watch<VoiceProvider>();
    final playerProv = context.watch<AudioPlayerProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0F1D),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF06B6D4)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.graphic_eq_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LocalCall Voice',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  'Neural Voice Agent Studio',
                  style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Tuning settings button
          IconButton(
            tooltip: 'Voice Tuning (Pitch & Speed)',
            icon: const Icon(Icons.tune_rounded, color: Color(0xFF94A3B8)),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const VoiceTuningSheet(),
              );
            },
          ),

          // History navigation button with badge
          Badge(
            isLabelVisible: voiceProv.history.isNotEmpty,
            label: Text('${voiceProv.history.length}'),
            backgroundColor: const Color(0xFF6366F1),
            child: IconButton(
              tooltip: 'Saved Audios',
              icon: const Icon(Icons.history_rounded, color: Color(0xFF94A3B8)),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const HistoryScreen()),
                );
              },
            ),
          ),

          // Settings & Info modal
          IconButton(
            tooltip: 'Studio Settings & Info',
            icon: const Icon(Icons.settings_outlined, color: Color(0xFF94A3B8)),
            onPressed: () => ServerConfigDialog.show(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Voice Selector Banner Card
            _buildVoiceSelectionCard(context),

            // Text Input Canvas
            _buildTextInputCard(context),

            // Sample Quick Script Chips
            _buildSampleScriptChips(context),

            // Convert to Voice Main Action
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    onPressed: voiceProv.isGenerating
                        ? null
                        : () async {
                            final audio = await voiceProv.convertTextToVoice(
                              _textController.text,
                            );
                            if (audio != null && mounted) {
                              // Play audio immediately
                              playerProv.play(audio.audioUrl);
                            }
                          },
                    icon: voiceProv.isGenerating
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.auto_awesome_rounded, color: Colors.white),
                    label: Text(
                      voiceProv.isGenerating
                          ? 'Generating Voice...'
                          : 'Convert to Voice',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Error display if any
            if (voiceProv.errorMessage != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.red.shade400.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: Colors.redAccent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        voiceProv.errorMessage!,
                        style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),

            // Ready Audio Output Card
            if (voiceProv.currentAudio != null) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF10B981),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Ready Audio Output',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const Text(
                      'Tap ⋮ to download',
                      style: TextStyle(fontSize: 12, color: Color(0xFF67E8F9)),
                    ),
                  ],
                ),
              ),
              AudioPlayerCard(audio: voiceProv.currentAudio!),
            ],

            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }

  Widget _buildVoiceSelectionCard(BuildContext context) {
    final voiceProv = context.watch<VoiceProvider>();
    final v = voiceProv.selectedVoice;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF131B2E),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFF1E293B),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF1E293B),
              border: Border.all(color: const Color(0xFF6366F1), width: 1.5),
            ),
            child: Center(
              child: Text(
                v.flagEmoji,
                style: const TextStyle(fontSize: 22),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        v.simpleName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      v.isFemale ? Icons.female : Icons.male,
                      size: 16,
                      color: v.isFemale ? const Color(0xFFF472B6) : const Color(0xFF60A5FA),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${v.langDisplay} • ${v.tag}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF22D3EE),
                  ),
                ),
                if (voiceProv.rate != 0 || voiceProv.pitch != 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      'Tuning: Speed ${voiceProv.rate > 0 ? "+" : ""}${voiceProv.rate}% | Pitch ${voiceProv.pitch > 0 ? "+" : ""}${voiceProv.pitch}Hz',
                      style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                    ),
                  ),
              ],
            ),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => VoiceSelectorModal.show(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: const Row(
                children: [
                  Text(
                    'Change',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Colors.white),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextInputCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF131B2E),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Enter Speech Text (Unlimited)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Color(0xFF94A3B8),
                ),
              ),
              if (_textController.text.isNotEmpty)
                InkWell(
                  onTap: () {
                    setState(() {
                      _textController.clear();
                    });
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      'Clear',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFFEF4444),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _textController,
            minLines: 5,
            maxLines: 12,
            style: const TextStyle(
              fontSize: 15,
              height: 1.5,
              color: Colors.white,
            ),
            decoration: const InputDecoration(
              hintText: 'Type or paste any text (English, Hindi, Tamil, Telugu, etc.)...',
              hintStyle: TextStyle(color: Color(0xFF64748B)),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: (_) => setState(() {}),
          ),
          const Divider(height: 20, color: Color(0xFF1E293B)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_textController.text.length} Characters  |  $_wordCount Words',
                style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              ),
              const Icon(Icons.edit_note_rounded, size: 18, color: Color(0xFF64748B)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSampleScriptChips(BuildContext context) {
    final voiceProv = context.read<VoiceProvider>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Script Presets:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ActionChip(
                  backgroundColor: const Color(0xFF131B2E),
                  side: const BorderSide(color: Color(0xFF334155)),
                  avatar: const Text('🇮🇳'),
                  label: const Text(
                    'Hindi Welcome',
                    style: TextStyle(color: Colors.white, fontSize: 13),
                  ),
                  onPressed: () {
                    // Automatically switch voice to Hindi Swara
                    final hindiVoice = voiceProv.allVoices.firstWhere(
                      (v) => v.locale.startsWith('hi') || v.shortName.contains('Swara') || v.shortName.contains('hi'),
                      orElse: () => voiceProv.selectedVoice,
                    );
                    voiceProv.selectVoice(hindiVoice);
                    _applySample(
                      'नमस्ते, लोकल कॉल एआई में आपका स्वागत है। मैं आपकी बुद्धिमान वॉयस असिस्टेंट हूँ। आप आज क्या जानना चाहते हैं?',
                    );
                  },
                ),
                const SizedBox(width: 8),
                ActionChip(
                  backgroundColor: const Color(0xFF131B2E),
                  side: const BorderSide(color: Color(0xFF334155)),
                  avatar: const Text('📞'),
                  label: const Text(
                    'Support Agent',
                    style: TextStyle(color: Colors.white, fontSize: 13),
                  ),
                  onPressed: () {
                    final enVoice = voiceProv.allVoices.firstWhere(
                      (v) => v.shortName.contains('Neerja'),
                      orElse: () => voiceProv.selectedVoice,
                    );
                    voiceProv.selectVoice(enVoice);
                    _applySample(
                      'Hello, thank you for contacting customer support. My name is Neerja. How may I assist you with your account today?',
                    );
                  },
                ),
                const SizedBox(width: 8),
                ActionChip(
                  backgroundColor: const Color(0xFF131B2E),
                  side: const BorderSide(color: Color(0xFF334155)),
                  avatar: const Text('📖'),
                  label: const Text(
                    'Story Narration',
                    style: TextStyle(color: Colors.white, fontSize: 13),
                  ),
                  onPressed: () {
                    _applySample(
                      'Once upon a time, atop the misty hills of the Western Ghats, a hidden stream flowed through ancient pine forests where wild elephants roamed beneath starry night skies.',
                    );
                  },
                ),
                const SizedBox(width: 8),
                ActionChip(
                  backgroundColor: const Color(0xFF131B2E),
                  side: const BorderSide(color: Color(0xFF334155)),
                  avatar: const Text('⚡'),
                  label: const Text(
                    'Tech Pitch',
                    style: TextStyle(color: Colors.white, fontSize: 13),
                  ),
                  onPressed: () {
                    _applySample(
                      'LocalCall AI provides autonomous on-device voice agents with zero-latency speech synthesis, crystal-clear audio, and complete local privacy.',
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

