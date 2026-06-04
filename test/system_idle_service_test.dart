import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:structural_flutter/services/system_idle_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('structural/system_idle');
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
  });

  test('does not poll when system idle unsupported', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'isSupported') {
        return false;
      }

      return null;
    });

    final service = SystemIdleService(
      idleThreshold: const Duration(minutes: 10),
      channel: channel,
    );

    var callbackCount = 0;
    await service.startPolling(onIdleChanged: (_) async {
      callbackCount++;
    });

    expect(service.isSupported, isFalse);
    expect(callbackCount, 0);
    await service.stopPolling();
  });

  test('reports idle transition when threshold reached', () async {
    var idleValue = 150000;

    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'isSupported') {
        return true;
      }
      if (call.method == 'getIdleMilliseconds') {
        return idleValue;
      }

      return null;
    });

    final service = SystemIdleService(
      idleThreshold: const Duration(minutes: 10),
      pollInterval: const Duration(milliseconds: 50),
      channel: channel,
    );

    final states = <bool>[];
    await service.startPolling(onIdleChanged: (isIdle) async {
      states.add(isIdle);
    });
    expect(states, [true]);

    idleValue = 1000;
    await Future<void>.delayed(const Duration(milliseconds: 80));
    expect(states, [true, false]);

    await service.stopPolling();
  });
}