import 'package:flutter/material.dart';

import 'services/app_controller.dart';
import 'theme/app_theme.dart';
import 'ui/login_page.dart';
import 'ui/my_work/my_work_page.dart';
import 'ui/settings_page.dart';
import 'ui/task/task_detail_page.dart';

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
          onGenerateRoute: (settings) {
            switch (settings.name) {
              case '/login':
                return MaterialPageRoute<void>(
                  settings: settings,
                  builder: (_) => LoginPage(controller: controller),
                );
              case '/my-work':
                return MaterialPageRoute<void>(
                  settings: settings,
                  builder: (_) => MyWorkPage(controller: controller),
                );
              case '/settings':
                return MaterialPageRoute<void>(
                  settings: settings,
                  builder: (_) => SettingsPage(controller: controller),
                );
              case '/tasks':
                final args = settings.arguments;
                if (args is! TaskDetailRouteArgs) {
                  return null;
                }
                return MaterialPageRoute<void>(
                  settings: settings,
                  builder: (_) => TaskDetailPage(
                    controller: controller,
                    projectId: args.projectId,
                    taskId: args.taskId,
                  ),
                );
            }
            return null;
          },
        );
      },
    );
  }
}
