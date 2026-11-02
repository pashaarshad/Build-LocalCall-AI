import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/call_session.dart';
import '../providers/call_assistant_provider.dart';
import 'active_call_screen.dart';
import 'call_summary_screen.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<CallAssistantProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0F1D),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF06B6D4)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.phone_in_talk_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LocalCall AI',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    letterSpacing: -0.2,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Autonomous Incoming Call Attendant',
                  style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Settings & Telegram API',
            icon: const Icon(Icons.settings_outlined, color: Color(0xFF94A3B8)),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Master Switch & Attendant Status Card
            _buildAttendantStatusCard(context, prov),

            // Mode Selector
            _buildModeSelector(context, prov),

            // Quick Call Simulator Launcher
            _buildSimulatorCard(context, prov),

            // Stats Row
            _buildStatsRow(context, prov),

            // Recent Attended Calls Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Attended Call Logs (${prov.history.length})',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFFCBD5E1),
                    ),
                  ),
                  if (prov.history.isNotEmpty)
                    InkWell(
                      onTap: () => prov.clearHistory(),
                      child: const Text(
                        'Clear',
                        style: TextStyle(fontSize: 12, color: Color(0xFFEF4444)),
                      ),
                    ),
                ],
              ),
            ),

            // Call History List
            _buildCallHistoryList(context, prov),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendantStatusCard(BuildContext context, CallAssistantProvider prov) {
    final isActive = prov.isAttendantActive;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: isActive
              ? [const Color(0xFF1E1B4B), const Color(0xFF0F172A)]
              : [const Color(0xFF1F2937), const Color(0xFF111827)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: isActive ? const Color(0xFF6366F1).withValues(alpha: 0.5) : const Color(0xFF374151),
        ),
        boxShadow: [
          BoxShadow(
            color: isActive ? const Color(0xFF6366F1).withValues(alpha: 0.2) : Colors.black26,
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
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
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isActive ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isActive ? 'ATTENDANT ACTIVE' : 'ATTENDANT PAUSED',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isActive ? const Color(0xFF34D399) : const Color(0xFF94A3B8),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Switch(
                value: isActive,
                activeThumbColor: const Color(0xFF06B6D4),
                activeTrackColor: const Color(0xFF6366F1),
                onChanged: (val) => prov.toggleAttendant(val),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isActive
                ? 'Your AI is Answering Calls'
                : 'Auto-Answer is Switched Off',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isActive
                ? 'Incoming phone calls will be auto-answered after ${prov.ringsThreshold} rings. The AI listens in milliseconds, maintains context, acknowledges caller names, and logs full debriefs.'
                : 'Turn on to let the AI attend your incoming phone calls while you are busy, driving, or in meetings.',
            style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8), height: 1.4),
          ),
          if (isActive) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF06B6D4).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF06B6D4).withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.ring_volume_rounded, size: 14, color: Color(0xFF22D3EE)),
                  const SizedBox(width: 6),
                  Text(
                    'Real Phone Call Trigger: Auto-Answer after ${prov.ringsThreshold} rings',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF22D3EE)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildModeSelector(BuildContext context, CallAssistantProvider prov) {
    final modes = [
      {'name': 'Do Not Disturb', 'icon': Icons.do_not_disturb_on_rounded},
      {'name': 'Meeting', 'icon': Icons.groups_rounded},
      {'name': 'Driving', 'icon': Icons.directions_car_rounded},
      {'name': 'Custom', 'icon': Icons.tune_rounded},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Assistant Scenario Mode:',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: modes.map((m) {
                final isSelected = prov.assistantMode == m['name'];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    selected: isSelected,
                    showCheckmark: false,
                    avatar: Icon(
                      m['icon'] as IconData,
                      size: 16,
                      color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                    ),
                    label: Text(m['name'] as String),
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
                    onSelected: (_) => prov.setMode(m['name'] as String),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimulatorCard(BuildContext context, CallAssistantProvider prov) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF131B2E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF06B6D4).withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.play_circle_outline_rounded, color: Color(0xFF22D3EE), size: 20),
              SizedBox(width: 8),
              Text(
                'Live Call Simulation Sandbox',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Test the complete STT ➔ LLM ➔ TTS loop right now on your screen. Tap below to trigger a test incoming call.',
            style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8), height: 1.4),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    prov.simulateIncomingCall(
                      callerName: 'Vijay Kumar (Client)',
                      callerNumber: '+91 98450 12345',
                    );
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ActiveCallScreen()),
                    );
                  },
                  icon: const Icon(Icons.call_received_rounded, size: 18, color: Colors.white),
                  label: const Text(
                    'Simulate Client Call',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF6366F1)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    prov.simulateIncomingCall(
                      callerName: 'Ramesh (Friend)',
                      callerNumber: '+91 99001 88776',
                    );
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ActiveCallScreen()),
                    );
                  },
                  icon: const Icon(Icons.phone_callback_rounded, size: 18, color: Color(0xFF6366F1)),
                  label: const Text(
                    'Simulate Friend Call',
                    style: TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context, CallAssistantProvider prov) {
    final totalCalls = prov.history.length;
    final urgentCalls = prov.history.where((c) => c.urgency == UrgencyLevel.high).length;
    final totalSeconds = prov.history.fold<int>(0, (sum, c) => sum + c.durationSeconds);
    final totalMinutes = (totalSeconds / 60).toStringAsFixed(1);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          _statBox('Calls Attended', '$totalCalls', const Color(0xFF6366F1)),
          const SizedBox(width: 10),
          _statBox('Minutes Saved', '$totalMinutes m', const Color(0xFF06B6D4)),
          const SizedBox(width: 10),
          _statBox('High Priority', '$urgentCalls', const Color(0xFFEF4444)),
        ],
      ),
    );
  }

  Widget _statBox(String label, String value, Color accentColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF131B2E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF1E293B)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: accentColor),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCallHistoryList(BuildContext context, CallAssistantProvider prov) {
    if (prov.history.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        padding: const EdgeInsets.all(32),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFF131B2E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF1E293B)),
        ),
        child: const Column(
          children: [
            Icon(Icons.phone_missed_rounded, size: 40, color: Color(0xFF64748B)),
            SizedBox(height: 10),
            Text(
              'No calls attended yet',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
            ),
            SizedBox(height: 4),
            Text(
              'Trigger a simulation above to test the AI Attendant.',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: prov.history.length,
      itemBuilder: (context, index) {
        final call = prov.history[index];
        final timeStr = DateFormat('h:mm a • d MMM').format(call.startTime);

        final badgeColor = switch (call.urgency) {
          UrgencyLevel.high => const Color(0xFFEF4444),
          UrgencyLevel.medium => const Color(0xFFF59E0B),
          UrgencyLevel.low => const Color(0xFF10B981),
        };

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF131B2E),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFF1E293B)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            leading: CircleAvatar(
              backgroundColor: badgeColor.withValues(alpha: 0.2),
              child: Icon(Icons.phone_in_talk_rounded, color: badgeColor, size: 20),
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  call.callerName,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                ),
                Text(
                  call.formattedDuration,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 2),
                Text(
                  call.callerNumber,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                if (call.summary != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    call.summary!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: Color(0xFFCBD5E1), height: 1.3),
                  ),
                ],
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(timeStr, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        call.urgency.name.toUpperCase(),
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: badgeColor),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => CallSummaryScreen(session: call)),
              );
            },
          ),
        );
      },
    );
  }
}
