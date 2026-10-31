import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/voice_provider.dart';

class ServerConfigDialog extends StatelessWidget {
  const ServerConfigDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (_) => const ServerConfigDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final voiceProv = context.watch<VoiceProvider>();

    return AlertDialog(
      backgroundColor: const Color(0xFF131B2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Row(
        children: [
          Icon(Icons.tune_rounded, color: Color(0xFF6366F1), size: 24),
          SizedBox(width: 10),
          Text(
            'Studio Settings & Info',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF10B981), width: 1),
              ),
              child: const Row(
                children: [
                  Icon(Icons.verified_rounded, color: Color(0xFF10B981), size: 22),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '100% Local Autonomous Voice Studio',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Feature Highlights
            const Text(
              '• All voice synthesis runs directly on your machine/device with zero external API dependencies or fees.',
              style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 8),
            const Text(
              '• Full native support for Hindi (हिंदी), Tamil, Telugu, Kannada, Bengali, Gujarati, Marathi, Urdu & Indian English.',
              style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 8),
            const Text(
              '• Mid-speech Pause & Resume: pause at any second and continue playback seamlessly.',
              style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 8),
            const Text(
              '• Tap the three dots (⋮) on any card to download the .mp3 file directly to your device storage.',
              style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 16),

            // Active Voice info
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Active Agent:', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                  Text(
                    voiceProv.selectedVoice.simpleName,
                    style: const TextStyle(color: Color(0xFF22D3EE), fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Saved audios count
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Saved Audios:', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                  Text(
                    '${voiceProv.history.length} recordings',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Reset Tuning Option
            if (voiceProv.rate != 0 || voiceProv.pitch != 0)
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFF59E0B),
                  side: const BorderSide(color: Color(0xFFF59E0B)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  voiceProv.resetTuning();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Voice tuning reset to defaults (0% speed, 0Hz pitch).')),
                  );
                },
                icon: const Icon(Icons.restart_alt_rounded, size: 18),
                label: const Text('Reset Pitch & Speed Tuning'),
              ),
          ],
        ),
      ),
      actions: [
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF6366F1),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
