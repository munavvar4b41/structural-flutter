import 'package:flutter/material.dart';

import '../../services/app_controller.dart';
import '../notifications/notification_bell.dart';

class BoardHeading extends StatelessWidget implements PreferredSizeWidget {
  const BoardHeading({
    super.key,
    required this.controller,
    this.onRefresh,
    this.onSettings,
    this.onNewTask,
    this.refreshEnabled = true,
  });

  final AppController controller;
  final VoidCallback? onRefresh;
  final VoidCallback? onSettings;
  final VoidCallback? onNewTask;
  final bool refreshEnabled;

  @override
  Size get preferredSize => const Size.fromHeight(96);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Material(
      color: scheme.surface,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 8, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'My work',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Tasks assigned to you, grouped by status. Open a card to view details in the app.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (onNewTask != null)
                IconButton(
                  tooltip: 'New task',
                  onPressed: onNewTask,
                  icon: const Icon(Icons.add),
                ),
              NotificationBell(controller: controller),
              if (onRefresh != null)
                IconButton(
                  tooltip: 'Refresh',
                  onPressed: refreshEnabled ? onRefresh : null,
                  icon: const Icon(Icons.refresh),
                ),
              if (onSettings != null)
                IconButton(
                  tooltip: 'Settings',
                  onPressed: onSettings,
                  icon: const Icon(Icons.settings_outlined),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
