import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/voice_model.dart';
import '../providers/voice_provider.dart';
import '../providers/audio_player_provider.dart';
import '../widgets/audio_player_card.dart';
import '../widgets/voice_tuning_sheet.dart';
import 'history_screen.dart';

class VoiceStudioScreen extends StatefulWidget {
  final VoiceModel voice;

  const VoiceStudioScreen({super.key, required this.voice});

  @override
  State<VoiceStudioScreen> createState() => _VoiceStudioScreenState();
}

class _VoiceStudioScreenState extends State<VoiceStudioScreen> {
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.voice.sampleTranscript);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VoiceProvider>().selectVoice(widget.voice);
    });
  }

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
    final activeVoice = voiceProv.selectedVoice;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0F1D),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () {
            playerProv.stop();
            Navigator.of(context).pop();
          },
        ),
        title: Row(
          children: [
            Text(
              activeVoice.flagEmoji,
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activeVoice.simpleName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${activeVoice.langDisplay} • ${activeVoice.gender}',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
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
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Voice Header Card
            _buildVoiceHeaderBanner(context, activeVoice, voiceProv),

            // Text Input Canvas
            _buildTextInputCard(context),

            // Quick Script Presets
            _buildQuickPresets(context, activeVoice),

            // Convert Button
            _buildConvertButton(context, voiceProv, playerProv),

            // Error display if any
            if (voiceProv.errorMessage != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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

            // Audio Player Section (Directly below generation)
            if (voiceProv.currentAudio != null) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF22D3EE),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Generated Audio',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
              AudioPlayerCard(audio: voiceProv.currentAudio!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVoiceHeaderBanner(BuildContext context, VoiceModel v, VoiceProvider voiceProv) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF131B2E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: v.isFemale
                    ? [const Color(0xFFEC4899), const Color(0xFF8B5CF6)]
                    : [const Color(0xFF3B82F6), const Color(0xFF06B6D4)],
              ),
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
                    Text(
                      v.simpleName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      v.isFemale ? Icons.female_rounded : Icons.male_rounded,
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
        ],
      ),
    );
  }

  Widget _buildTextInputCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                'Enter Text to Convert',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF94A3B8),
                  letterSpacing: 0.3,
                ),
              ),
              if (_textController.text.isNotEmpty)
                InkWell(
                  onTap: () => setState(() => _textController.clear()),
                  child: const Text(
                    'Clear',
                    style: TextStyle(color: Color(0xFFEF4444), fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
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
              hintText: 'Type or paste your text here (English, Hindi, Tamil, Telugu, etc.)...',
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

  Widget _buildQuickPresets(BuildContext context, VoiceModel v) {
    final isHindi = v.locale.startsWith('hi');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Script Presets:',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                if (isHindi) ...[
                  ActionChip(
                    backgroundColor: const Color(0xFF131B2E),
                    side: const BorderSide(color: Color(0xFF334155)),
                    avatar: const Text('🇮🇳'),
                    label: const Text('नमस्ते ग्रीटिंग', style: TextStyle(color: Colors.white, fontSize: 13)),
                    onPressed: () => _applySample(
                      'नमस्ते, लोकल कॉल एआई में आपका स्वागत है। मैं आपकी बुद्धिमान वॉयस असिस्टेंट हूँ। आप आज क्या जानना चाहते हैं?',
                    ),
                  ),
                  const SizedBox(width: 8),
                  ActionChip(
                    backgroundColor: const Color(0xFF131B2E),
                    side: const BorderSide(color: Color(0xFF334155)),
                    avatar: const Text('📢'),
                    label: const Text('घोषणा', style: TextStyle(color: Colors.white, fontSize: 13)),
                    onPressed: () => _applySample(
                      'कृपया ध्यान दें! आपकी ट्रेन समय पर प्लेटफार्म नंबर 2 पर आ रही है। धन्यवाद।',
                    ),
                  ),
                  const SizedBox(width: 8),
                ] else ...[
                  ActionChip(
                    backgroundColor: const Color(0xFF131B2E),
                    side: const BorderSide(color: Color(0xFF334155)),
                    avatar: const Text('📞'),
                    label: const Text('Support Agent', style: TextStyle(color: Colors.white, fontSize: 13)),
                    onPressed: () => _applySample(
                      'Hello! Thank you for calling our customer support. How may I assist you with your account today?',
                    ),
                  ),
                  const SizedBox(width: 8),
                  ActionChip(
                    backgroundColor: const Color(0xFF131B2E),
                    side: const BorderSide(color: Color(0xFF334155)),
                    avatar: const Text('📖'),
                    label: const Text('Storyteller', style: TextStyle(color: Colors.white, fontSize: 13)),
                    onPressed: () => _applySample(
                      'Once upon a time in a peaceful mountain valley, the morning mist slowly lifted to reveal an enchanted ancient city.',
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                ActionChip(
                  backgroundColor: const Color(0xFF131B2E),
                  side: const BorderSide(color: Color(0xFF334155)),
                  avatar: const Text('🚀'),
                  label: const Text('Product Pitch', style: TextStyle(color: Colors.white, fontSize: 13)),
                  onPressed: () => _applySample(
                    'Welcome to the next generation of voice intelligence. Ultra-fast, completely private, and powered by advanced on-device AI.',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConvertButton(BuildContext context, VoiceProvider voiceProv, AudioPlayerProvider playerProv) {
    return Padding(
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
            onPressed: voiceProv.isGenerating
                ? null
                : () async {
                    // Stop any sample playing before converting
                    await playerProv.stop();

                    final audio = await voiceProv.convertTextToVoice(_textController.text);
                    if (audio != null && mounted) {
                      // Play once cleanly via AudioPlayerProvider
                      await playerProv.play(audio.audioUrl);
                    }
                  },
            icon: voiceProv.isGenerating
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                  )
                : const Icon(Icons.auto_awesome_rounded, color: Colors.white),
            label: Text(
              voiceProv.isGenerating ? 'Generating Voice...' : 'Convert to Voice',
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
    );
  }
}
