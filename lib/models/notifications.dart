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

class NotificationFeed {
  NotificationFeed({
    required this.unreadCount,
    required this.readCount,
    required this.unreadItems,
    required this.readItems,
  });

  factory NotificationFeed.fromJson(Map<String, dynamic> json) {
    return NotificationFeed(
      unreadCount: jsonIntOrNull(json['unread_count']) ?? 0,
      readCount: jsonIntOrNull(json['read_count']) ?? 0,
      unreadItems: (json['unread_items'] as List<dynamic>? ?? [])
          .map((e) => NotificationItem.fromJson(_map(e)))
          .toList(),
      readItems: (json['read_items'] as List<dynamic>? ?? [])
          .map((e) => NotificationItem.fromJson(_map(e)))
          .toList(),
    );
  }

  final int unreadCount;
  final int readCount;
  final List<NotificationItem> unreadItems;
  final List<NotificationItem> readItems;
}

class NotificationItem {
  NotificationItem({
    required this.id,
    required this.type,
    required this.readAt,
    required this.createdAt,
    required this.title,
    required this.projectName,
    required this.taskShowUrl,
    required this.projectId,
    required this.projectTaskId,
    required this.notificationType,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? '',
      readAt: json['read_at'] as String?,
      createdAt: json['created_at'] as String?,
      title: json['title'] as String?,
      projectName: json['project_name'] as String?,
      taskShowUrl: json['task_show_url'] as String?,
      projectId: jsonIntOrNull(json['project_id']),
      projectTaskId: jsonIntOrNull(json['project_task_id']),
      notificationType: json['notification_type'] as String?,
    );
  }

  final String id;
  final String type;
  final String? readAt;
  final String? createdAt;
  final String? title;
  final String? projectName;
  final String? taskShowUrl;
  final int? projectId;
  final int? projectTaskId;
  final String? notificationType;

  bool get isUnread => readAt == null;
}
