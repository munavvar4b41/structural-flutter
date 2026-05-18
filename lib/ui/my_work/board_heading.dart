import 'package:flutter/material.dart';

class BoardHeading extends StatelessWidget implements PreferredSizeWidget {
  const BoardHeading({
    super.key,
    this.onRefresh,
    this.onSettings,
    this.refreshEnabled = true,
  });

  final VoidCallback? onRefresh;
  final VoidCallback? onSettings;
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
                      'Tasks assigned to you, grouped by status. Click a card to open the task in your browser.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
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
