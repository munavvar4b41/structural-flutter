import 'dart:async';

import 'package:flutter/material.dart';
import '../../models/task_show.dart';
import '../../services/app_controller.dart';
import '../../services/desktop_api_client.dart';
import '../../utils/duration_format.dart';
import '../../utils/task_minutes_format.dart';
import '../my_work/task_timer_actions.dart';
import 'task_form_sheet.dart';

class TaskDetailPage extends StatefulWidget {
  const TaskDetailPage({
    super.key,
    required this.controller,
    required this.projectId,
    required this.taskId,
  });

  final AppController controller;
  final int projectId;
  final int taskId;

  @override
  State<TaskDetailPage> createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends State<TaskDetailPage> {
  TaskShowPayload? _payload;
  bool _loading = true;
  bool _refreshing = false;
  String? _error;
  Timer? _tickTimer;

  @override
  void initState() {
    super.initState();
    widget.controller.tray.addListener(_onTrayChanged);
    _load();
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    widget.controller.tray.removeListener(_onTrayChanged);
    super.dispose();
  }

  void _onTrayChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    } else {
      setState(() => _refreshing = true);
    }

    try {
      final payload = await widget.controller.api.fetchTaskShow(
        projectId: widget.projectId,
        taskId: widget.taskId,
      );
      if (mounted) {
        setState(() {
          _payload = payload;
          _loading = false;
          _refreshing = false;
        });
      }
    } on DesktopApiException catch (e) {
      if (e.statusCode == 401) {
        await widget.controller.requireLogin();
        return;
      }
      if (mounted) {
        setState(() {
          _error = e.message;
          _loading = false;
          _refreshing = false;
        });
      }
    }
  }

  Future<void> _mutate(Future<TaskShowPayload> Function() action) async {
    try {
      final payload = await action();
      if (mounted) {
        setState(() => _payload = payload);
      }
    } on DesktopApiException catch (e) {
      if (e.statusCode == 401) {
        await widget.controller.requireLogin();
        return;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    }
  }

  Future<void> _editTask() async {
    final payload = _payload;
    if (payload == null) {
      return;
    }
    final saved = await TaskFormSheet.show(
      context,
      controller: widget.controller,
      projectId: widget.projectId,
      task: payload.task,
    );
    if (saved == true) {
      await _load(silent: true);
    }
  }

  Future<void> _deleteTask() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete task?'),
        content: Text('Delete "${_payload?.task.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }

    try {
      await widget.controller.api.deleteTask(
        projectId: widget.projectId,
        taskId: widget.taskId,
      );
      if (mounted) {
        Navigator.of(context).pop();
      }
    } on DesktopApiException catch (e) {
      if (e.statusCode == 401) {
        await widget.controller.requireLogin();
        return;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    }
  }

  Future<void> _confirmCompletion() async {
    final task = _payload?.task;
    if (task == null) {
      return;
    }

    int taskRating = 3;
    int? assigneeRating = task.assignee != null ? 3 : null;
    int creatorRating = 3;
    final notesController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Confirm completion'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _RatingField(
                  label: 'Task rating',
                  value: taskRating,
                  onChanged: (v) => setDialogState(() => taskRating = v),
                ),
                if (task.assignee != null)
                  _RatingField(
                    label: 'Assignee rating',
                    value: assigneeRating ?? 3,
                    onChanged: (v) => setDialogState(() => assigneeRating = v),
                  ),
                _RatingField(
                  label: 'Creator rating',
                  value: creatorRating,
                  onChanged: (v) => setDialogState(() => creatorRating = v),
                ),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(labelText: 'Review notes'),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirm'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) {
      notesController.dispose();
      return;
    }

    final reviewNotes = notesController.text.trim();
    notesController.dispose();

    await _mutate(
      () => widget.controller.api.confirmTaskCompletion(
        projectId: widget.projectId,
        taskId: widget.taskId,
        data: {
          'task_rating': taskRating,
          if (assigneeRating != null) 'assignee_rating': assigneeRating,
          'creator_rating': creatorRating,
          if (reviewNotes.isNotEmpty) 'review_notes': reviewNotes,
        },
      ),
    );
  }

  bool get _isActiveTimer {
    final active = widget.controller.tray.snapshot?.active;
    return active != null && active.taskId == widget.taskId;
  }

  String get _timerState {
    final active = widget.controller.tray.snapshot?.active;
    final isActive = active != null && active.taskId == widget.taskId;
    if (!isActive) {
      return 'idle';
    }
    return active.isPaused ? 'paused' : 'running';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_payload?.task.title ?? 'Task'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _refreshing ? null : () => _load(silent: true),
            icon: _refreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: _load,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final payload = _payload!;
    final task = payload.task;
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (task.canSubmitTaskCompletion)
              FilledButton(
                onPressed: () => _mutate(
                  () => widget.controller.api.submitTaskCompletion(
                    projectId: widget.projectId,
                    taskId: widget.taskId,
                  ),
                ),
                child: const Text('Submit for completion'),
              ),
            if (task.canConfirmTaskCompletion)
              FilledButton(
                onPressed: _confirmCompletion,
                child: const Text('Confirm completion'),
              ),
            if (payload.timeTracking.canTrack)
              TaskTimerActions(
                timerState: _timerState,
                isActive: _isActiveTimer,
                onView: () {},
                onStart: () => widget.controller.tray.startTask(
                  projectId: widget.projectId,
                  taskId: widget.taskId,
                ),
                onPause: () => widget.controller.tray.pauseTimer(),
                onResume: () => widget.controller.tray.resumeTimer(),
                onStop: () => widget.controller.tray.stopTimer(),
              ),
            if (task.canUpdate)
              OutlinedButton(
                onPressed: _editTask,
                child: const Text('Edit'),
              ),
            if (task.canDelete)
              OutlinedButton(
                onPressed: _deleteTask,
                style: OutlinedButton.styleFrom(
                  foregroundColor: scheme.error,
                ),
                child: const Text('Delete'),
              ),
            OutlinedButton(
              onPressed: () => TaskFormSheet.show(
                context,
                controller: widget.controller,
                projectId: widget.projectId,
                parentTaskId: task.id,
              ).then((saved) {
                if (saved == true) {
                  _load(silent: true);
                }
              }),
              child: const Text('Add subtask'),
            ),
          ],
        ),
        if (task.status == 'review') ...[
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Awaiting review',
            child: Text(
              'Submitted ${task.completionSubmittedAt ?? ''}'
              '${task.completionSubmittedBy != null ? ' by ${task.completionSubmittedBy!.name}' : ''}',
            ),
          ),
        ],
        const SizedBox(height: 16),
        _SectionCard(
          title: 'Details',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DetailRow(label: 'Status', value: task.statusLabel),
              _DetailRow(
                label: 'Assignee',
                value: task.assignee?.name ?? '—',
              ),
              _DetailRow(
                label: 'Estimate',
                value: task.estimatedMinutes != null
                    ? formatTaskMinutes(task.estimatedMinutes!)
                    : '—',
              ),
              if (payload.timeTracking.totals.remainingSeconds != null)
                _DetailRow(
                  label: 'Remaining',
                  value: formatElapsed(
                    Duration(
                      seconds: payload.timeTracking.totals.remainingSeconds!,
                    ),
                  ),
                ),
              if (task.requirementTitle != null)
                _DetailRow(label: 'Requirement', value: task.requirementTitle!),
              if (task.parent != null)
                _DetailRow(
                  label: 'Parent task',
                  value: task.parent!.title,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => TaskDetailPage(
                        controller: widget.controller,
                        projectId: widget.projectId,
                        taskId: task.parent!.id,
                      ),
                    ),
                  ),
                ),
              if (task.description != null && task.description!.isNotEmpty)
                _DetailRow(label: 'Description', value: task.description!),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _ChecklistSection(
          payload: payload,
          projectId: widget.projectId,
          taskId: widget.taskId,
          onMutate: _mutate,
          api: widget.controller.api,
        ),
        const SizedBox(height: 16),
        _TimeTrackingSection(
          payload: payload,
          projectId: widget.projectId,
          taskId: widget.taskId,
          onMutate: _mutate,
          api: widget.controller.api,
        ),
        if (task.subtasks.isNotEmpty) ...[
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Subtasks',
            child: Column(
              children: [
                for (final sub in task.subtasks)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(sub.title),
                    subtitle: Text(sub.statusLabel),
                    trailing: sub.canSubmitTaskCompletion
                        ? IconButton(
                            tooltip: 'Submit for completion',
                            icon: const Icon(Icons.check_circle_outline),
                            onPressed: () async {
                              try {
                                await widget.controller.api.submitTaskCompletion(
                                  projectId: widget.projectId,
                                  taskId: sub.id,
                                );
                                await _load(silent: true);
                              } on DesktopApiException catch (e) {
                                if (e.statusCode == 401) {
                                  await widget.controller.requireLogin();
                                  return;
                                }
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(e.message)),
                                  );
                                }
                              }
                            },
                          )
                        : null,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => TaskDetailPage(
                          controller: widget.controller,
                          projectId: widget.projectId,
                          taskId: sub.id,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final valueWidget = Text(value);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 2),
          onTap != null
              ? InkWell(
                  onTap: onTap,
                  child: Text(
                    value,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                )
              : valueWidget,
        ],
      ),
    );
  }
}

class _RatingField extends StatelessWidget {
  const _RatingField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<int>(
        value: value,
        decoration: InputDecoration(labelText: label),
        items: List.generate(
          5,
          (i) => DropdownMenuItem(value: i + 1, child: Text('${i + 1}')),
        ),
        onChanged: (v) {
          if (v != null) {
            onChanged(v);
          }
        },
      ),
    );
  }
}

class _ChecklistSection extends StatefulWidget {
  const _ChecklistSection({
    required this.payload,
    required this.projectId,
    required this.taskId,
    required this.onMutate,
    required this.api,
  });

  final TaskShowPayload payload;
  final int projectId;
  final int taskId;
  final Future<void> Function(Future<TaskShowPayload> Function()) onMutate;
  final DesktopApiClient api;

  @override
  State<_ChecklistSection> createState() => _ChecklistSectionState();
}

class _ChecklistSectionState extends State<_ChecklistSection> {
  final _newItemController = TextEditingController();

  @override
  void dispose() {
    _newItemController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final checklist = widget.payload.checklist;

    return _SectionCard(
      title: 'Checklist',
      child: Column(
        children: [
          for (final item in checklist.items)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: item.isCompleted,
              title: Text(item.title),
              onChanged: checklist.canManage
                  ? (v) => widget.onMutate(
                        () => widget.api.updateChecklistItem(
                          projectId: widget.projectId,
                          taskId: widget.taskId,
                          itemId: item.id,
                          data: {'is_completed': v ?? false},
                        ),
                      )
                  : null,
              secondary: checklist.canManage
                  ? IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => widget.onMutate(
                        () => widget.api.deleteChecklistItem(
                          projectId: widget.projectId,
                          taskId: widget.taskId,
                          itemId: item.id,
                        ),
                      ),
                    )
                  : null,
            ),
          if (checklist.canManage) ...[
            TextField(
              controller: _newItemController,
              decoration: const InputDecoration(
                labelText: 'Add checklist item',
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton(
                onPressed: () {
                  final title = _newItemController.text.trim();
                  if (title.isEmpty) {
                    return;
                  }
                  widget.onMutate(
                    () => widget.api.createChecklistItem(
                      projectId: widget.projectId,
                      taskId: widget.taskId,
                      title: title,
                    ),
                  ).then((_) {
                    _newItemController.clear();
                  });
                },
                child: const Text('Add item'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TimeTrackingSection extends StatelessWidget {
  const _TimeTrackingSection({
    required this.payload,
    required this.projectId,
    required this.taskId,
    required this.onMutate,
    required this.api,
  });

  final TaskShowPayload payload;
  final int projectId;
  final int taskId;
  final Future<void> Function(Future<TaskShowPayload> Function()) onMutate;
  final DesktopApiClient api;

  Future<void> _logManual(BuildContext context) async {
    final durationController = TextEditingController();
    final startController = TextEditingController();
    final endController = TextEditingController();
    final notesController = TextEditingController();
    var timeOnly = true;

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Log time'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: const Text('Duration only'),
                value: timeOnly,
                onChanged: (v) => setDialogState(() => timeOnly = v),
              ),
              if (timeOnly)
                TextField(
                  controller: durationController,
                  decoration: const InputDecoration(
                    labelText: 'Duration (minutes)',
                  ),
                  keyboardType: TextInputType.number,
                )
              else ...[
                TextField(
                  controller: startController,
                  decoration: const InputDecoration(
                    labelText: 'Start (YYYY-MM-DD HH:mm)',
                  ),
                ),
                TextField(
                  controller: endController,
                  decoration: const InputDecoration(
                    labelText: 'End (YYYY-MM-DD HH:mm)',
                  ),
                ),
              ],
              TextField(
                controller: notesController,
                decoration: const InputDecoration(labelText: 'Notes'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (saved != true) {
      durationController.dispose();
      startController.dispose();
      endController.dispose();
      notesController.dispose();
      return;
    }

    final data = <String, dynamic>{};
    if (timeOnly) {
      data['duration_minutes'] = int.parse(durationController.text.trim());
    } else {
      data['started_at'] = startController.text.trim();
      data['ended_at'] = endController.text.trim();
    }
    final notes = notesController.text.trim();
    if (notes.isNotEmpty) {
      data['notes'] = notes;
    }

    durationController.dispose();
    startController.dispose();
    endController.dispose();
    notesController.dispose();

    await onMutate(
      () => api.createTimeEntry(
        projectId: projectId,
        taskId: taskId,
        data: data,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tracking = payload.timeTracking;

    return _SectionCard(
      title: 'Time tracked',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Today: ${formatElapsed(Duration(seconds: tracking.totals.myTodaySeconds))} · '
            'My all-time: ${formatElapsed(Duration(seconds: tracking.totals.myAllTimeSeconds))} · '
            'Task all-time: ${formatElapsed(Duration(seconds: tracking.totals.taskAllTimeSeconds))}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          if (tracking.canTrack)
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton(
                onPressed: () => _logManual(context),
                child: const Text('Log time manually'),
              ),
            ),
          const SizedBox(height: 8),
          for (final entry in tracking.entries)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(entry.userName ?? 'User'),
              subtitle: Text(
                entry.durationSeconds != null
                    ? formatElapsed(Duration(seconds: entry.durationSeconds!))
                    : entry.startedAt ?? '',
              ),
              trailing: entry.canDelete
                  ? IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => onMutate(
                        () => api.deleteTimeEntry(
                          projectId: projectId,
                          taskId: taskId,
                          entryId: entry.id,
                        ),
                      ),
                    )
                  : null,
            ),
        ],
      ),
    );
  }
}
