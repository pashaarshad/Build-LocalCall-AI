import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/call_session.dart';
import '../providers/call_assistant_provider.dart';
import 'call_summary_screen.dart';

class ActiveCallScreen extends StatefulWidget {
  const ActiveCallScreen({super.key});

  @override
  State<ActiveCallScreen> createState() => _ActiveCallScreenState();
}

class _ActiveCallScreenState extends State<ActiveCallScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  Timer? _durationTimer;
  int _seconds = 0;
  final TextEditingController _testTextController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _seconds++);
      }
    });
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    _pulseController.dispose();
    _testTextController.dispose();
    super.dispose();
  }

  String _formatTimer(int s) {
    final m = s ~/ 60;
    final sec = s % 60;
    return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<CallAssistantProvider>();
    final call = prov.currentCall;

    if (call == null || call.status == CallStatus.ended) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && call != null) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => CallSummaryScreen(session: call)),
          );
        } else if (mounted) {
          Navigator.of(context).pop();
        }
      });
      return const Scaffold(
        backgroundColor: Color(0xFF0A0F1D),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF6366F1))),
      );
    }

    final isIncoming = call.status == CallStatus.incoming;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1D),
      body: SafeArea(
        child: Column(
          children: [
            // Top Header: Status & Timer
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF6366F1), width: 0.8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.shield_outlined, size: 14, color: Color(0xFF22D3EE)),
                        const SizedBox(width: 4),
                        Text(
                          isIncoming ? 'AUTO-ATTENDING' : 'CALL CONNECTED',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF22D3EE),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    isIncoming
                        ? 'Ringing (Ring ${prov.currentRingCount > 0 ? prov.currentRingCount : 1} of ${prov.ringsThreshold})...'
                        : _formatTimer(_seconds),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isIncoming ? const Color(0xFFF59E0B) : Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            // Caller Profile Section
            _buildCallerHeader(call, isIncoming),

            // Status Indicator Banner
            _buildTurnStatusBadge(prov.turnStatus),

            // Live Transcript Feed
            Expanded(
              child: _buildLiveTranscriptFeed(call, prov),
            ),

            // Real-Time Sound Waveform
            if (!isIncoming) _buildWaveform(prov),

            // Manual Test Input (For typing caller speech if on PC/testing)
            if (!isIncoming) _buildTestInputBar(prov),

            // Bottom Action Controls (End Call, Answer, Mute)
            _buildBottomControls(context, prov, isIncoming),
          ],
        ),
      ),
    );
  }

  Widget _buildCallerHeader(CallSession call, bool isIncoming) {
    return Column(
      children: [
        const SizedBox(height: 10),
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            final scale = isIncoming ? (1.0 + (_pulseController.value * 0.08)) : 1.0;
            return Transform.scale(
              scale: scale,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF06B6D4)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.4),
                      blurRadius: isIncoming ? 24 : 14,
                      spreadRadius: isIncoming ? 4 : 1,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(Icons.person_rounded, size: 38, color: Colors.white),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        Text(
          call.callerName,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          call.callerNumber,
          style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildTurnStatusBadge(TurnStatus status) {
    String text;
    Color color;
    IconData icon;

    switch (status) {
      case TurnStatus.listening:
        text = '🎙️ Listening to Caller in Milliseconds...';
        color = const Color(0xFF10B981);
        icon = Icons.graphic_eq_rounded;
      case TurnStatus.generating:
        text = '🧠 AI Understanding & Thinking...';
        color = const Color(0xFFF59E0B);
        icon = Icons.auto_awesome_rounded;
      case TurnStatus.speaking:
        text = '🔊 AI Assistant Speaking...';
        color = const Color(0xFF6366F1);
        icon = Icons.volume_up_rounded;
      case TurnStatus.idle:
        text = 'Connecting Call...';
        color = const Color(0xFF64748B);
        icon = Icons.phone_in_talk_rounded;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveTranscriptFeed(CallSession call, CallAssistantProvider prov) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF131B2E),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Live Call Transcript',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF94A3B8),
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                'Real-Time Multilingual',
                style: TextStyle(fontSize: 10, color: Color(0xFF22D3EE)),
              ),
            ],
          ),
          const Divider(height: 16, color: Color(0xFF1E293B)),
          Expanded(
            child: ListView.builder(
              reverse: false,
              itemCount: call.turns.length + (prov.liveCallerWords.isNotEmpty ? 1 : 0),
              itemBuilder: (context, index) {
                // Live streaming caller utterance
                if (index == call.turns.length && prov.liveCallerWords.isNotEmpty) {
                  return _buildTranscriptBubble(
                    speaker: 'caller',
                    text: prov.liveCallerWords,
                    isStreaming: true,
                  );
                }

                final turn = call.turns[index];
                return _buildTranscriptBubble(
                  speaker: turn.speaker,
                  text: turn.text,
                  isStreaming: false,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTranscriptBubble({
    required String speaker,
    required String text,
    required bool isStreaming,
  }) {
    final isCaller = speaker == 'caller';

    return Align(
      alignment: isCaller ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: isCaller
              ? const Color(0xFF1E293B)
              : const Color(0xFF4F46E5).withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(16),
          border: isStreaming
              ? Border.all(color: const Color(0xFF10B981), width: 1.2)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isCaller ? Icons.person_rounded : Icons.smart_toy_rounded,
                  size: 12,
                  color: isCaller ? const Color(0xFF94A3B8) : const Color(0xFF22D3EE),
                ),
                const SizedBox(width: 4),
                Text(
                  isCaller ? 'Caller' : 'AI Assistant',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isCaller ? const Color(0xFF94A3B8) : const Color(0xFF22D3EE),
                  ),
                ),
                if (isStreaming) ...[
                  const SizedBox(width: 6),
                  const Text('● live', style: TextStyle(color: Color(0xFF10B981), fontSize: 9)),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Text(
              text,
              style: const TextStyle(fontSize: 13, color: Colors.white, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaveform(CallAssistantProvider prov) {
    final level = prov.soundLevel;
    return Container(
      height: 24,
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(16, (i) {
          final barHeight = ((i % 4 + 1) * 5 * (level > 0.1 ? level : 0.2)).clamp(4.0, 24.0);
          return Container(
            width: 3,
            height: barHeight,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: prov.turnStatus == TurnStatus.speaking
                  ? const Color(0xFF6366F1)
                  : const Color(0xFF10B981),
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTestInputBar(CallAssistantProvider prov) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF131B2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _testTextController,
              style: const TextStyle(fontSize: 12, color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Type caller reply here (e.g. "I need an urgent meeting")...',
                hintStyle: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                border: InputBorder.none,
                isDense: true,
              ),
              onSubmitted: (text) {
                prov.submitTestCallerSpeech(text);
                _testTextController.clear();
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send_rounded, size: 18, color: Color(0xFF06B6D4)),
            onPressed: () {
              prov.submitTestCallerSpeech(_testTextController.text);
              _testTextController.clear();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls(BuildContext context, CallAssistantProvider prov, bool isIncoming) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: isIncoming
          ? Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Decline button
                _callActionButton(
                  icon: Icons.call_end_rounded,
                  color: const Color(0xFFEF4444),
                  label: 'Decline',
                  onTap: () => prov.endCall(),
                ),
                // Let AI Answer button
                _callActionButton(
                  icon: Icons.phone_in_talk_rounded,
                  color: const Color(0xFF10B981),
                  label: 'AI Answer Now',
                  onTap: () => prov.answerCall(),
                ),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _callActionButton(
                  icon: Icons.call_end_rounded,
                  color: const Color(0xFFEF4444),
                  label: 'End Call',
                  size: 64,
                  onTap: () => prov.endCall(),
                ),
              ],
            ),
    );
  }

  Widget _callActionButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
    double size = 56,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(size / 2),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: size * 0.5),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ],
    );
  }
}
