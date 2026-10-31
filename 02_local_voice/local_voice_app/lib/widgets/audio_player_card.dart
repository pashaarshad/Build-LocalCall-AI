import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/audio_generation.dart';
import '../providers/audio_player_provider.dart';
import '../providers/voice_provider.dart';

class AudioPlayerCard extends StatefulWidget {
  final AudioGeneration audio;

  const AudioPlayerCard({super.key, required this.audio});

  @override
  State<AudioPlayerCard> createState() => _AudioPlayerCardState();
}

class _AudioPlayerCardState extends State<AudioPlayerCard> {
  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final playerProv = context.watch<AudioPlayerProvider>();
    final voiceProv = context.watch<VoiceProvider>();
    final audio = widget.audio;

    final isCurrentPlaying = playerProv.currentAudioUrl == audio.audioUrl;
    final isPlaying = isCurrentPlaying && playerProv.isPlaying;
    final duration = isCurrentPlaying ? playerProv.duration : Duration.zero;
    final position = isCurrentPlaying ? playerProv.position : Duration.zero;

    final progress = (duration.inMilliseconds > 0)
        ? (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF131B2E),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isPlaying
              ? const Color(0xFF6366F1).withValues(alpha: 0.6)
              : const Color(0xFF1E293B),
          width: 1.5,
        ),
        boxShadow: isPlaying
            ? [
                BoxShadow(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                  blurRadius: 18,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Voice Avatar + Info + Three Dots Menu
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF06B6D4)],
                  ),
                ),
                child: const Icon(
                  Icons.graphic_eq_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      audio.voiceFriendlyName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${audio.langDisplay} • ${audio.formattedFileSize}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),

              // Three Dots Menu with Download Option
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF94A3B8)),
                color: const Color(0xFF1E293B),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                onSelected: (value) async {
                  if (value == 'download') {
                    final scaffold = ScaffoldMessenger.of(context);
                    scaffold.showSnackBar(
                      const SnackBar(
                        content: Row(
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text('Downloading audio to your device...'),
                          ],
                        ),
                        duration: Duration(seconds: 2),
                      ),
                    );

                    final savedPath = await voiceProv.downloadAudio(audio);
                    if (savedPath != null) {
                      scaffold.showSnackBar(
                        SnackBar(
                          backgroundColor: const Color(0xFF059669),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          content: Row(
                            children: [
                              const Icon(Icons.check_circle_rounded, color: Colors.white),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Audio downloaded successfully!\nSaved: $savedPath',
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                          duration: const Duration(seconds: 4),
                        ),
                      );
                    }
                  } else if (value == 'copy') {
                    await Clipboard.setData(ClipboardData(text: audio.text));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Text copied to clipboard!'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    }
                  } else if (value == 'info') {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        backgroundColor: const Color(0xFF1E293B),
                        title: const Text('Audio Details', style: TextStyle(color: Colors.white)),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Voice Agent: ${audio.voiceFriendlyName}', style: const TextStyle(color: Colors.white)),
                            const SizedBox(height: 6),
                            Text('Language: ${audio.langDisplay}', style: const TextStyle(color: Color(0xFF94A3B8))),
                            const SizedBox(height: 6),
                            Text('Characters: ${audio.text.length}', style: const TextStyle(color: Color(0xFF94A3B8))),
                            const SizedBox(height: 6),
                            Text('File Size: ${audio.formattedFileSize}', style: const TextStyle(color: Color(0xFF94A3B8))),
                            if (audio.localSavedPath != null) ...[
                              const SizedBox(height: 6),
                              Text('Device Path: ${audio.localSavedPath}', style: const TextStyle(color: Color(0xFF22D3EE), fontSize: 11)),
                            ],
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    );
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'download',
                    child: Row(
                      children: [
                        Icon(Icons.download_rounded, color: Color(0xFF10B981)),
                        SizedBox(width: 12),
                        Text(
                          'Download Audio (.mp3)',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'copy',
                    child: Row(
                      children: [
                        Icon(Icons.copy_rounded, color: Colors.white70),
                        SizedBox(width: 12),
                        Text('Copy Text', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'info',
                    child: Row(
                      children: [
                        Icon(Icons.info_outline_rounded, color: Colors.white70),
                        SizedBox(width: 12),
                        Text('Audio Details', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Speech text snippet
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              audio.shortSummary,
              style: const TextStyle(
                fontStyle: FontStyle.italic,
                fontSize: 13,
                color: Color(0xFFCBD5E1),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 12),

          // Progress Scrubber Slider
          Column(
            children: [
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 4,
                  activeTrackColor: const Color(0xFF6366F1),
                  inactiveTrackColor: const Color(0xFF334155),
                  thumbColor: const Color(0xFF22D3EE),
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                ),
                child: Slider(
                  value: progress,
                  onChanged: (val) {
                    if (isCurrentPlaying && duration.inMilliseconds > 0) {
                      final targetMs = (val * duration.inMilliseconds).round();
                      playerProv.seek(Duration(milliseconds: targetMs));
                    }
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(position),
                      style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                    ),
                    Text(
                      _formatDuration(duration),
                      style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Playback Controls Row (Play, Pause, Resume, Rewind, FastForward, Speed, Download)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Speed selector button
              PopupMenuButton<double>(
                tooltip: 'Playback Speed',
                color: const Color(0xFF1E293B),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: Text(
                    '${playerProv.playbackSpeed}x',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
                onSelected: (speed) => playerProv.setSpeed(speed),
                itemBuilder: (context) => [0.75, 1.0, 1.25, 1.5, 2.0]
                    .map(
                      (s) => PopupMenuItem(
                        value: s,
                        child: Text('${s}x Speed', style: const TextStyle(color: Colors.white)),
                      ),
                    )
                    .toList(),
              ),

              // Main Audio Transport Controls
              Row(
                children: [
                  // Rewind 5 seconds
                  IconButton(
                    icon: const Icon(Icons.replay_5_rounded, color: Color(0xFF94A3B8)),
                    onPressed: isCurrentPlaying
                        ? () {
                            final target = position - const Duration(seconds: 5);
                            playerProv.seek(target < Duration.zero ? Duration.zero : target);
                          }
                        : null,
                  ),
                  const SizedBox(width: 4),

                  // Play / Pause Toggle Button
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: IconButton(
                      iconSize: 28,
                      color: Colors.white,
                      icon: playerProv.isLoading && isCurrentPlaying
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
                      onPressed: () {
                        if (isPlaying) {
                          // Pause mid-speech
                          playerProv.pause();
                        } else {
                          // Resume or Play cleanly
                          playerProv.play(audio.audioUrl);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 4),

                  // Forward 5 seconds
                  IconButton(
                    icon: const Icon(Icons.forward_5_rounded, color: Color(0xFF94A3B8)),
                    onPressed: isCurrentPlaying
                        ? () {
                            final target = position + const Duration(seconds: 5);
                            playerProv.seek(target > duration ? duration : target);
                          }
                        : null,
                  ),
                ],
              ),

              // 1-Tap Quick Download Button
              IconButton(
                tooltip: 'Download Audio File',
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  side: const BorderSide(color: Color(0xFF334155)),
                ),
                icon: const Icon(Icons.download_rounded, color: Color(0xFF10B981), size: 20),
                onPressed: () async {
                  final scaffold = ScaffoldMessenger.of(context);
                  scaffold.showSnackBar(
                    const SnackBar(
                      content: Text('Downloading audio to your device...'),
                      duration: Duration(seconds: 2),
                    ),
                  );

                  final savedPath = await voiceProv.downloadAudio(audio);
                  if (savedPath != null) {
                    scaffold.showSnackBar(
                      SnackBar(
                        backgroundColor: const Color(0xFF059669),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        content: Row(
                          children: [
                            const Icon(Icons.check_circle_rounded, color: Colors.white),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text('Downloaded: $savedPath'),
                            ),
                          ],
                        ),
                        duration: const Duration(seconds: 4),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

