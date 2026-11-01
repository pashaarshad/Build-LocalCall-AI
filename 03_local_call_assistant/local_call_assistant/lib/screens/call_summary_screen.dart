import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/call_session.dart';
import '../providers/call_assistant_provider.dart';

class CallSummaryScreen extends StatelessWidget {
  final CallSession session;

  const CallSummaryScreen({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<CallAssistantProvider>();

    final urgencyColor = switch (session.urgency) {
      UrgencyLevel.high => const Color(0xFFEF4444),
      UrgencyLevel.medium => const Color(0xFFF59E0B),
      UrgencyLevel.low => const Color(0xFF10B981),
    };

    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0F1D),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Call Attendant Debrief',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.white),
        ),
        actions: [
          IconButton(
            tooltip: 'Forward to Telegram',
            icon: const Icon(Icons.send_rounded, color: Color(0xFF06B6D4)),
            onPressed: () async {
              final ok = await prov.telegramService.sendCallReport(session);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(ok ? 'Call report sent to Telegram!' : 'Could not send. Check Telegram settings.'),
                    backgroundColor: ok ? const Color(0xFF10B981) : Colors.redAccent,
                  ),
                );
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Caller & Urgency Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF131B2E),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: urgencyColor.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: urgencyColor.withValues(alpha: 0.2),
                    child: Icon(Icons.phone_in_talk_rounded, color: urgencyColor, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          session.callerName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${session.callerNumber} • ${session.formattedDuration}',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: urgencyColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      session.urgency.name.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: urgencyColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // AI Executive Summary
            _buildSectionHeader('AI Executive Summary', Icons.auto_awesome_rounded),
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 8, bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF131B2E),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFF1E293B)),
              ),
              child: Text(
                session.summary ?? 'No summary available.',
                style: const TextStyle(fontSize: 14, color: Colors.white, height: 1.5),
              ),
            ),

            // Action Items
            _buildSectionHeader('Action Items & Follow-ups', Icons.checklist_rounded),
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 8, bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF131B2E),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFF1E293B)),
              ),
              child: session.actionItems.isEmpty
                  ? const Text('No action items detected.', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: session.actionItems
                          .map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.check_circle_outline_rounded, size: 16, color: Color(0xFF22D3EE)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      item,
                                      style: const TextStyle(fontSize: 13, color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
            ),

            // Full Transcript
            _buildSectionHeader('Complete Conversation Transcript', Icons.subtitles_rounded),
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 8, bottom: 24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF131B2E),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFF1E293B)),
              ),
              child: session.turns.isEmpty
                  ? const Text('Transcript empty.', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13))
                  : Column(
                      children: session.turns.map((t) {
                        final isCaller = t.speaker == 'caller';
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isCaller ? '👤 Caller: ' : '🤖 AI: ',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: isCaller ? const Color(0xFF94A3B8) : const Color(0xFF22D3EE),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  t.text,
                                  style: const TextStyle(fontSize: 13, color: Colors.white, height: 1.4),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
            ),

            // Back to Dashboard Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Back to Dashboard',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF22D3EE)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Color(0xFFCBD5E1),
          ),
        ),
      ],
    );
  }
}
