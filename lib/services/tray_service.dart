import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:tray_manager/tray_manager.dart';

import '../models/tray_snapshot.dart';
import '../utils/asset_paths.dart';
import '../utils/tray_platform.dart';
import 'desktop_api_client.dart';

class TrayService extends ChangeNotifier with TrayListener {
  TrayService({
    required DesktopApiClient api,
    required Future<void> Function() onViewAllTasks,
    required Future<void> Function() onOpenSettings,
    required Future<void> Function() onRequireLogin,
    required Future<void> Function() onQuit,
  })  : _api = api,
        _onViewAllTasks = onViewAllTasks,
        _onOpenSettings = onOpenSettings,
        _onRequireLogin = onRequireLogin,
        _onQuit = onQuit;

  final DesktopApiClient _api;
  final Future<void> Function() _onViewAllTasks;
  final Future<void> Function() _onOpenSettings;
  final Future<void> Function() _onRequireLogin;
  final Future<void> Function() _onQuit;

  TraySnapshot? _snapshot;
  DateTime? _snapshotFetchedAt;
  Timer? _pollTimer;
  Timer? _tickTimer;
  bool _busy = false;
  String? _lastMenuSignature;
  String? _stopIcon;
  String? _pauseIcon;
  String? _resumeIcon;
  String? _refreshIcon;
  String? _playIcon;

  TraySnapshot? get snapshot => _snapshot;
  int? get activeTaskId => _snapshot?.active?.taskId;

  static const int _pendingMenuLimit = 15;

  Future<void> stopTimer() => _stopTimer();

  Future<void> pauseTimer() => _pauseTimer();

  Future<void> resumeTimer() => _resumeTimer();

  Future<void> startTask({
    required int projectId,
    required int taskId,
  }) =>
      _startTask(projectId: projectId, taskId: taskId);

  Future<void> init() async {
    if (!Platform.isLinux && !Platform.isWindows && !Platform.isMacOS) {
      return;
    }

    await AssetPaths.preloadTrayIcons();
    if (TrayPlatform.menuIconsSupported) {
      _stopIcon = await AssetPaths.resolve('assets/tray/stop.png');
      _pauseIcon = await AssetPaths.resolve('assets/tray/pause.png');
      _resumeIcon = await AssetPaths.resolve('assets/tray/resume.png');
      _refreshIcon = await AssetPaths.resolve('assets/tray/refresh.png');
      _playIcon = await AssetPaths.resolve('assets/tray/play.png');
    }

    trayManager.addListener(this);
    await trayManager.setIcon(TrayPlatform.trayIconAsset);
    await _updateTrayLabel();
  }

  Future<void> start() async {
    await refresh();
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) => refresh());
    _tickTimer?.cancel();
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_snapshot?.active != null) {
        unawaited(_updateTrayLabel());
      }
    });
  }

  Future<void> stop() async {
    _pollTimer?.cancel();
    _tickTimer?.cancel();
    trayManager.removeListener(this);
    try {
      await trayManager.destroy();
    } catch (_) {
      // Tray may not exist on unsupported platforms.
    }
  }

  Future<void> refresh() async {
    if (_busy) {
      return;
    }
    _busy = true;
    try {
      _snapshot = await _api.fetchTray();
      _snapshotFetchedAt = DateTime.now();
      notifyListeners();
      await _rebuildMenu(force: true);
      await _updateTrayLabel();
    } on DesktopApiException catch (e) {
      if (e.statusCode == 401) {
        await _onRequireLogin();
      }
    } finally {
      _busy = false;
    }
  }

  String? _menuSignature(TraySnapshot? snapshot) {
    if (snapshot == null) {
      return null;
    }
    final active = snapshot.active;
    final pendingIds =
        snapshot.pendingTasks.map((t) => t.id).join(',');
    return '${active?.taskId}:${active?.isPaused}:$pendingIds';
  }

  Future<void> _updateTrayLabel() async {
    final label = TrayPlatform.formatTrayLabel(
      snapshot: _snapshot,
      snapshotFetchedAt: _snapshotFetchedAt,
    );
    await TrayPlatform.setHoverLabel(label);
  }

  Future<void> _rebuildMenu({bool force = false}) async {
    final signature = _menuSignature(_snapshot);
    if (!force && signature == _lastMenuSignature) {
      return;
    }
    _lastMenuSignature = signature;

    final items = <MenuItem>[];

    if (_snapshot == null) {
      items.add(
        MenuItem(
          key: 'loading',
          label: 'Loading…',
          disabled: true,
        ),
      );
    } else {
      final active = _snapshot!.active;
      if (active != null) {
        final headerLabel = active.description.isNotEmpty
            ? active.description
            : active.taskTitleTray;
        items.add(
          MenuItem(
            key: 'active_header',
            label: headerLabel,
            toolTip: active.description.isNotEmpty ? active.description : active.taskTitle,
            disabled: true,
          ),
        );
        items.add(_timerControlItem(
          key: 'timer_stop',
          label: 'Stop',
          toolTip: 'Stop timer',
          icon: _stopIcon,
          onClick: () => unawaited(_stopTimer()),
        ));
        if (active.isPaused) {
          items.add(_timerControlItem(
            key: 'timer_resume',
            label: 'Resume',
            toolTip: 'Resume timer',
            icon: _resumeIcon,
            onClick: () => unawaited(_resumeTimer()),
          ));
        } else {
          items.add(_timerControlItem(
            key: 'timer_pause',
            label: 'Pause',
            toolTip: 'Pause timer',
            icon: _pauseIcon,
            onClick: () => unawaited(_pauseTimer()),
          ));
        }
        items.add(_timerControlItem(
          key: 'timer_refresh',
          label: 'Refresh',
          toolTip: 'Refresh tray',
          icon: _refreshIcon,
          onClick: () => unawaited(refresh()),
        ));
        items.add(MenuItem.separator());
      }

      final pending = _snapshot!.pendingTasks.take(_pendingMenuLimit).toList();
      if (pending.isNotEmpty) {
        items.add(
          MenuItem(
            key: 'project_tasks_header',
            label: 'Project tasks',
            disabled: true,
          ),
        );
        for (final task in pending) {
          final baseTitle = task.description.isNotEmpty
              ? task.description
              : (task.titleShort.isNotEmpty ? task.titleShort : task.title);
          items.add(
            _pendingStartItem(
              task: task,
              title: _pendingMenuLabel(task, baseTitle),
              toolTip: task.description.isNotEmpty ? task.description : null,
            ),
          );
        }
        items.add(MenuItem.separator());
      }
    }

    items.add(
      MenuItem(
        key: 'view_all',
        label: 'View all tasks',
        onClick: (_) => unawaited(_onViewAllTasks()),
      ),
    );
    items.add(MenuItem.separator());
    items.add(
      MenuItem(
        key: 'settings',
        label: 'Settings',
        onClick: (_) => unawaited(_onOpenSettings()),
      ),
    );
    items.add(
      MenuItem(
        key: 'quit',
        label: 'Quit',
        onClick: (_) => unawaited(_onQuit()),
      ),
    );

    await trayManager.setContextMenu(Menu(items: items));
  }

  MenuItem _timerControlItem({
    required String key,
    required String label,
    required String toolTip,
    required String? icon,
    required VoidCallback onClick,
  }) {
    if (TrayPlatform.menuIconsSupported && icon != null) {
      return MenuItem(
        key: key,
        label: label,
        toolTip: toolTip,
        icon: icon,
        onClick: (_) => onClick(),
      );
    }
    return MenuItem(
      key: key,
      label: label,
      toolTip: toolTip,
      onClick: (_) => onClick(),
    );
  }

  String _pendingMenuLabel(PendingTrayTask task, String title) {
    if (task.statusLabel.isEmpty) {
      return title;
    }

    return '[${task.statusLabel}] $title';
  }

  MenuItem _pendingStartItem({
    required PendingTrayTask task,
    required String title,
    String? toolTip,
  }) {
    final hint = toolTip ??
        (_snapshot?.active != null ? 'Switch timer to this task' : 'Start timer');
    if (TrayPlatform.menuIconsSupported && _playIcon != null) {
      return MenuItem(
        key: 'start_${task.id}',
        label: title,
        toolTip: hint,
        icon: _playIcon,
        onClick: (_) => unawaited(
          _startTask(projectId: task.projectId, taskId: task.id),
        ),
      );
    }
    return MenuItem(
      key: 'start_${task.id}',
      label: '▶ $title',
      toolTip: hint,
      onClick: (_) => unawaited(
        _startTask(projectId: task.projectId, taskId: task.id),
      ),
    );
  }

  Future<void> _applySnapshot(TraySnapshot snapshot) async {
    _snapshot = snapshot;
    _snapshotFetchedAt = DateTime.now();
    notifyListeners();
    await _rebuildMenu(force: true);
    await _updateTrayLabel();
  }

  Future<void> _stopTimer() async {
    try {
      await _applySnapshot(await _api.stopTimer());
    } on DesktopApiException catch (e) {
      if (e.statusCode == 401) {
        await _onRequireLogin();
      }
    }
  }

  Future<void> _pauseTimer() async {
    try {
      await _applySnapshot(await _api.pauseTimer());
    } on DesktopApiException catch (e) {
      if (e.statusCode == 401) {
        await _onRequireLogin();
      }
    }
  }

  Future<void> _resumeTimer() async {
    try {
      await _applySnapshot(await _api.resumeTimer());
    } on DesktopApiException catch (e) {
      if (e.statusCode == 401) {
        await _onRequireLogin();
      }
    }
  }

  Future<void> _startTask({
    required int projectId,
    required int taskId,
  }) async {
    try {
      await _applySnapshot(
        await _api.startTimer(projectId: projectId, taskId: taskId),
      );
    } on DesktopApiException catch (e) {
      if (e.statusCode == 401) {
        await _onRequireLogin();
      }
    }
  }

  @override
  void onTrayIconMouseDown() {
    // Left click — no action; menu opens on right click on most platforms.
  }

  @override
  void onTrayIconRightMouseDown() {
    unawaited(TrayPlatform.popUpContextMenuIfSupported());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _tickTimer?.cancel();
    trayManager.removeListener(this);
    super.dispose();
  }
}
