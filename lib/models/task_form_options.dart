import '../utils/json_parse.dart';
import 'task_show.dart';

Map<String, dynamic> _map(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  return {};
}

class TaskFormOptions {
  TaskFormOptions({
    required this.project,
    required this.statusOptions,
    required this.assignableUsers,
    required this.requirements,
    required this.parentTasks,
    required this.canCreateTasks,
    required this.canManageProject,
  });

  factory TaskFormOptions.fromJson(Map<String, dynamic> json) {
    return TaskFormOptions(
      project: ProjectSummary.fromJson(_map(json['project'])),
      statusOptions: (json['status_options'] as List<dynamic>? ?? [])
          .map((e) => FormOption.fromJson(_map(e)))
          .toList(),
      assignableUsers: (json['assignable_users'] as List<dynamic>? ?? [])
          .map((e) => IntFormOption.fromJson(_map(e)))
          .toList(),
      requirements: (json['requirements'] as List<dynamic>? ?? [])
          .map((e) => RequirementOption.fromJson(_map(e)))
          .toList(),
      parentTasks: (json['parent_tasks'] as List<dynamic>? ?? [])
          .map((e) => ParentTaskOption.fromJson(_map(e)))
          .toList(),
      canCreateTasks: jsonBool(json['can_create_tasks']),
      canManageProject: jsonBool(json['can_manage_project']),
    );
  }

  final ProjectSummary project;
  final List<FormOption> statusOptions;
  final List<IntFormOption> assignableUsers;
  final List<RequirementOption> requirements;
  final List<ParentTaskOption> parentTasks;
  final bool canCreateTasks;
  final bool canManageProject;
}

class FormOption {
  FormOption({required this.value, required this.label});

  factory FormOption.fromJson(Map<String, dynamic> json) {
    return FormOption(
      value: json['value'] as String? ?? '',
      label: json['label'] as String? ?? '',
    );
  }

  final String value;
  final String label;
}

class IntFormOption {
  IntFormOption({required this.value, required this.label});

  factory IntFormOption.fromJson(Map<String, dynamic> json) {
    return IntFormOption(
      value: jsonInt(json['value'], field: 'option.value'),
      label: json['label'] as String? ?? '',
    );
  }

  final int value;
  final String label;
}

class RequirementOption {
  RequirementOption({
    required this.value,
    required this.label,
    required this.maxGeneratedPhase,
  });

  factory RequirementOption.fromJson(Map<String, dynamic> json) {
    return RequirementOption(
      value: jsonInt(json['value'], field: 'requirement.value'),
      label: json['label'] as String? ?? '',
      maxGeneratedPhase:
          jsonIntOrNull(json['max_generated_phase']) ?? 1,
    );
  }

  final int value;
  final String label;
  final int maxGeneratedPhase;
}

class ParentTaskOption {
  ParentTaskOption({
    required this.value,
    required this.label,
    required this.treeDepth,
  });

  factory ParentTaskOption.fromJson(Map<String, dynamic> json) {
    return ParentTaskOption(
      value: jsonInt(json['value'], field: 'parent.value'),
      label: json['label'] as String? ?? '',
      treeDepth: jsonIntOrNull(json['tree_depth']) ?? 0,
    );
  }

  final int value;
  final String label;
  final int treeDepth;
}
