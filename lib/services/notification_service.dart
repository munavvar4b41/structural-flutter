import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/notifications.dart';
import 'desktop_api_client.dart';

class NotificationService extends ChangeNotifier {
  NotificationService({required DesktopApiClient api}) : _api = api;

  final DesktopApiClient _api;
  Timer? _pollTimer;

  NotificationFeed? _feed;
  bool _loading = false;
  String? _error;

  NotificationFeed? get feed => _feed;
  bool get loading => _loading;
  String? get error => _error;
  int get unreadCount => _feed?.unreadCount ?? 0;
  List<NotificationItem> get unreadItems => _feed?.unreadItems ?? [];
  List<NotificationItem> get readItems => _feed?.readItems ?? [];

  void start() {
    _pollTimer?.cancel();
    unawaited(refresh());
    _pollTimer = Timer.periodic(
      const Duration(seconds: 60),
      (_) => unawaited(refresh(silent: true)),
    );
  }

  void stop() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _feed = null;
    _error = null;
    _loading = false;
    notifyListeners();
  }

  Future<void> refresh({bool silent = false}) async {
    if (!silent) {
      _loading = true;
      _error = null;
      notifyListeners();
    }

    try {
      _feed = await _api.fetchNotifications();
      _error = null;
    } on DesktopApiException catch (e) {
      _error = e.message;
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> markRead(String notificationId) async {
    _feed = await _api.markNotificationRead(notificationId);
    notifyListeners();
  }

  Future<void> markAllRead() async {
    _feed = await _api.markAllNotificationsRead();
    notifyListeners();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}
