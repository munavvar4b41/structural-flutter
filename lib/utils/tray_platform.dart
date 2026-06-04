import 'dart:io';

import 'package:tray_manager/tray_manager.dart';

import '../models/tray_snapshot.dart';
import 'duration_format.dart';

/// Wraps tray_manager calls that are not implemented on every platform.
class TrayPlatform {
  TrayPlatform._();

  static const trayIconAsset = 'assets/icons/app.png';

  /// Hover text: [setToolTip] on Windows/macOS; [setTitle] on Linux (AppIndicator label).
  static Future<void> setHoverLabel(String label) async {
    if (Platform.isLinux) {
      try {
        await trayManager.setTitle(label);
      } catch (_) {
        // setTitle requires an active indicator; ignore if not ready yet.
      }
      return;
    }
    if (Platform.isWindows || Platform.isMacOS) {
      await trayManager.setToolTip(label);
    }
  }

  /// Linux attaches the menu to the indicator; popup is only needed on Windows/macOS.
  static Future<void> popUpContextMenuIfSupported() async {
    if (Platform.isWindows || Platform.isMacOS) {
      await trayManager.popUpContextMenu();
    }
  }

  /// Tray indicator label from snapshot + locally ticked elapsed time (today total).
  static String formatTrayLabel({
    required TraySnapshot? snapshot,
    required DateTime? snapshotFetchedAt,
    required bool showInactiveBadge,
    bool systemIdleUnavailable = false,
  }) {
    if (systemIdleUnavailable) {
      return 'structural · system idle unavailable';
    }

    final active = snapshot?.active;
    if (active == null) {
      return showInactiveBadge ? '🔴 structural' : 'structural';
    }

    var seconds = active.taskTodaySeconds;
    if (!active.isPaused && snapshotFetchedAt != null) {
      final segmentTick =
          DateTime.now().difference(snapshotFetchedAt).inSeconds;
      final todayBase = active.taskTodaySeconds - active.elapsedSeconds;
      seconds = todayBase + active.elapsedSeconds + segmentTick;
    }

    final elapsed = formatElapsed(Duration(seconds: seconds));
    final description = active.descriptionTray.isNotEmpty
        ? active.descriptionTray
        : (active.description.isNotEmpty
            ? active.description
            : active.taskTitleTray);
    if (active.isPaused) {
      final base = '$description · $elapsed (paused)';
      return showInactiveBadge ? '🔴 $base' : base;
    }
    final base = '$description · $elapsed';
    return showInactiveBadge ? '🔴 $base' : base;
  }

  static bool get menuIconsSupported => Platform.isWindows || Platform.isMacOS;
}
