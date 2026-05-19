import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/my_work_board.dart';
import '../../services/app_controller.dart';
import '../../services/desktop_api_client.dart';
import '../../theme/app_theme.dart';
import 'board_heading.dart';
import 'task_card.dart';

class MyWorkPage extends StatefulWidget {
  const MyWorkPage({super.key, required this.controller});

  final AppController controller;

  @override
  State<MyWorkPage> createState() => _MyWorkPageState();
}

class _MyWorkPageState extends State<MyWorkPage> {
  MyWorkBoard? _board;
  bool _loading = true;
  bool _refreshing = false;
  String? _error;
  int? _projectId;
  final Map<String, int> _columnPages = {};
  int? _trackedActiveTaskId;

  @override
  void initState() {
    super.initState();
    widget.controller.tray.addListener(_onTrayChanged);
    _load();
  }

  @override
  void dispose() {
    widget.controller.tray.removeListener(_onTrayChanged);
    super.dispose();
  }

  void _onTrayChanged() {
    if (!mounted || _board == null) {
      return;
    }

    final activeTaskId = widget.controller.tray.snapshot?.active?.taskId;
    if (activeTaskId != _trackedActiveTaskId) {
      _trackedActiveTaskId = activeTaskId;
      _syncTimerFromTray();
      unawaited(_load(silent: true));

      return;
    }

    _syncTimerFromTray();
  }

  void _syncTimerFromTray() {
    final board = _board;
    if (board == null) {
      return;
    }

    final active = widget.controller.tray.snapshot?.active;
    final activeTaskId = active?.taskId;

    final updatedColumns = board.columns.map((column) {
      final tasks = column.tasks.map((task) {
        if (activeTaskId != null && task.id == activeTaskId) {
          return task.copyWith(
            timerState: active!.isPaused ? 'paused' : 'running',
            timerTodaySeconds: active.taskTodaySeconds,
          );
        }

        if (task.timerState != 'idle') {
          return task.copyWith(timerState: 'idle');
        }

        return task;
      }).toList();

      return MyWorkColumn(
        status: column.status,
        label: column.label,
        tasks: tasks,
        meta: column.meta,
      );
    }).toList();

    setState(() {
      _board = MyWorkBoard(
        columns: updatedColumns,
        statusOptions: board.statusOptions,
        projectOptions: board.projectOptions,
        filters: board.filters,
      );
    });
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    } else {
      setState(() => _refreshing = true);
    }

    try {
      final board = await widget.controller.api.fetchMyWork(
        projectId: _projectId,
        columnPages: _columnPages.isEmpty ? null : Map.from(_columnPages),
      );
      if (mounted) {
        setState(() {
          _board = board;
          _projectId = board.filters.projectId;
          _trackedActiveTaskId = widget.controller.tray.snapshot?.active?.taskId;
          _loading = false;
          _refreshing = false;
        });
      }
    } on DesktopApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _loading = false;
          _refreshing = false;
        });
      }
      if (e.statusCode == 401) {
        await widget.controller.requireLogin();
      }
    } catch (e, stack) {
      debugPrint('MyWorkPage load failed: $e\n$stack');
      if (mounted) {
        setState(() {
          _error = e is FormatException
              ? 'Could not read board data from the server.'
              : 'Failed to load board: $e';
          _loading = false;
          _refreshing = false;
        });
      }
    }
  }

  Future<void> _refresh() async {
    await widget.controller.tray.refresh();
    await _load(silent: true);
  }

  void _onProjectFilterChanged(int? projectId) {
    setState(() {
      _projectId = projectId;
      _columnPages.clear();
    });
    unawaited(_load(silent: true));
  }

  void _loadMoreColumn(MyWorkColumn column) {
    if (column.meta.currentPage >= column.meta.lastPage) {
      return;
    }
    setState(() {
      _columnPages[column.status] = column.meta.currentPage + 1;
    });
    unawaited(_load(silent: true));
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open $url')),
        );
      }
    }
  }

  Future<void> _startTimer(MyWorkTaskCard task) async {
    await widget.controller.tray.startTask(
      projectId: task.projectId,
      taskId: task.id,
    );
  }

  Future<void> _pauseTimer() async {
    await widget.controller.tray.pauseTimer();
  }

  Future<void> _resumeTimer() async {
    await widget.controller.tray.resumeTimer();
  }

  Future<void> _stopTimer() async {
    await widget.controller.tray.stopTimer();
  }

  @override
  Widget build(BuildContext context) {
    final activeTaskId = widget.controller.tray.activeTaskId;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: BoardHeading(
        onRefresh: _refresh,
        onSettings: () => widget.controller.showSettings(),
        refreshEnabled: !_loading && !_refreshing,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                if (_error != null)
                  _buildErrorBody()
                else if (_board == null)
                  const SizedBox.shrink()
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                        child: _ProjectFilter(
                          board: _board!,
                          projectId: _projectId,
                          onChanged: _onProjectFilterChanged,
                        ),
                      ),
                      Expanded(
                        child: _KanbanBoard(
                          board: _board!,
                          activeTaskId: activeTaskId,
                          onOpenTask: _openUrl,
                          onStartTimer: _startTimer,
                          onPauseTimer: _pauseTimer,
                          onResumeTimer: _resumeTimer,
                          onStopTimer: _stopTimer,
                          onLoadMore: _loadMoreColumn,
                        ),
                      ),
                    ],
                  ),
                if (_refreshing)
                  const Positioned(
                    top: 8,
                    right: 16,
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildErrorBody() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_error!),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => _load(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _ProjectFilter extends StatelessWidget {
  const _ProjectFilter({
    required this.board,
    required this.projectId,
    required this.onChanged,
  });

  final MyWorkBoard board;
  final int? projectId;
  final void Function(int?) onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int?>(
      value: projectId,
      decoration: const InputDecoration(
        labelText: 'Project',
        isDense: true,
      ),
      items: [
        const DropdownMenuItem<int?>(
          value: null,
          child: Text('All projects'),
        ),
        ...board.projectOptions.map(
          (o) => DropdownMenuItem<int?>(
            value: o.value,
            child: Text(o.label, overflow: TextOverflow.ellipsis),
          ),
        ),
      ],
      onChanged: onChanged,
    );
  }
}

class _KanbanBoard extends StatefulWidget {
  const _KanbanBoard({
    required this.board,
    required this.activeTaskId,
    required this.onOpenTask,
    required this.onStartTimer,
    required this.onPauseTimer,
    required this.onResumeTimer,
    required this.onStopTimer,
    required this.onLoadMore,
  });

  final MyWorkBoard board;
  final int? activeTaskId;
  final Future<void> Function(String url) onOpenTask;
  final Future<void> Function(MyWorkTaskCard task) onStartTimer;
  final Future<void> Function() onPauseTimer;
  final Future<void> Function() onResumeTimer;
  final Future<void> Function() onStopTimer;
  final void Function(MyWorkColumn column) onLoadMore;

  @override
  State<_KanbanBoard> createState() => _KanbanBoardState();
}

class _KanbanBoardState extends State<_KanbanBoard> {
  final ScrollController _horizontalScrollController = ScrollController();

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _KanbanBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.board != widget.board) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _clampScrollOffset());
    }
  }

  void _clampScrollOffset() {
    if (!_horizontalScrollController.hasClients) {
      return;
    }
    final position = _horizontalScrollController.position;
    final maxExtent = position.maxScrollExtent;
    final pixels = position.pixels;
    if (pixels > maxExtent) {
      _horizontalScrollController.jumpTo(maxExtent);
    }
  }

  @override
  Widget build(BuildContext context) {
    final listView = ListView(
      controller: _horizontalScrollController,
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      children: [
        for (final column in widget.board.columns)
          _StatusColumn(
            column: column,
            activeTaskId: widget.activeTaskId,
            onOpenTask: widget.onOpenTask,
            onStartTimer: widget.onStartTimer,
            onPauseTimer: widget.onPauseTimer,
            onResumeTimer: widget.onResumeTimer,
            onStopTimer: widget.onStopTimer,
            onLoadMore: widget.onLoadMore,
          ),
      ],
    );

    return Scrollbar(
      controller: _horizontalScrollController,
      child: listView,
    );
  }
}

class _StatusColumn extends StatelessWidget {
  const _StatusColumn({
    required this.column,
    required this.activeTaskId,
    required this.onOpenTask,
    required this.onStartTimer,
    required this.onPauseTimer,
    required this.onResumeTimer,
    required this.onStopTimer,
    required this.onLoadMore,
  });

  final MyWorkColumn column;
  final int? activeTaskId;
  final Future<void> Function(String url) onOpenTask;
  final Future<void> Function(MyWorkTaskCard task) onStartTimer;
  final Future<void> Function() onPauseTimer;
  final Future<void> Function() onResumeTimer;
  final Future<void> Function() onStopTimer;
  final void Function(MyWorkColumn column) onLoadMore;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = AppTheme.columnAccent(column.status, scheme);
    final canLoadMore = column.meta.currentPage < column.meta.lastPage;

    return Container(
      width: 288,
      height: double.infinity,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: AppTheme.columnBackground(scheme),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: accent, width: 3),
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    column.label,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                Text(
                  '${column.tasks.length} / ${column.meta.total}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          Expanded(
            child: column.tasks.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: scheme.outlineVariant,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'No tasks',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                        ),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    itemCount:
                        column.tasks.length + (canLoadMore ? 1 : 0),
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      if (canLoadMore && index == column.tasks.length) {
                        return OutlinedButton(
                          onPressed: () => onLoadMore(column),
                          child: Text(
                            'Load more (${column.meta.total - column.tasks.length})',
                          ),
                        );
                      }
                      final task = column.tasks[index];
                      final isActive = activeTaskId != null &&
                          task.id == activeTaskId;
                      return TaskCardWidget(
                        task: task,
                        isActive: isActive,
                        onView: () => onOpenTask(task.taskShowUrl),
                        onStart: () => onStartTimer(task),
                        onPause: onPauseTimer,
                        onResume: onResumeTimer,
                        onStop: onStopTimer,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
