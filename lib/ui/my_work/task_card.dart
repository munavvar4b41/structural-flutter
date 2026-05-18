import 'package:flutter/material.dart';

import '../../models/my_work_board.dart';
import '../../utils/duration_format.dart';
import '../../utils/task_minutes_format.dart';

class TaskCardWidget extends StatelessWidget {
  const TaskCardWidget({
    super.key,
    required this.task,
    required this.isActive,
    required this.onOpenInBrowser,
  });

  final MyWorkTaskCard task;
  final bool isActive;
  final VoidCallback onOpenInBrowser;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final projectLabel = task.project.code != null && task.project.code!.isNotEmpty
        ? '${task.project.name} (${task.project.code})'
        : task.project.name;

    final timerLabel = switch (task.timerState) {
      'running' => 'Timer running',
      'paused' => 'Timer paused',
      _ => null,
    };

    return Material(
      color: scheme.surfaceContainerLowest,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isActive || task.timerState == 'running'
              ? scheme.primary
              : scheme.outlineVariant,
          width: isActive || task.timerState == 'running' ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: onOpenInBrowser,
        onDoubleTap: onOpenInBrowser,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          decoration: isActive || task.timerState == 'running'
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border(
                    left: BorderSide(color: scheme.primary, width: 3),
                  ),
                )
              : null,
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                task.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                projectLabel,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
              if (task.requirement != null) ...[
                const SizedBox(height: 4),
                Text(
                  task.requirement!.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              if (task.estimatedMinutes != null)
                Text(
                  'Est.: ${formatTaskMinutes(task.estimatedMinutes!)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              if (task.timerTodaySeconds > 0) ...[
                const SizedBox(height: 6),
                Text(
                  'Today: ${formatElapsed(Duration(seconds: task.timerTodaySeconds))}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontSize: 12,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
              if (timerLabel != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.timer_outlined, size: 14, color: scheme.primary),
                    const SizedBox(width: 4),
                    Text(
                      timerLabel,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
