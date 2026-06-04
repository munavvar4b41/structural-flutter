import 'package:flutter/material.dart';

import '../../models/my_work_board.dart';

class TaskTimerActions extends StatelessWidget {
  const TaskTimerActions({
    super.key,
    required this.task,
    required this.isActive,
    required this.onView,
    required this.onStart,
    required this.onPause,
    required this.onResume,
    required this.onStop,
  });

  final MyWorkTaskCard task;
  final bool isActive;
  final VoidCallback onView;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onStop;

  bool get _isRunning => isActive && task.timerState == 'running';

  bool get _isPaused => isActive && task.timerState == 'paused';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        _ActionButton(
          icon: Icons.visibility_outlined,
          tooltip: 'View task',
          onPressed: onView,
        ),
        const SizedBox(width: 4),
        if (_isRunning) ...[
          _ActionButton(
            icon: Icons.pause,
            tooltip: 'Pause timer',
            onPressed: onPause,
            color: scheme.primary,
          ),
          const SizedBox(width: 4),
          _ActionButton(
            icon: Icons.stop,
            tooltip: 'Stop timer',
            onPressed: onStop,
          ),
        ] else if (_isPaused) ...[
          _ActionButton(
            icon: Icons.play_arrow,
            tooltip: 'Resume timer',
            onPressed: onResume,
            color: scheme.primary,
          ),
          const SizedBox(width: 4),
          _ActionButton(
            icon: Icons.stop,
            tooltip: 'Stop timer',
            onPressed: onStop,
          ),
        ] else
          Expanded(
            child: _ActionButton(
              icon: Icons.play_arrow,
              tooltip: 'Start timer',
              onPressed: onStart,
              expanded: true,
            ),
          ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color,
    this.expanded = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color? color;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final button = IconButton(
      onPressed: onPressed,
      icon: Icon(icon, size: 20, color: color),
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      style: IconButton.styleFrom(
        minimumSize: const Size(36, 36),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );

    return button;
  }
}
