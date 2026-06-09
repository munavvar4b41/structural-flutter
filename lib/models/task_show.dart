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

class TaskShowPayload {
  TaskShowPayload({
    required this.project,
    required this.task,
    required this.canManageProject,
    required this.checklist,
    required this.timeTracking,
  });

  factory TaskShowPayload.fromJson(Map<String, dynamic> json) {
    return TaskShowPayload(
      project: ProjectSummary.fromJson(_map(json['project'])),
      task: TaskDetail.fromJson(_map(json['task'])),
      canManageProject: jsonBool(json['can_manage_project']),
      checklist: ChecklistSection.fromJson(_map(json['checklist'])),
      timeTracking: TimeTrackingSection.fromJson(_map(json['time_tracking'])),
    );
  }

  final ProjectSummary project;
  final TaskDetail task;
  final bool canManageProject;
  final ChecklistSection checklist;
  final TimeTrackingSection timeTracking;
}

class ProjectSummary {
  ProjectSummary({
    required this.id,
    required this.name,
    required this.code,
    required this.estimationRequired,
  });

  factory ProjectSummary.fromJson(Map<String, dynamic> json) {
    return ProjectSummary(
      id: jsonInt(json['id'], field: 'project.id'),
      name: json['name'] as String? ?? '',
      code: json['code'] as String?,
      estimationRequired: jsonBool(json['estimation_required']),
    );
  }

  final int id;
  final String name;
  final String? code;
  final bool estimationRequired;
}

class UserBrief {
  UserBrief({required this.id, required this.name, required this.email});

  factory UserBrief.fromJson(Map<String, dynamic> json) {
    return UserBrief(
      id: jsonInt(json['id'], field: 'user.id'),
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
    );
  }

  final int id;
  final String name;
  final String email;
}

class TaskParentBrief {
  TaskParentBrief({required this.id, required this.title});

  factory TaskParentBrief.fromJson(Map<String, dynamic> json) {
    return TaskParentBrief(
      id: jsonInt(json['id'], field: 'parent.id'),
      title: json['title'] as String? ?? '',
    );
  }

  final int id;
  final String title;
}

class SubtaskRow {
  SubtaskRow({
    required this.id,
    required this.title,
    required this.status,
    required this.statusLabel,
    required this.assigneeUserId,
    required this.assignee,
    required this.projectRequirementId,
    required this.requirementTitle,
    required this.estimatedMinutes,
    required this.childrenCount,
    required this.treeDepth,
    required this.canUpdate,
    required this.canDelete,
    required this.isAssigneeOnlyLimited,
    required this.canSubmitTaskCompletion,
    required this.canConfirmTaskCompletion,
  });

  factory SubtaskRow.fromJson(Map<String, dynamic> json) {
    return SubtaskRow(
      id: jsonInt(json['id'], field: 'subtask.id'),
      title: json['title'] as String? ?? '',
      status: json['status'] as String? ?? '',
      statusLabel: json['status_label'] as String? ?? '',
      assigneeUserId: jsonIntOrNull(json['assignee_user_id']),
      assignee: json['assignee'] == null
          ? null
          : UserBrief.fromJson(_map(json['assignee'])),
      projectRequirementId: jsonIntOrNull(json['project_requirement_id']),
      requirementTitle: json['requirement_title'] as String?,
      estimatedMinutes: jsonIntOrNull(json['estimated_minutes']),
      childrenCount: jsonIntOrNull(json['children_count']) ?? 0,
      treeDepth: jsonIntOrNull(json['tree_depth']) ?? 0,
      canUpdate: jsonBool(json['can_update']),
      canDelete: jsonBool(json['can_delete']),
      isAssigneeOnlyLimited: jsonBool(json['is_assignee_only_limited']),
      canSubmitTaskCompletion: jsonBool(json['can_submit_task_completion']),
      canConfirmTaskCompletion: jsonBool(json['can_confirm_task_completion']),
    );
  }

  final int id;
  final String title;
  final String status;
  final String statusLabel;
  final int? assigneeUserId;
  final UserBrief? assignee;
  final int? projectRequirementId;
  final String? requirementTitle;
  final int? estimatedMinutes;
  final int childrenCount;
  final int treeDepth;
  final bool canUpdate;
  final bool canDelete;
  final bool isAssigneeOnlyLimited;
  final bool canSubmitTaskCompletion;
  final bool canConfirmTaskCompletion;
}

class TaskDetail {
  TaskDetail({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.statusLabel,
    required this.assigneeUserId,
    required this.assignee,
    required this.projectRequirementId,
    required this.requirementTitle,
    required this.parentProjectTaskId,
    required this.parent,
    required this.estimatedMinutes,
    required this.phase,
    required this.phaseLabel,
    required this.childrenCount,
    required this.subtasks,
    required this.canUpdate,
    required this.canDelete,
    required this.completionSubmittedAt,
    required this.completionSubmittedBy,
    required this.isAssigneeOnlyLimited,
    required this.canSubmitTaskCompletion,
    required this.canConfirmTaskCompletion,
  });

  factory TaskDetail.fromJson(Map<String, dynamic> json) {
    return TaskDetail(
      id: jsonInt(json['id'], field: 'task.id'),
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      status: json['status'] as String? ?? '',
      statusLabel: json['status_label'] as String? ?? '',
      assigneeUserId: jsonIntOrNull(json['assignee_user_id']),
      assignee: json['assignee'] == null
          ? null
          : UserBrief.fromJson(_map(json['assignee'])),
      projectRequirementId: jsonIntOrNull(json['project_requirement_id']),
      requirementTitle: json['requirement_title'] as String?,
      parentProjectTaskId: jsonIntOrNull(json['parent_project_task_id']),
      parent: json['parent'] == null
          ? null
          : TaskParentBrief.fromJson(_map(json['parent'])),
      estimatedMinutes: jsonIntOrNull(json['estimated_minutes']),
      phase: jsonIntOrNull(json['phase']),
      phaseLabel: json['phase_label'] as String?,
      childrenCount: jsonIntOrNull(json['children_count']) ?? 0,
      subtasks: (json['subtasks'] as List<dynamic>? ?? [])
          .map((e) => SubtaskRow.fromJson(_map(e)))
          .toList(),
      canUpdate: jsonBool(json['can_update']),
      canDelete: jsonBool(json['can_delete']),
      completionSubmittedAt: json['completion_submitted_at'] as String?,
      completionSubmittedBy: json['completion_submitted_by'] == null
          ? null
          : UserBrief.fromJson(_map(json['completion_submitted_by'])),
      isAssigneeOnlyLimited: jsonBool(json['is_assignee_only_limited']),
      canSubmitTaskCompletion: jsonBool(json['can_submit_task_completion']),
      canConfirmTaskCompletion: jsonBool(json['can_confirm_task_completion']),
    );
  }

  final int id;
  final String title;
  final String? description;
  final String status;
  final String statusLabel;
  final int? assigneeUserId;
  final UserBrief? assignee;
  final int? projectRequirementId;
  final String? requirementTitle;
  final int? parentProjectTaskId;
  final TaskParentBrief? parent;
  final int? estimatedMinutes;
  final int? phase;
  final String? phaseLabel;
  final int childrenCount;
  final List<SubtaskRow> subtasks;
  final bool canUpdate;
  final bool canDelete;
  final String? completionSubmittedAt;
  final UserBrief? completionSubmittedBy;
  final bool isAssigneeOnlyLimited;
  final bool canSubmitTaskCompletion;
  final bool canConfirmTaskCompletion;
}

class ChecklistItemRow {
  ChecklistItemRow({
    required this.id,
    required this.title,
    required this.isCompleted,
  });

  factory ChecklistItemRow.fromJson(Map<String, dynamic> json) {
    return ChecklistItemRow(
      id: jsonInt(json['id'], field: 'checklist.id'),
      title: json['title'] as String? ?? '',
      isCompleted: jsonBool(json['is_completed']),
    );
  }

  final int id;
  final String title;
  final bool isCompleted;
}

class ChecklistSection {
  ChecklistSection({required this.canManage, required this.items});

  factory ChecklistSection.fromJson(Map<String, dynamic> json) {
    return ChecklistSection(
      canManage: jsonBool(json['can_manage']),
      items: (json['items'] as List<dynamic>? ?? [])
          .map((e) => ChecklistItemRow.fromJson(_map(e)))
          .toList(),
    );
  }

  final bool canManage;
  final List<ChecklistItemRow> items;
}

class TimeEntryRow {
  TimeEntryRow({
    required this.id,
    required this.userId,
    required this.userName,
    required this.startedAt,
    required this.endedAt,
    required this.durationSeconds,
    required this.isRunning,
    required this.isPaused,
    required this.elapsedSeconds,
    required this.source,
    required this.sourceLabel,
    required this.notes,
    required this.canUpdate,
    required this.canDelete,
  });

  factory TimeEntryRow.fromJson(Map<String, dynamic> json) {
    return TimeEntryRow(
      id: jsonInt(json['id'], field: 'time_entry.id'),
      userId: jsonInt(json['user_id'], field: 'time_entry.user_id'),
      userName: json['user_name'] as String?,
      startedAt: json['started_at'] as String?,
      endedAt: json['ended_at'] as String?,
      durationSeconds: jsonIntOrNull(json['duration_seconds']),
      isRunning: jsonBool(json['is_running']),
      isPaused: jsonBool(json['is_paused']),
      elapsedSeconds: jsonIntOrNull(json['elapsed_seconds']),
      source: json['source'] as String? ?? '',
      sourceLabel: json['source_label'] as String? ?? '',
      notes: json['notes'] as String?,
      canUpdate: jsonBool(json['can_update']),
      canDelete: jsonBool(json['can_delete']),
    );
  }

  final int id;
  final int userId;
  final String? userName;
  final String? startedAt;
  final String? endedAt;
  final int? durationSeconds;
  final bool isRunning;
  final bool isPaused;
  final int? elapsedSeconds;
  final String source;
  final String sourceLabel;
  final String? notes;
  final bool canUpdate;
  final bool canDelete;
}

class TimeTrackingTotals {
  TimeTrackingTotals({
    required this.myTodaySeconds,
    required this.myAllTimeSeconds,
    required this.taskAllTimeSeconds,
    required this.remainingSeconds,
  });

  factory TimeTrackingTotals.fromJson(Map<String, dynamic> json) {
    return TimeTrackingTotals(
      myTodaySeconds: jsonIntOrNull(json['my_today_seconds']) ?? 0,
      myAllTimeSeconds: jsonIntOrNull(json['my_all_time_seconds']) ?? 0,
      taskAllTimeSeconds: jsonIntOrNull(json['task_all_time_seconds']) ?? 0,
      remainingSeconds: jsonIntOrNull(json['remaining_seconds']),
    );
  }

  final int myTodaySeconds;
  final int myAllTimeSeconds;
  final int taskAllTimeSeconds;
  final int? remainingSeconds;
}

class TimeTrackingSection {
  TimeTrackingSection({
    required this.canTrack,
    required this.workingHoursStart,
    required this.workingHoursEnd,
    required this.totals,
    required this.entries,
  });

  factory TimeTrackingSection.fromJson(Map<String, dynamic> json) {
    final workingHours = _map(json['working_hours']);
    return TimeTrackingSection(
      canTrack: jsonBool(json['can_track']),
      workingHoursStart: workingHours['start'] as String? ?? '',
      workingHoursEnd: workingHours['end'] as String? ?? '',
      totals: TimeTrackingTotals.fromJson(_map(json['totals'])),
      entries: (json['entries'] as List<dynamic>? ?? [])
          .map((e) => TimeEntryRow.fromJson(_map(e)))
          .toList(),
    );
  }

  final bool canTrack;
  final String workingHoursStart;
  final String workingHoursEnd;
  final TimeTrackingTotals totals;
  final List<TimeEntryRow> entries;
}
