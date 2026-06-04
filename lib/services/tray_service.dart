import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:tray_manager/tray_manager.dart';

import '../models/tray_snapshot.dart';
import '../utils/asset_paths.dart';
import '../utils/tray_platform.dart';
import 'desktop_api_client.dart';
import 'system_idle_service.dart';

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
        _onQuit = onQuit {
    _systemIdle = SystemIdleService(
      idleThreshold: _inactivityThreshold,
      pollInterval: const Duration(seconds: 5),
    );
  }

  static const Duration _inactivityThreshold = Duration(minutes: 10);

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
  bool _inactivityActionInFlight = false;
  late final SystemIdleService _systemIdle;
  bool _systemIdleActive = false;
  bool _systemIdleSupported = false;
  bool autoPausedByInactivity = false;
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

  Future<void> pauseTimer() => _pauseTimer(manual: true);

  Future<void> resumeTimer() => _resumeTimer(manual: true);

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
    try {
      await trayManager.setIcon(TrayPlatform.trayIconAsset);
    } catch (_) {
      // Allow startup when icon assets are unavailable.
    }
    await _updateTrayLabel();
  }

  Future<void> start() async {
    await refresh();
    await _systemIdle.startPolling(onIdleChanged: _onSystemIdleChanged);
    _systemIdleSupported = _systemIdle.isSupported;
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) => refresh());
    _tickTimer?.cancel();
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_snapshot?.active != null) {
        unawaited(_updateTrayLabel());
      }
    });
    await _rebuildMenu(force: true);
  }

  Future<void> stop() async {
    _systemIdleActive = false;
    autoPausedByInactivity = false;
    await _systemIdle.stopPolling();
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
    return '${active?.taskId}:${active?.isPaused}:$pendingIds:'
        '$autoPausedByInactivity:$_systemIdleSupported';
  }

  Future<void> _updateTrayLabel() async {
    final label = TrayPlatform.formatTrayLabel(
      snapshot: _snapshot,
      snapshotFetchedAt: _snapshotFetchedAt,
      showInactiveBadge: _showInactiveBadge,
      systemIdleUnavailable: !_systemIdleSupported,
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
      items.add(_timerControlItem(
        key: 'tray_refresh',
        label: 'Refresh tray',
        toolTip: 'Load tray data',
        icon: _refreshIcon,
        onClick: () => unawaited(refresh()),
      ));
    } else {
      final active = _snapshot!.active;
      if (active != null) {
        final taskLabel = active.description.isNotEmpty
            ? active.description
            : active.taskTitleTray;
        final taskToolTip = active.description.isNotEmpty
            ? active.description
            : active.taskTitle;
        items.add(_timerControlItem(
          key: 'timer_stop',
          label: 'Stop · $taskLabel',
          toolTip: 'Stop timer · $taskToolTip',
          icon: _stopIcon,
          onClick: () => unawaited(_stopTimer()),
        ));
        if (active.isPaused) {
          items.add(_timerControlItem(
            key: 'timer_resume',
            label: 'Resume',
            toolTip: 'Resume timer',
            icon: _resumeIcon,
            onClick: () => unawaited(_resumeTimer(manual: true)),
          ));
        } else {
          items.add(_timerControlItem(
            key: 'timer_pause',
            label: 'Pause',
            toolTip: 'Pause timer',
            icon: _pauseIcon,
            onClick: () => unawaited(_pauseTimer(manual: true)),
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

    await trayManager.setContextMenu(Menu(items: _compactMenuSeparators(items)));
  }

  /// Linux AppIndicator/dbusmenu warns on disabled/header-only rows.
  List<MenuItem> _compactMenuSeparators(List<MenuItem> items) {
    final compact = <MenuItem>[];
    for (final item in items) {
      if (item.type == 'separator') {
        if (compact.isEmpty || compact.last.type == 'separator') {
          continue;
        }
      }
      compact.add(item);
    }
    while (compact.isNotEmpty && compact.last.type == 'separator') {
      compact.removeLast();
    }

    return compact;
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
    if (_snapshot?.active == null) {
      _systemIdleActive = false;
      autoPausedByInactivity = false;
    }
    notifyListeners();
    await _rebuildMenu(force: true);
    await _updateTrayLabel();
  }

  bool get _showInactiveBadge =>
      _snapshot?.active != null &&
      (_systemIdleActive || autoPausedByInactivity);

  Future<void> _onSystemIdleChanged(bool isIdle) async {
    if (!_systemIdleSupported) {
      return;
    }

    _systemIdleActive = isIdle;

    if (_snapshot?.active == null) {
      await _updateTrayLabel();

      return;
    }

    if (isIdle) {
      await _autoPauseTimer();
    } else if (autoPausedByInactivity && _snapshot?.active?.isPaused == true) {
      await _autoResumeTimer();
    }

    await _updateTrayLabel();
    await _rebuildMenu();
  }

  bool get _hasRunningTimer =>
      _snapshot?.active != null && _snapshot!.active!.isPaused == false;

  Future<void> _autoPauseTimer() async {
    if (_inactivityActionInFlight || !_hasRunningTimer || !_systemIdleSupported) {
      return;
    }

    await _pauseTimer(manual: false, reason: 'inactivity');
  }

  Future<void> _autoResumeTimer() async {
    if (_inactivityActionInFlight ||
        !autoPausedByInactivity ||
        _snapshot?.active?.isPaused != true ||
        !_systemIdleSupported) {
      return;
    }

    await _resumeTimer(manual: false, resumedBy: 'inactivity');
  }

  Future<void> _stopTimer() async {
    try {
      autoPausedByInactivity = false;
      _systemIdleActive = false;
      await _applySnapshot(await _api.stopTimer());
    } on DesktopApiException catch (e) {
      if (e.statusCode == 401) {
        await _onRequireLogin();
      }
    }
  }

  Future<void> _pauseTimer({
    required bool manual,
    String? reason,
  }) async {
    if (_inactivityActionInFlight) {
      return;
    }
    _inactivityActionInFlight = true;
    try {
      final eventAt = DateTime.now();
      await _applySnapshot(
        await _api.pauseTimer(
          reason: manual ? 'manual' : reason,
          clientEventAt: eventAt,
        ),
      );
      if (manual) {
        autoPausedByInactivity = false;
      } else if (reason == 'inactivity') {
        autoPausedByInactivity = true;
      }
    } on DesktopApiException catch (e) {
      if (e.statusCode == 401) {
        await _onRequireLogin();
      }
    } finally {
      _inactivityActionInFlight = false;
    }
  }

  Future<void> _resumeTimer({
    required bool manual,
    String? resumedBy,
  }) async {
    if (_inactivityActionInFlight) {
      return;
    }
    _inactivityActionInFlight = true;
    try {
      final eventAt = DateTime.now();
      await _applySnapshot(
        await _api.resumeTimer(
          resumedBy: manual ? 'manual' : resumedBy,
          clientEventAt: eventAt,
        ),
      );
      if (manual || resumedBy == 'inactivity') {
        autoPausedByInactivity = false;
      }
    } on DesktopApiException catch (e) {
      if (e.statusCode == 401) {
        await _onRequireLogin();
      }
    } finally {
      _inactivityActionInFlight = false;
    }
  }

  Future<void> _startTask({
    required int projectId,
    required int taskId,
  }) async {
    try {
      autoPausedByInactivity = false;
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
