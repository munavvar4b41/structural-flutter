import 'dart:async';

import 'package:flutter/services.dart';

class SystemIdleService {
  SystemIdleService({
    required this.idleThreshold,
    this.pollInterval = const Duration(seconds: 5),
    MethodChannel? channel,
  }) : _channel = channel ?? const MethodChannel(_channelName);

  static const String _channelName = 'structural/system_idle';

  final Duration idleThreshold;
  final Duration pollInterval;
  final MethodChannel _channel;

  Timer? _pollTimer;
  bool _isSupported = false;
  bool _isIdle = false;

  bool get isSupported => _isSupported;
  bool get isIdle => _isIdle;

  Future<void> startPolling({
    required Future<void> Function(bool isIdle) onIdleChanged,
  }) async {
    _isSupported = await _fetchSupported();
    if (!_isSupported) {
      // Session D-Bus (Mutter IdleMonitor) may not be ready at app startup.
      await Future<void>.delayed(const Duration(seconds: 2));
      _isSupported = await _fetchSupported();
    }
    if (!_isSupported) {
      return;
    }

    await _pollOnce(onIdleChanged: onIdleChanged);
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(pollInterval, (_) {
      unawaited(_pollOnce(onIdleChanged: onIdleChanged));
    });
  }

  Future<void> stopPolling() async {
    _pollTimer?.cancel();
    _pollTimer = null;
    _isIdle = false;
  }

  Future<int?> getIdleMilliseconds() async {
    try {
      return await _channel.invokeMethod<int>('getIdleMilliseconds');
    } on PlatformException {
      return null;
    }
  }

  Future<bool> _fetchSupported() async {
    try {
      return await _channel.invokeMethod<bool>('isSupported') ?? false;
    } on PlatformException {
      return false;
    }
  }

  Future<void> _pollOnce({
    required Future<void> Function(bool isIdle) onIdleChanged,
  }) async {
    final idleMs = await getIdleMilliseconds();
    if (idleMs == null) {
      return;
    }

    final nextIsIdle = idleMs >= idleThreshold.inMilliseconds;
    if (nextIsIdle == _isIdle) {
      return;
    }

    _isIdle = nextIsIdle;
    await onIdleChanged(_isIdle);
  }
}
