import 'dart:io';

import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import 'auth_store.dart';
import 'desktop_api_client.dart';
import 'notification_service.dart';
import 'tray_service.dart';

class AppController extends ChangeNotifier with WindowListener {
  AppController() {
    authStore = AuthStore();
    api = DesktopApiClient(authStore);
    notifications = NotificationService(api: api);
    tray = TrayService(
      api: api,
      onViewAllTasks: showMyWork,
      onOpenSettings: showSettings,
      onRequireLogin: requireLogin,
      onQuit: quit,
    );
    tray.addListener(notifyListeners);
    notifications.addListener(notifyListeners);
  }

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  late final AuthStore authStore;
  late final DesktopApiClient api;
  late final NotificationService notifications;
  late final TrayService tray;

  bool _initialized = false;
  bool _sessionReady = false;

  bool get initialized => _initialized;
  bool get sessionReady => _sessionReady;

  Future<void> init() async {
    await authStore.load();

    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      await windowManager.ensureInitialized();
      const windowOptions = WindowOptions(
        size: Size(1280, 800),
        minimumSize: Size(900, 600),
        center: true,
        title: 'structural',
      );
      windowManager.addListener(this);
      await windowManager.waitUntilReadyToShow(windowOptions, () async {
        await windowManager.show();
        await windowManager.focus();
      });
      await windowManager.setPreventClose(true);
      await tray.init();
    }

    if (authStore.isAuthenticated) {
      await tray.start();
      notifications.start();
      _sessionReady = true;
    }

    _initialized = true;
    notifyListeners();
  }

  Future<void> onLoginSuccess() async {
    await tray.start();
    notifications.start();
    _sessionReady = true;
    notifyListeners();
    navigatorKey.currentState?.pushNamedAndRemoveUntil(
      '/my-work',
      (route) => false,
    );
  }

  Future<void> requireLogin() async {
    await tray.stop();
    notifications.stop();
    await authStore.clearSession();
    _sessionReady = false;
    notifyListeners();
    navigatorKey.currentState?.pushNamedAndRemoveUntil(
      '/login',
      (route) => false,
    );
  }

  Future<void> logout() async {
    try {
      await api.logout();
    } catch (_) {
      // Clear local session even if remote logout fails.
    }
    await tray.stop();
    notifications.stop();
    await authStore.clearSession();
    _sessionReady = false;
    notifyListeners();
    navigatorKey.currentState?.pushNamedAndRemoveUntil(
      '/login',
      (route) => false,
    );
  }

  void openTaskDetail({required int projectId, required int taskId}) {
    navigatorKey.currentState?.pushNamed(
      '/tasks',
      arguments: TaskDetailRouteArgs(projectId: projectId, taskId: taskId),
    );
  }

  Future<void> showMyWork() async {
    final navigator = navigatorKey.currentState;
    if (navigator == null || !navigator.mounted) {
      return;
    }
    final currentRoute = ModalRoute.of(navigator.context)?.settings.name;
    if (currentRoute == '/my-work') {
      if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
        await windowManager.show();
        await windowManager.focus();
      }
      return;
    }

    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      await windowManager.show();
      await windowManager.focus();
    }
    if (!navigator.mounted) {
      return;
    }
    await navigator.pushNamedAndRemoveUntil(
      '/my-work',
      (route) => route.settings.name == '/login',
    );
  }

  Future<void> showSettings() async {
    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      await windowManager.show();
      await windowManager.focus();
    }
    navigatorKey.currentState?.pushNamed('/settings');
  }

  Future<void> quit() async {
    await tray.stop();
    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      await windowManager.destroy();
    }
    exit(0);
  }

  @override
  void onWindowClose() async {
    await windowManager.hide();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    notifications.dispose();
    tray.dispose();
    super.dispose();
  }
}

class TaskDetailRouteArgs {
  const TaskDetailRouteArgs({
    required this.projectId,
    required this.taskId,
  });

  final int projectId;
  final int taskId;
}
