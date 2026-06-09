import 'package:flutter/material.dart';

import '../../models/task_form_options.dart';
import '../../models/task_show.dart';
import '../../services/app_controller.dart';
import '../../services/desktop_api_client.dart';

class TaskFormSheet extends StatefulWidget {
  const TaskFormSheet({
    super.key,
    required this.controller,
    required this.projectId,
    this.task,
    this.parentTaskId,
  });

  final AppController controller;
  final int projectId;
  final TaskDetail? task;
  final int? parentTaskId;

  static Future<bool?> show(
    BuildContext context, {
    required AppController controller,
    required int projectId,
    TaskDetail? task,
    int? parentTaskId,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: TaskFormSheet(
          controller: controller,
          projectId: projectId,
          task: task,
          parentTaskId: parentTaskId,
        ),
      ),
    );
  }

  @override
  State<TaskFormSheet> createState() => _TaskFormSheetState();
}

class _TaskFormSheetState extends State<TaskFormSheet> {
  TaskFormOptions? _options;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _estimateController = TextEditingController();

  String? _status;
  int? _assigneeId;
  int? _requirementId;
  int? _parentId;
  int? _phase;
  DateTime? _displayAfter;
  DateTime? _notifyAt;

  bool get _isEdit => widget.task != null;
  bool get _limited => widget.task?.isAssigneeOnlyLimited ?? false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _estimateController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final options = await widget.controller.api.fetchTaskFormOptions(
        projectId: widget.projectId,
        excludeTaskId: widget.task?.id,
      );
      if (!mounted) {
        return;
      }

      final task = widget.task;
      setState(() {
        _options = options;
        _loading = false;
        if (task != null) {
          _titleController.text = task.title;
          _descriptionController.text = task.description ?? '';
          if (task.estimatedMinutes != null) {
            _estimateController.text = '${task.estimatedMinutes}';
          }
          _status = task.status;
          _assigneeId = task.assigneeUserId;
          _requirementId = task.projectRequirementId;
          _parentId = task.parentProjectTaskId;
          _phase = task.phase;
        } else {
          _status = options.statusOptions.firstOrNull?.value ?? 'to_do';
          _parentId = widget.parentTaskId;
        }
      });
    } on DesktopApiException catch (e) {
      if (e.statusCode == 401) {
        await widget.controller.requireLogin();
        return;
      }
      if (mounted) {
        setState(() {
          _error = e.message;
          _loading = false;
        });
      }
    }
  }

  Future<void> _save() async {
    if (_options == null) {
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final data = <String, dynamic>{};

    if (_limited && _isEdit) {
      data['status'] = _status;
      final estimate = int.tryParse(_estimateController.text.trim());
      if (estimate != null) {
        data['estimated_minutes'] = estimate;
      }
    } else {
      data['title'] = _titleController.text.trim();
      data['description'] = _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim();
      data['status'] = _status;
      data['assignee_user_id'] = _assigneeId;
      data['project_requirement_id'] = _requirementId;
      data['parent_project_task_id'] = _parentId;
      final estimate = int.tryParse(_estimateController.text.trim());
      if (estimate != null) {
        data['estimated_minutes'] = estimate;
      } else if (!_options!.project.estimationRequired) {
        data['estimated_minutes'] = null;
      }
      if (_requirementId != null && _phase != null) {
        data['phase'] = _phase;
      }
      if (_displayAfter != null) {
        data['display_after_at'] = _displayAfter!.toUtc().toIso8601String();
      }
      if (_notifyAt != null) {
        data['notify_at'] = _notifyAt!.toUtc().toIso8601String();
      }
    }

    try {
      if (_isEdit) {
        await widget.controller.api.updateTask(
          projectId: widget.projectId,
          taskId: widget.task!.id,
          data: data,
        );
      } else {
        await widget.controller.api.createTask(
          projectId: widget.projectId,
          data: data,
        );
      }
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } on DesktopApiException catch (e) {
      if (e.statusCode == 401) {
        await widget.controller.requireLogin();
        return;
      }
      if (mounted) {
        setState(() {
          _error = e.message;
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        height: 240,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final options = _options;
    if (options == null) {
      return SizedBox(
        height: 200,
        child: Center(child: Text(_error ?? 'Could not load form.')),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _isEdit ? 'Edit task' : 'New task',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          if (!_limited) ...[
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 4,
            ),
            const SizedBox(height: 12),
          ],
          DropdownButtonFormField<String>(
            value: _status,
            decoration: const InputDecoration(labelText: 'Status'),
            items: options.statusOptions
                .map(
                  (o) => DropdownMenuItem(value: o.value, child: Text(o.label)),
                )
                .toList(),
            onChanged: (v) => setState(() => _status = v),
          ),
          if (!_limited) ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<int?>(
              value: _assigneeId,
              decoration: const InputDecoration(labelText: 'Assignee'),
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('Unassigned'),
                ),
                ...options.assignableUsers.map(
                  (u) => DropdownMenuItem(
                    value: u.value,
                    child: Text(u.label, overflow: TextOverflow.ellipsis),
                  ),
                ),
              ],
              onChanged: (v) => setState(() => _assigneeId = v),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int?>(
              value: _requirementId,
              decoration: const InputDecoration(labelText: 'Requirement'),
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('None'),
                ),
                ...options.requirements.map(
                  (r) => DropdownMenuItem(
                    value: r.value,
                    child: Text(r.label, overflow: TextOverflow.ellipsis),
                  ),
                ),
              ],
              onChanged: (v) => setState(() {
                _requirementId = v;
                _phase = 1;
              }),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int?>(
              value: _parentId,
              decoration: const InputDecoration(labelText: 'Parent task'),
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('None'),
                ),
                ...options.parentTasks.map(
                  (p) => DropdownMenuItem(
                    value: p.value,
                    child: Text(
                      '${'— ' * p.treeDepth}${p.label}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
              onChanged: (v) => setState(() => _parentId = v),
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: _estimateController,
            decoration: InputDecoration(
              labelText: options.project.estimationRequired
                  ? 'Estimated minutes (required)'
                  : 'Estimated minutes',
            ),
            keyboardType: TextInputType.number,
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(_isEdit ? 'Save changes' : 'Create task'),
          ),
        ],
      ),
    );
  }
}
