import 'package:flutter/material.dart';

import '../../models/my_work_board.dart';
import '../../utils/duration_format.dart';
import '../../utils/task_minutes_format.dart';
import 'task_timer_actions.dart';

class TaskCardWidget extends StatelessWidget {
  const TaskCardWidget({
    super.key,
    required this.task,
    required this.isActive,
    required this.statusOptions,
    required this.onView,
    required this.onStatusChange,
    required this.onSubmitCompletion,
    required this.onStart,
    required this.onPause,
    required this.onResume,
    required this.onStop,
  });

  final MyWorkTaskCard task;
  final bool isActive;
  final List<StatusOption> statusOptions;
  final VoidCallback onView;
  final ValueChanged<String> onStatusChange;
  final VoidCallback? onSubmitCompletion;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onStop;

  bool get _timerHighlighted =>
      isActive || task.timerState == 'running' || task.timerState == 'paused';

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
          color: _timerHighlighted ? scheme.primary : scheme.outlineVariant,
          width: _timerHighlighted ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: onView,
            onDoubleTap: onView,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            child: Container(
              decoration: _timerHighlighted
                  ? BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(10),
                      ),
                      border: Border(
                        left: BorderSide(color: scheme.primary, width: 3),
                      ),
                    )
                  : null,
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
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
                      'Est.: ${formatTaskMinutes(task.estimatedMinutes!)}'
                      '${task.childrenCount > 0 ? ' · ${task.childrenCount} subtasks' : ''}',
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
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<String>(
                  value: task.status,
                  isDense: true,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 8),
                  ),
                  items: statusOptions
                      .map(
                        (o) => DropdownMenuItem(
                          value: o.value,
                          child: Text(o.label, style: const TextStyle(fontSize: 12)),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null && v != task.status) {
                      onStatusChange(v);
                    }
                  },
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (task.canSubmitTaskCompletion && onSubmitCompletion != null)
                      IconButton(
                        tooltip: 'Submit for completion',
                        onPressed: onSubmitCompletion,
                        icon: const Icon(Icons.check_circle_outline, size: 20),
                      ),
                    Expanded(
                      child: TaskTimerActions(
                        task: task,
                        isActive: isActive,
                        onView: onView,
                        onStart: onStart,
                        onPause: onPause,
                        onResume: onResume,
                        onStop: onStop,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
