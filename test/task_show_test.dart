import 'package:flutter_test/flutter_test.dart';
import 'package:structural_flutter/models/notifications.dart';
import 'package:structural_flutter/models/task_show.dart';

void main() {
  test('TaskShowPayload.fromJson parses show payload', () {
    final payload = TaskShowPayload.fromJson({
      'project': {
        'id': 1,
        'name': 'Alpha',
        'code': 'ALP',
        'estimation_required': false,
      },
      'task': {
        'id': 5,
        'title': 'Fix bug',
        'description': 'Details',
        'status': 'to_do',
        'status_label': 'To do',
        'assignee_user_id': 2,
        'assignee': {'id': 2, 'name': 'Staff', 'email': 's@example.com'},
        'project_requirement_id': null,
        'requirement_title': null,
        'parent_project_task_id': null,
        'parent': null,
        'estimated_minutes': 60,
        'phase': null,
        'phase_label': null,
        'children_count': 1,
        'subtasks': [],
        'can_update': true,
        'can_delete': false,
        'completion_submitted_at': null,
        'completion_submitted_by': null,
        'is_assignee_only_limited': false,
        'can_submit_task_completion': true,
        'can_confirm_task_completion': false,
      },
      'can_manage_project': true,
      'checklist': {
        'can_manage': true,
        'items': [
          {'id': 1, 'title': 'Step one', 'is_completed': false},
        ],
      },
      'time_tracking': {
        'can_track': true,
        'working_hours': {'start': '09:00', 'end': '17:00'},
        'totals': {
          'my_today_seconds': 120,
          'my_all_time_seconds': 3600,
          'task_all_time_seconds': 7200,
          'remaining_seconds': 1800,
        },
        'entries': [],
      },
    });

    expect(payload.task.title, 'Fix bug');
    expect(payload.checklist.items.first.title, 'Step one');
    expect(payload.timeTracking.totals.myTodaySeconds, 120);
  });

  test('NotificationFeed.fromJson includes navigation ids', () {
    final feed = NotificationFeed.fromJson({
      'unread_count': 1,
      'read_count': 0,
      'unread_items': [
        {
          'id': 'uuid-1',
          'type': 'App\\\\Notifications\\\\TaskAssignedNotification',
          'read_at': null,
          'created_at': '2026-06-08T10:00:00Z',
          'title': 'Task assigned: Fix bug',
          'project_name': 'Alpha',
          'task_show_url': 'http://localhost/admin/projects/1/tasks/5',
          'project_id': 1,
          'project_task_id': 5,
          'notification_type': 'task_assigned',
        },
      ],
      'read_items': [],
    });

    expect(feed.unreadCount, 1);
    expect(feed.unreadItems.first.projectTaskId, 5);
  });
}
