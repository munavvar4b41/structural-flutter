import 'dart:io';

import 'package:flutter/material.dart';

import 'app.dart';
import 'services/app_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!Platform.isLinux && !Platform.isWindows && !Platform.isMacOS) {
    runApp(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('structural desktop runs on Linux, Windows, or macOS.'),
          ),
        ),
      ),
    );
    return;
  }

  final controller = AppController();
  await controller.init();
  runApp(StructuralApp(controller: controller));
}
