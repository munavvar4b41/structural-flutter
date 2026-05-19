import '../utils/json_parse.dart';

Map<String, dynamic> _map(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  return {};
}

class TraySnapshot {
  TraySnapshot({required this.active, required this.pendingTasks});

  factory TraySnapshot.fromJson(Map<String, dynamic> json) {
    final activeJson = json['active'];
    return TraySnapshot(
      active: activeJson == null
          ? null
          : ActiveTrayEntry.fromJson(_map(activeJson)),
      pendingTasks: (json['pending_tasks'] as List<dynamic>? ?? [])
          .map((e) => PendingTrayTask.fromJson(_map(e)))
          .toList(),
    );
  }

  final ActiveTrayEntry? active;
  final List<PendingTrayTask> pendingTasks;
}

class ActiveTrayEntry {
  ActiveTrayEntry({
    required this.id,
    required this.taskId,
    required this.projectId,
    required this.taskTitle,
    required this.taskTitleShort,
    required this.taskTitleTray,
    required this.projectName,
    required this.projectNameShort,
    required this.description,
    required this.descriptionTray,
    required this.isPaused,
    required this.elapsedSeconds,
    required this.taskTodaySeconds,
    required this.startedAt,
  });

  factory ActiveTrayEntry.fromJson(Map<String, dynamic> json) {
    return ActiveTrayEntry(
      id: jsonInt(json['id'], field: 'active.id'),
      taskId: jsonInt(json['task_id'], field: 'active.task_id'),
      projectId: jsonInt(json['project_id'], field: 'active.project_id'),
      taskTitle: json['task_title'] as String? ?? '',
      taskTitleShort: json['task_title_short'] as String? ?? '',
      taskTitleTray: json['task_title_tray'] as String? ?? '',
      projectName: json['project_name'] as String? ?? '',
      projectNameShort: json['project_name_short'] as String? ?? '',
      description: json['description'] as String? ?? '',
      descriptionTray: json['description_tray'] as String? ?? '',
      isPaused: jsonBool(json['is_paused']),
      elapsedSeconds: jsonIntOrNull(json['elapsed_seconds']) ?? 0,
      taskTodaySeconds: jsonIntOrNull(json['task_today_seconds']) ?? 0,
      startedAt: DateTime.parse(json['started_at'] as String),
    );
  }

  final int id;
  final int taskId;
  final int projectId;
  final String taskTitle;
  final String taskTitleShort;
  final String taskTitleTray;
  final String projectName;
  final String projectNameShort;
  final String description;
  final String descriptionTray;
  final bool isPaused;
  final int elapsedSeconds;
  final int taskTodaySeconds;
  final DateTime startedAt;
}

class PendingTrayTask {
  PendingTrayTask({
    required this.id,
    required this.projectId,
    required this.title,
    required this.titleShort,
    required this.projectName,
    required this.projectNameShort,
    required this.description,
    required this.descriptionTray,
    required this.status,
    required this.statusLabel,
  });

  factory PendingTrayTask.fromJson(Map<String, dynamic> json) {
    return PendingTrayTask(
      id: jsonInt(json['id'], field: 'pending.id'),
      projectId: jsonInt(json['project_id'], field: 'pending.project_id'),
      title: json['title'] as String? ?? '',
      titleShort: json['title_short'] as String? ?? '',
      projectName: json['project_name'] as String? ?? '',
      projectNameShort: json['project_name_short'] as String? ?? '',
      description: json['description'] as String? ?? '',
      descriptionTray: json['description_tray'] as String? ?? '',
      status: json['status'] as String? ?? '',
      statusLabel: json['status_label'] as String? ?? '',
    );
  }

  final int id;
  final int projectId;
  final String title;
  final String titleShort;
  final String projectName;
  final String projectNameShort;
  final String description;
  final String descriptionTray;
  final String status;
  final String statusLabel;
}
