import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

class ConnectionBadge extends StatelessWidget {
  const ConnectionBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final theme = Theme.of(context);

    Color dotColor;
    String label;
    IconData? icon;

    switch (settings.connectionStatus) {
      case ConnectionStatus.connected:
        dotColor = Colors.greenAccent.shade700;
        label = 'Online';
        icon = Icons.cloud_done_rounded;
        break;
      case ConnectionStatus.testing:
        dotColor = Colors.amber;
        label = 'Testing...';
        icon = Icons.sync;
        break;
      case ConnectionStatus.failed:
      case ConnectionStatus.unknown:
        dotColor = Colors.orangeAccent;
        label = 'Offline / Standby';
        icon = Icons.cloud_off_rounded;
        break;
    }

    return Tooltip(
      message: '${settings.statusMessage}\nHost: ${settings.serverUrl}',
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => settings.testConnection(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: dotColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: dotColor.withOpacity(0.4), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: dotColor),
              const SizedBox(width: 4),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
