import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:structural_flutter/models/my_work_board.dart';
import 'package:structural_flutter/ui/my_work/task_timer_actions.dart';

MyWorkTaskCard _task({String timerState = 'idle'}) {
  return MyWorkTaskCard(
    id: 1,
    projectId: 10,
    title: 'Test task',
    status: 'todo',
    estimatedMinutes: null,
    project: MyWorkProject(id: 10, name: 'Project', code: null),
    requirement: null,
    projectTasksUrl: 'https://example.com/tasks',
    taskShowUrl: 'https://example.com/task/1',
    isAssigneeOnlyLimited: false,
    canSubmitTaskCompletion: false,
    childrenCount: 0,
    timerTodaySeconds: 0,
    timerState: timerState,
  );
}

void main() {
  testWidgets('idle task start row renders without ParentDataWidget error',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TaskTimerActions(
            task: _task(),
            isActive: false,
            onView: () {},
            onStart: () {},
            onPause: () {},
            onResume: () {},
            onStop: () {},
          ),
        ),
      ),
    );

    expect(find.byTooltip('Start timer'), findsOneWidget);
  });
}
