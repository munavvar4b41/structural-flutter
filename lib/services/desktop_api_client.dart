import 'package:dio/dio.dart';

import '../models/auth_user.dart';
import '../models/my_work_board.dart';
import '../models/notifications.dart';
import '../models/task_form_options.dart';
import '../models/task_show.dart';
import '../models/tray_snapshot.dart';
import 'auth_store.dart';

class DesktopApiException implements Exception {
  DesktopApiException(this.message, {this.statusCode, this.errors});

  final String message;
  final int? statusCode;
  final Map<String, dynamic>? errors;

  @override
  String toString() => message;
}

class DesktopApiClient {
  DesktopApiClient(this._authStore) {
    _dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'Accept': 'application/json'},
      ),
    );
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = _authStore.token;
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
  }

  final AuthStore _authStore;
  late final Dio _dio;

  String get _baseUrl => _authStore.apiBaseUrl();

  Future<LoginResult> login({
    required String email,
    required String password,
    String deviceName = 'structural-desktop',
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '$_baseUrl/api/desktop/login',
        data: {
          'email': email,
          'password': password,
          'device_name': deviceName,
        },
      );
      return LoginResult.fromJson(response.data!);
    } on DioException catch (e) {
      throw _mapError(e, fallback: 'Login failed.');
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post('$_baseUrl/api/desktop/logout');
    } on DioException catch (e) {
      if (e.response?.statusCode != 401) {
        throw _mapError(e, fallback: 'Logout failed.');
      }
    }
  }

  Future<TraySnapshot> fetchTray() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '$_baseUrl/api/desktop/tray',
      );
      return TraySnapshot.fromJson(
        _decodeMap(response.data, context: 'tray API'),
      );
    } on DioException catch (e) {
      throw _mapError(e, fallback: 'Could not load tray data.');
    }
  }

  Future<MyWorkBoard> fetchMyWork({
    int? projectId,
    Map<String, int>? columnPages,
  }) async {
    try {
      final query = <String, dynamic>{};
      if (projectId != null) {
        query['project_id'] = projectId;
      }
      columnPages?.forEach((status, page) {
        query['page_$status'] = page;
      });

      final response = await _dio.get<Map<String, dynamic>>(
        '$_baseUrl/api/desktop/my-work',
        queryParameters: query.isEmpty ? null : query,
      );
      return MyWorkBoard.fromJson(
        _decodeMap(response.data, context: 'my-work API'),
      );
    } on DioException catch (e) {
      throw _mapError(e, fallback: 'Could not load My Work board.');
    }
  }

  Future<TraySnapshot> startTimer({
    required int projectId,
    required int taskId,
  }) async {
    return _timerAction(
      '$_baseUrl/api/desktop/timer/start',
      data: {'project_id': projectId, 'task_id': taskId},
    );
  }

  Future<TraySnapshot> stopTimer() async {
    return _timerAction('$_baseUrl/api/desktop/timer/stop');
  }

  Future<TraySnapshot> pauseTimer({
    String? reason,
    DateTime? clientEventAt,
  }) async {
    return _timerAction(
      '$_baseUrl/api/desktop/timer/pause',
      data: _timerMetadata(reason: reason, clientEventAt: clientEventAt),
    );
  }

  Future<TraySnapshot> resumeTimer({
    String? resumedBy,
    DateTime? clientEventAt,
  }) async {
    return _timerAction(
      '$_baseUrl/api/desktop/timer/resume',
      data: _timerMetadata(
        resumedBy: resumedBy,
        clientEventAt: clientEventAt,
      ),
    );
  }

  Map<String, dynamic>? _timerMetadata({
    String? reason,
    String? resumedBy,
    DateTime? clientEventAt,
  }) {
    final data = <String, dynamic>{};
    if (reason != null) {
      data['reason'] = reason;
    }
    if (resumedBy != null) {
      data['resumed_by'] = resumedBy;
    }
    if (clientEventAt != null) {
      data['client_event_at'] = clientEventAt.toUtc().toIso8601String();
    }

    return data.isEmpty ? null : data;
  }

  Map<String, dynamic> _decodeMap(dynamic raw, {required String context}) {
    if (raw == null) {
      throw FormatException('Empty response from $context');
    }
    if (raw is Map<String, dynamic>) {
      return raw;
    }
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    throw FormatException('Expected JSON object from $context');
  }

  Future<TraySnapshot> _timerAction(
    String url, {
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(url, data: data);
      return TraySnapshot.fromJson(_decodeMap(response.data, context: url));
    } on DioException catch (e) {
      throw _mapError(e, fallback: 'Timer action failed.');
    }
  }

  Future<NotificationFeed> fetchNotifications() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '$_baseUrl/api/desktop/notifications',
      );
      return NotificationFeed.fromJson(
        _decodeMap(response.data, context: 'notifications API'),
      );
    } on DioException catch (e) {
      throw _mapError(e, fallback: 'Could not load notifications.');
    }
  }

  Future<NotificationFeed> markNotificationRead(String notificationId) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        '$_baseUrl/api/desktop/notifications/$notificationId',
      );
      return NotificationFeed.fromJson(
        _decodeMap(response.data, context: 'mark notification read'),
      );
    } on DioException catch (e) {
      throw _mapError(e, fallback: 'Could not mark notification as read.');
    }
  }

  Future<NotificationFeed> markAllNotificationsRead() async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        '$_baseUrl/api/desktop/notifications/mark-all-read',
      );
      return NotificationFeed.fromJson(
        _decodeMap(response.data, context: 'mark all notifications read'),
      );
    } on DioException catch (e) {
      throw _mapError(e, fallback: 'Could not mark all notifications as read.');
    }
  }

  Future<TaskShowPayload> fetchTaskShow({
    required int projectId,
    required int taskId,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '$_baseUrl/api/desktop/projects/$projectId/tasks/$taskId',
      );
      return TaskShowPayload.fromJson(
        _decodeMap(response.data, context: 'task show API'),
      );
    } on DioException catch (e) {
      throw _mapError(e, fallback: 'Could not load task.');
    }
  }

  Future<TaskFormOptions> fetchTaskFormOptions({
    required int projectId,
    int? excludeTaskId,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '$_baseUrl/api/desktop/projects/$projectId/tasks/form-options',
        queryParameters: excludeTaskId != null
            ? {'exclude_task_id': excludeTaskId}
            : null,
      );
      return TaskFormOptions.fromJson(
        _decodeMap(response.data, context: 'task form options API'),
      );
    } on DioException catch (e) {
      throw _mapError(e, fallback: 'Could not load task form options.');
    }
  }

  Future<TaskShowPayload> createTask({
    required int projectId,
    required Map<String, dynamic> data,
  }) async {
    return _taskMutation(
      '$_baseUrl/api/desktop/projects/$projectId/tasks',
      method: 'post',
      data: data,
      fallback: 'Could not create task.',
    );
  }

  Future<TaskShowPayload> updateTask({
    required int projectId,
    required int taskId,
    required Map<String, dynamic> data,
  }) async {
    return _taskMutation(
      '$_baseUrl/api/desktop/projects/$projectId/tasks/$taskId',
      method: 'patch',
      data: data,
      fallback: 'Could not update task.',
    );
  }

  Future<void> deleteTask({
    required int projectId,
    required int taskId,
  }) async {
    try {
      await _dio.delete(
        '$_baseUrl/api/desktop/projects/$projectId/tasks/$taskId',
      );
    } on DioException catch (e) {
      throw _mapError(e, fallback: 'Could not delete task.');
    }
  }

  Future<TaskShowPayload> submitTaskCompletion({
    required int projectId,
    required int taskId,
  }) async {
    return _taskMutation(
      '$_baseUrl/api/desktop/projects/$projectId/tasks/$taskId/submit-completion',
      method: 'post',
      fallback: 'Could not submit task for completion.',
    );
  }

  Future<TaskShowPayload> confirmTaskCompletion({
    required int projectId,
    required int taskId,
    required Map<String, dynamic> data,
  }) async {
    return _taskMutation(
      '$_baseUrl/api/desktop/projects/$projectId/tasks/$taskId/confirm-completion',
      method: 'post',
      data: data,
      fallback: 'Could not confirm task completion.',
    );
  }

  Future<TaskShowPayload> createChecklistItem({
    required int projectId,
    required int taskId,
    required String title,
  }) async {
    return _taskMutation(
      '$_baseUrl/api/desktop/projects/$projectId/tasks/$taskId/checklist-items',
      method: 'post',
      data: {'title': title},
      fallback: 'Could not add checklist item.',
    );
  }

  Future<TaskShowPayload> updateChecklistItem({
    required int projectId,
    required int taskId,
    required int itemId,
    required Map<String, dynamic> data,
  }) async {
    return _taskMutation(
      '$_baseUrl/api/desktop/projects/$projectId/tasks/$taskId/checklist-items/$itemId',
      method: 'patch',
      data: data,
      fallback: 'Could not update checklist item.',
    );
  }

  Future<TaskShowPayload> deleteChecklistItem({
    required int projectId,
    required int taskId,
    required int itemId,
  }) async {
    return _taskMutation(
      '$_baseUrl/api/desktop/projects/$projectId/tasks/$taskId/checklist-items/$itemId',
      method: 'delete',
      fallback: 'Could not delete checklist item.',
    );
  }

  Future<TaskShowPayload> createTimeEntry({
    required int projectId,
    required int taskId,
    required Map<String, dynamic> data,
  }) async {
    return _taskMutation(
      '$_baseUrl/api/desktop/projects/$projectId/tasks/$taskId/time-entries',
      method: 'post',
      data: data,
      fallback: 'Could not add time entry.',
    );
  }

  Future<TaskShowPayload> updateTimeEntry({
    required int projectId,
    required int taskId,
    required int entryId,
    required Map<String, dynamic> data,
  }) async {
    return _taskMutation(
      '$_baseUrl/api/desktop/projects/$projectId/tasks/$taskId/time-entries/$entryId',
      method: 'patch',
      data: data,
      fallback: 'Could not update time entry.',
    );
  }

  Future<TaskShowPayload> deleteTimeEntry({
    required int projectId,
    required int taskId,
    required int entryId,
  }) async {
    return _taskMutation(
      '$_baseUrl/api/desktop/projects/$projectId/tasks/$taskId/time-entries/$entryId',
      method: 'delete',
      fallback: 'Could not delete time entry.',
    );
  }

  Future<TaskShowPayload> _taskMutation(
    String url, {
    required String method,
    Map<String, dynamic>? data,
    required String fallback,
  }) async {
    try {
      final Response<Map<String, dynamic>> response;
      switch (method) {
        case 'post':
          response = await _dio.post<Map<String, dynamic>>(url, data: data);
        case 'patch':
          response = await _dio.patch<Map<String, dynamic>>(url, data: data);
        case 'delete':
          response = await _dio.delete<Map<String, dynamic>>(url);
        default:
          throw ArgumentError('Unsupported method: $method');
      }
      return TaskShowPayload.fromJson(
        _decodeMap(response.data, context: url),
      );
    } on DioException catch (e) {
      throw _mapError(e, fallback: fallback);
    }
  }

  DesktopApiException _mapError(DioException e, {required String fallback}) {
    final response = e.response;
    final data = response?.data;
    if (data is Map<String, dynamic>) {
      final message = data['message'] as String?;
      final errors = data['errors'] as Map<String, dynamic>?;
      if (errors != null && errors.isNotEmpty) {
        final first = errors.values.first;
        if (first is List && first.isNotEmpty) {
          return DesktopApiException(
            first.first.toString(),
            statusCode: response?.statusCode,
            errors: errors,
          );
        }
      }
      if (message != null && message.isNotEmpty) {
        return DesktopApiException(
          message,
          statusCode: response?.statusCode,
          errors: errors,
        );
      }
    }
    if (e.type == DioExceptionType.connectionError) {
      return DesktopApiException(
        'Cannot reach API at $_baseUrl',
        statusCode: response?.statusCode,
      );
    }
    return DesktopApiException(
      fallback,
      statusCode: response?.statusCode,
    );
  }
}
