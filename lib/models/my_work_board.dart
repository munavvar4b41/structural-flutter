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

class MyWorkBoard {
  MyWorkBoard({
    required this.columns,
    required this.statusOptions,
    required this.projectOptions,
    required this.filters,
  });

  factory MyWorkBoard.fromJson(Map<String, dynamic> json) {
    return MyWorkBoard(
      columns: (json['columns'] as List<dynamic>? ?? [])
          .map((e) => MyWorkColumn.fromJson(_map(e)))
          .toList(),
      statusOptions: (json['status_options'] as List<dynamic>? ?? [])
          .map((e) => StatusOption.fromJson(_map(e)))
          .toList(),
      projectOptions: (json['project_options'] as List<dynamic>? ?? [])
          .map((e) => ProjectOption.fromJson(_map(e)))
          .toList(),
      filters: MyWorkFilters.fromJson(_map(json['filters'])),
    );
  }

  final List<MyWorkColumn> columns;
  final List<StatusOption> statusOptions;
  final List<ProjectOption> projectOptions;
  final MyWorkFilters filters;
}

class MyWorkFilters {
  MyWorkFilters({required this.projectId});

  factory MyWorkFilters.fromJson(Map<String, dynamic> json) {
    return MyWorkFilters(
      projectId: jsonIntOrNull(json['project_id']),
    );
  }

  final int? projectId;
}

class ProjectOption {
  ProjectOption({required this.value, required this.label});

  factory ProjectOption.fromJson(Map<String, dynamic> json) {
    return ProjectOption(
      value: jsonInt(json['value'], field: 'project_options.value'),
      label: json['label'] as String? ?? '',
    );
  }

  final int value;
  final String label;
}

class MyWorkColumn {
  MyWorkColumn({
    required this.status,
    required this.label,
    required this.tasks,
    required this.meta,
  });

  factory MyWorkColumn.fromJson(Map<String, dynamic> json) {
    return MyWorkColumn(
      status: json['status'] as String? ?? '',
      label: json['label'] as String? ?? '',
      tasks: (json['tasks'] as List<dynamic>? ?? [])
          .map((e) => MyWorkTaskCard.fromJson(_map(e)))
          .toList(),
      meta: json['meta'] == null
          ? ColumnMeta.empty()
          : ColumnMeta.fromJson(_map(json['meta'])),
    );
  }

  final String status;
  final String label;
  final List<MyWorkTaskCard> tasks;
  final ColumnMeta meta;
}

class ColumnMeta {
  ColumnMeta({
    required this.total,
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
  });

  factory ColumnMeta.empty() {
    return ColumnMeta(total: 0, currentPage: 1, lastPage: 1, perPage: 20);
  }

  factory ColumnMeta.fromJson(Map<String, dynamic> json) {
    return ColumnMeta(
      total: jsonIntOrNull(json['total']) ?? 0,
      currentPage: jsonIntOrNull(json['current_page']) ?? 1,
      lastPage: jsonIntOrNull(json['last_page']) ?? 1,
      perPage: jsonIntOrNull(json['per_page']) ?? 20,
    );
  }

  final int total;
  final int currentPage;
  final int lastPage;
  final int perPage;
}

class MyWorkTaskCard {
  MyWorkTaskCard({
    required this.id,
    required this.projectId,
    required this.title,
    required this.status,
    required this.estimatedMinutes,
    required this.project,
    required this.requirement,
    required this.projectTasksUrl,
    required this.taskShowUrl,
    required this.isAssigneeOnlyLimited,
    required this.canSubmitTaskCompletion,
    required this.timerTodaySeconds,
    required this.timerState,
  });

  factory MyWorkTaskCard.fromJson(Map<String, dynamic> json) {
    return MyWorkTaskCard(
      id: jsonInt(json['id'], field: 'task.id'),
      projectId: jsonInt(json['project_id'], field: 'task.project_id'),
      title: json['title'] as String? ?? '',
      status: json['status'] as String? ?? '',
      estimatedMinutes: jsonIntOrNull(json['estimated_minutes']),
      project: MyWorkProject.fromJson(_map(json['project'])),
      requirement: json['requirement'] == null
          ? null
          : MyWorkRequirement.fromJson(_map(json['requirement'])),
      projectTasksUrl: json['project_tasks_url'] as String? ?? '',
      taskShowUrl: json['task_show_url'] as String? ?? '',
      isAssigneeOnlyLimited:
          jsonBool(json['is_assignee_only_limited']),
      canSubmitTaskCompletion:
          jsonBool(json['can_submit_task_completion']),
      timerTodaySeconds:
          jsonIntOrNull(json['timer_today_seconds']) ?? 0,
      timerState: json['timer_state'] as String? ?? 'idle',
    );
  }

  final int id;
  final int projectId;
  final String title;
  final String status;
  final int? estimatedMinutes;
  final MyWorkProject project;
  final MyWorkRequirement? requirement;
  final String projectTasksUrl;
  final String taskShowUrl;
  final bool isAssigneeOnlyLimited;
  final bool canSubmitTaskCompletion;
  final int timerTodaySeconds;
  final String timerState;

  MyWorkTaskCard copyWith({
    int? timerTodaySeconds,
    String? timerState,
  }) {
    return MyWorkTaskCard(
      id: id,
      projectId: projectId,
      title: title,
      status: status,
      estimatedMinutes: estimatedMinutes,
      project: project,
      requirement: requirement,
      projectTasksUrl: projectTasksUrl,
      taskShowUrl: taskShowUrl,
      isAssigneeOnlyLimited: isAssigneeOnlyLimited,
      canSubmitTaskCompletion: canSubmitTaskCompletion,
      timerTodaySeconds: timerTodaySeconds ?? this.timerTodaySeconds,
      timerState: timerState ?? this.timerState,
    );
  }
}

class MyWorkProject {
  MyWorkProject({
    required this.id,
    required this.name,
    required this.code,
  });

  factory MyWorkProject.fromJson(Map<String, dynamic> json) {
    return MyWorkProject(
      id: jsonInt(json['id'], field: 'project.id'),
      name: json['name'] as String? ?? '',
      code: json['code'] as String?,
    );
  }

  final int id;
  final String name;
  final String? code;
}

class MyWorkRequirement {
  MyWorkRequirement({required this.id, required this.title});

  factory MyWorkRequirement.fromJson(Map<String, dynamic> json) {
    return MyWorkRequirement(
      id: jsonInt(json['id'], field: 'requirement.id'),
      title: json['title'] as String? ?? '',
    );
  }

  final int id;
  final String title;
}

class StatusOption {
  StatusOption({required this.value, required this.label});

  factory StatusOption.fromJson(Map<String, dynamic> json) {
    return StatusOption(
      value: json['value'] as String? ?? '',
      label: json['label'] as String? ?? '',
    );
  }

  final String value;
  final String label;
}
