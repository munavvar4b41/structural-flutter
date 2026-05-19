import 'package:flutter_test/flutter_test.dart';
import 'package:structural_flutter/models/tray_snapshot.dart';

void main() {
  test('TraySnapshot.fromJson parses pending task status fields', () {
    final snapshot = TraySnapshot.fromJson({
      'active': null,
      'pending_tasks': [
        {
          'id': 5,
          'project_id': 2,
          'title': 'Fix bug',
          'title_short': 'Fix bug',
          'project_name': 'Alpha',
          'project_name_short': 'ALP',
          'description': 'ALP · Fix bug',
          'description_tray': 'ALP · Fix bug',
          'status': 'in_progress',
          'status_label': 'In progress',
        },
      ],
    });

    expect(snapshot.pendingTasks, hasLength(1));
    expect(snapshot.pendingTasks.first.status, 'in_progress');
    expect(snapshot.pendingTasks.first.statusLabel, 'In progress');
  });
}
