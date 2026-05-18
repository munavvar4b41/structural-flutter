import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class AssetPaths {
  AssetPaths._();

  static final Map<String, String> _cache = {};

  static Future<String> resolve(String assetPath) async {
    final cached = _cache[assetPath];
    if (cached != null) {
      return cached;
    }

    final bytes = await rootBundle.load(assetPath);
    final directory = await getApplicationSupportDirectory();
    final trayDir = Directory('${directory.path}/tray_assets');
    if (!await trayDir.exists()) {
      await trayDir.create(recursive: true);
    }

    final fileName = assetPath.split('/').last;
    final file = File('${trayDir.path}/$fileName');
    await file.writeAsBytes(
      bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
      flush: true,
    );
    _cache[assetPath] = file.path;
    return file.path;
  }

  static Future<void> preloadTrayIcons() async {
    for (final asset in [
      'assets/tray/stop.png',
      'assets/tray/pause.png',
      'assets/tray/resume.png',
      'assets/tray/refresh.png',
      'assets/tray/play.png',
    ]) {
      await resolve(asset);
    }
  }
}
