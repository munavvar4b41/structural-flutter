import 'package:flutter/material.dart';

import 'services/app_controller.dart';
import 'theme/app_theme.dart';
import 'ui/login_page.dart';
import 'ui/my_work/my_work_page.dart';
import 'ui/settings_page.dart';

class StructuralApp extends StatelessWidget {
  const StructuralApp({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        if (!controller.initialized) {
          return MaterialApp(
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: ThemeMode.system,
            home: const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final initialRoute =
            controller.sessionReady ? '/my-work' : '/login';

        return MaterialApp(
          navigatorKey: controller.navigatorKey,
          title: 'structural',
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: ThemeMode.system,
          initialRoute: initialRoute,
          routes: {
            '/login': (_) => LoginPage(controller: controller),
            '/my-work': (_) => MyWorkPage(controller: controller),
            '/settings': (_) => SettingsPage(controller: controller),
          },
        );
      },
    );
  }
}
