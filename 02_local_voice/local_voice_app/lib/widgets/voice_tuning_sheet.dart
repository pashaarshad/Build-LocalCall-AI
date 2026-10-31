import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/voice_provider.dart';

class VoiceTuningSheet extends StatelessWidget {
  const VoiceTuningSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final voiceProv = context.watch<VoiceProvider>();

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.tune_rounded, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Voice Parameter Tuning',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: () => voiceProv.resetTuning(),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Reset'),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Speed / Rate Slider
          _buildSliderSection(
            context: context,
            title: 'Speech Speed (Rate)',
            valueLabel: '${voiceProv.rate >= 0 ? '+' : ''}${voiceProv.rate}%',
            icon: Icons.speed_rounded,
            value: voiceProv.rate.toDouble(),
            min: -50,
            max: 100,
            divisions: 30,
            onChanged: (val) => voiceProv.setRate(val.round()),
            helperLeft: '0.5x Slow',
            helperRight: '2.0x Fast',
          ),
          const SizedBox(height: 16),

          // Pitch Slider
          _buildSliderSection(
            context: context,
            title: 'Voice Pitch',
            valueLabel: '${voiceProv.pitch >= 0 ? '+' : ''}${voiceProv.pitch} Hz',
            icon: Icons.graphic_eq_rounded,
            value: voiceProv.pitch.toDouble(),
            min: -50,
            max: 50,
            divisions: 20,
            onChanged: (val) => voiceProv.setPitch(val.round()),
            helperLeft: 'Deeper / Lower',
            helperRight: 'Higher / Lighter',
          ),
          const SizedBox(height: 16),

          // Volume Slider
          _buildSliderSection(
            context: context,
            title: 'Output Volume',
            valueLabel: '${voiceProv.volume >= 0 ? '+' : ''}${voiceProv.volume}%',
            icon: Icons.volume_up_rounded,
            value: voiceProv.volume.toDouble(),
            min: -50,
            max: 50,
            divisions: 20,
            onChanged: (val) => voiceProv.setVolume(val.round()),
            helperLeft: 'Softer',
            helperRight: 'Louder',
          ),
          const SizedBox(height: 20),

          // Presets row
          Text(
            'Quick Presets:',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ActionChip(
                label: const Text('Natural (Default)'),
                avatar: const Icon(Icons.check_circle_outline, size: 16),
                onPressed: () => voiceProv.resetTuning(),
              ),
              ActionChip(
                label: const Text('Fast Narration (+20%)'),
                avatar: const Icon(Icons.fast_forward, size: 16),
                onPressed: () {
                  voiceProv.setRate(20);
                  voiceProv.setPitch(0);
                },
              ),
              ActionChip(
                label: const Text('Calm & Slow (-15%)'),
                avatar: const Icon(Icons.slow_motion_video, size: 16),
                onPressed: () {
                  voiceProv.setRate(-15);
                  voiceProv.setPitch(-5);
                },
              ),
              ActionChip(
                label: const Text('Deep Voice (-15Hz)'),
                avatar: const Icon(Icons.record_voice_over, size: 16),
                onPressed: () {
                  voiceProv.setRate(0);
                  voiceProv.setPitch(-15);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSliderSection({
    required BuildContext context,
    required String title,
    required String valueLabel,
    required IconData icon,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
    required String helperLeft,
    required String helperRight,
  }) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                valueLabel,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          label: valueLabel,
          onChanged: onChanged,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                helperLeft,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
              Text(
                helperRight,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
