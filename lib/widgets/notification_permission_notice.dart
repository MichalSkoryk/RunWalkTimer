import 'package:flutter/material.dart';

class NotificationPermissionNotice extends StatelessWidget {
  const NotificationPermissionNotice({required this.onOpenSettings, super.key});

  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      color: colors.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.notifications_off_outlined,
              color: colors.onErrorContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Background controls are hidden because notifications are '
                    'turned off.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.onErrorContainer,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: onOpenSettings,
                    style: TextButton.styleFrom(
                      foregroundColor: colors.onErrorContainer,
                      padding: EdgeInsets.zero,
                    ),
                    icon: const Icon(Icons.settings_outlined),
                    label: const Text('Open notification settings'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
