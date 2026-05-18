import 'package:flutter_test/flutter_test.dart';
import 'package:structural_flutter/models/my_work_board.dart';

void main() {
  test('MyWorkBoard.fromJson parses Laravel my-work payload', () {
    final board = MyWorkBoard.fromJson({
      'columns': [
        {
          'status': 'to_do',
          'label': 'To do',
          'tasks': [
            {
              'id': 1,
              'project_id': 2,
              'title': 'Fix bug',
              'status': 'to_do',
              'estimated_minutes': 60,
              'project': {
                'id': 2,
                'name': 'Alpha',
                'code': 'ALP',
              },
              'requirement': null,
              'project_tasks_url': 'http://localhost/admin/projects/2/tasks',
              'task_show_url': 'http://localhost/admin/projects/2/tasks/1',
              'is_assignee_only_limited': false,
              'can_submit_task_completion': true,
              'timer_today_seconds': 120,
              'timer_state': 'running',
            },
          ],
          'meta': {
            'total': 1,
            'current_page': 1,
            'last_page': 1,
            'per_page': 20,
          },
        },
      ],
      'status_options': [
        {'value': 'to_do', 'label': 'To do'},
      ],
      'project_options': [
        {'value': 2, 'label': 'Alpha (ALP)'},
      ],
      'filters': {'project_id': null},
    });

    expect(board.columns, hasLength(1));
    expect(board.columns.first.tasks.first.timerTodaySeconds, 120);
    expect(board.columns.first.meta.total, 1);
    expect(board.projectOptions.first.value, 2);
  });

  test('MyWorkBoard.fromJson accepts numeric values as double', () {
    final board = MyWorkBoard.fromJson({
      'columns': [
        {
          'status': 'to_do',
          'label': 'To do',
          'tasks': [
            {
              'id': 1.0,
              'project_id': 2.0,
              'title': 'Task',
              'status': 'to_do',
              'estimated_minutes': null,
              'project': {'id': 2.0, 'name': 'P', 'code': null},
              'requirement': null,
              'project_tasks_url': 'http://x',
              'task_show_url': 'http://y',
              'is_assignee_only_limited': 0,
              'can_submit_task_completion': 1,
              'timer_today_seconds': 0.0,
              'timer_state': 'idle',
            },
          ],
          'meta': {
            'total': 1.0,
            'current_page': 1.0,
            'last_page': 1.0,
            'per_page': 20.0,
          },
        },
      ],
      'status_options': [],
      'project_options': [],
      'filters': {},
    });

    expect(board.columns.first.tasks.first.id, 1);
    expect(board.columns.first.tasks.first.canSubmitTaskCompletion, isTrue);
  });
}
