import 'package:dio/dio.dart';

import '../models/auth_user.dart';
import '../models/my_work_board.dart';
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

  Future<TraySnapshot> pauseTimer() async {
    return _timerAction('$_baseUrl/api/desktop/timer/pause');
  }

  Future<TraySnapshot> resumeTimer() async {
    return _timerAction('$_baseUrl/api/desktop/timer/resume');
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
