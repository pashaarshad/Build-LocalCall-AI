import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/stt_provider.dart';
import '../providers/voice_provider.dart';
import 'voice_studio_screen.dart';

class TranscribeScreen extends StatefulWidget {
  const TranscribeScreen({super.key});

  @override
  State<TranscribeScreen> createState() => _TranscribeScreenState();
}

class _TranscribeScreenState extends State<TranscribeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sttProv = context.watch<SttProvider>();
    final voiceProv = context.watch<VoiceProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0F1D),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () {
            sttProv.stopListening();
            Navigator.of(context).pop();
          },
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Instant Audio to Text',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17,
                color: Colors.white,
              ),
            ),
            Text(
              'Real-Time Multilingual Speech Recognizer',
              style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
        actions: [
          if (sttProv.recognizedText.isNotEmpty)
            IconButton(
              tooltip: 'Clear Text',
              icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFF94A3B8)),
              onPressed: () => sttProv.clearText(),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Language selector bar
          _buildLanguageSelector(context, sttProv),

          // Main Transcription Canvas
          Expanded(
            child: _buildTranscriptionCanvas(context, sttProv),
          ),

          // Error banner if any
          if (sttProv.errorMessage != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.red.shade400.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      sttProv.errorMessage!,
                      style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

          // Action Toolbar (Copy, Convert to Voice, Send to LLM)
          if (sttProv.recognizedText.isNotEmpty)
            _buildActionToolbar(context, sttProv, voiceProv),

          // Glowing Interactive Microphone Button
          _buildMicrophoneSection(context, sttProv),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildLanguageSelector(BuildContext context, SttProvider sttProv) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select Recognition Language:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF94A3B8),
                  ),
                ),
                Text(
                  'Instant Millisecond Detection',
                  style: TextStyle(fontSize: 11, color: Color(0xFF22D3EE), fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: SttProvider.supportedLanguages.map((lang) {
                final isSelected = sttProv.selectedLanguage.id == lang.id;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    selected: isSelected,
                    showCheckmark: false,
                    avatar: Text(lang.flag),
                    label: Text('${lang.name} (${lang.nativeName})'),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : const Color(0xFFCBD5E1),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                    backgroundColor: const Color(0xFF131B2E),
                    selectedColor: const Color(0xFF4F46E5),
                    side: BorderSide(
                      color: isSelected ? const Color(0xFF6366F1) : const Color(0xFF1E293B),
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    onSelected: (_) => sttProv.selectLanguage(lang),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTranscriptionCanvas(BuildContext context, SttProvider sttProv) {
    final text = sttProv.recognizedText;
    final wordCount = text.trim().isEmpty ? 0 : text.trim().split(RegExp(r'\s+')).length;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF131B2E),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: sttProv.isListening
              ? const Color(0xFF06B6D4).withValues(alpha: 0.8)
              : const Color(0xFF1E293B),
          width: sttProv.isListening ? 1.5 : 1.0,
        ),
        boxShadow: sttProv.isListening
            ? [
                BoxShadow(
                  color: const Color(0xFF06B6D4).withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: sttProv.isListening ? const Color(0xFF10B981) : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    sttProv.isListening ? 'Listening in real-time...' : 'Transcript Output',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: sttProv.isListening ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
              Text(
                '${text.length} Chars | $wordCount Words',
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              ),
            ],
          ),
          const Divider(height: 24, color: Color(0xFF1E293B)),
          Expanded(
            child: SingleChildScrollView(
              child: text.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 40),
                        child: Column(
                          children: [
                            Icon(
                              Icons.mic_none_rounded,
                              size: 48,
                              color: const Color(0xFF6366F1).withValues(alpha: 0.4),
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'Tap the microphone below and speak',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Speak in ${sttProv.selectedLanguage.name} (${sttProv.selectedLanguage.nativeName}).\nYour words will be recognized instantly in milliseconds.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8), height: 1.4),
                            ),
                          ],
                        ),
                      ),
                    )
                  : SelectableText(
                      text,
                      style: const TextStyle(
                        fontSize: 18,
                        height: 1.6,
                        color: Colors.white,
                        letterSpacing: 0.2,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionToolbar(BuildContext context, SttProvider sttProv, VoiceProvider voiceProv) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Copy Text Button
          Expanded(
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                backgroundColor: const Color(0xFF131B2E),
                side: const BorderSide(color: Color(0xFF334155)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: sttProv.recognizedText));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.check_circle_rounded, color: Color(0xFF10B981)),
                          SizedBox(width: 8),
                          Text('Text copied to clipboard!'),
                        ],
                      ),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.copy_rounded, size: 18, color: Colors.white),
              label: const Text('Copy Text', style: TextStyle(color: Colors.white, fontSize: 13)),
            ),
          ),
          const SizedBox(width: 10),

          // Send to Voice Studio Button
          Expanded(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () {
                sttProv.stopListening();
                // Select an appropriate voice for the transcribed text
                final activeVoice = voiceProv.selectedVoice;
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => VoiceStudioScreen(
                      voice: activeVoice,
                      initialText: sttProv.recognizedText,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.auto_awesome_rounded, size: 18, color: Colors.white),
              label: const Text('Convert to Voice', style: TextStyle(color: Colors.white, fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMicrophoneSection(BuildContext context, SttProvider sttProv) {
    final isListening = sttProv.isListening;

    return Column(
      children: [
        GestureDetector(
          onTap: () => sttProv.toggleListening(),
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final scale = isListening ? (1.0 + (_pulseController.value * 0.15)) : 1.0;
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: isListening
                          ? [const Color(0xFFEF4444), const Color(0xFFF97316)]
                          : [const Color(0xFF6366F1), const Color(0xFF06B6D4)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isListening
                            ? const Color(0xFFEF4444).withValues(alpha: 0.45)
                            : const Color(0xFF6366F1).withValues(alpha: 0.35),
                        blurRadius: isListening ? 28 : 18,
                        spreadRadius: isListening ? 6 : 2,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                      color: Colors.white,
                      size: 38,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Text(
          isListening ? 'Listening... Tap to stop' : 'Tap Microphone to Speak',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isListening ? const Color(0xFFF87171) : const Color(0xFF94A3B8),
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}
