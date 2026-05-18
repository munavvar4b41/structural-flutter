import 'package:flutter/material.dart';

import '../config/desktop_config.dart';
import '../services/app_controller.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.controller});

  final AppController controller;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final TextEditingController _apiUrlController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _apiUrlController = TextEditingController(
      text: widget.controller.authStore.apiBaseUrl(),
    );
  }

  @override
  void dispose() {
    _apiUrlController.dispose();
    super.dispose();
  }

  Future<void> _saveApiUrl() async {
    setState(() => _saving = true);
    await widget.controller.authStore.saveApiBaseUrl(_apiUrlController.text);
    if (mounted) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('API URL saved.')),
      );
    }
  }

  Future<void> _logout() async {
    await widget.controller.logout();
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.controller.authStore.user;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'API',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _apiUrlController,
            decoration: InputDecoration(
              labelText: 'Laravel base URL',
              hintText: DesktopConfig.defaultApiBaseUrl,
              border: const OutlineInputBorder(),
              helperText:
                  'Override with --dart-define=API_BASE_URL=... at build time.',
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _saving ? null : _saveApiUrl,
            child: const Text('Save API URL'),
          ),
          const SizedBox(height: 32),
          if (user != null) ...[
            Text(
              'Signed in as ${user.name}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            Text(user.email),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _logout,
              child: const Text('Log out'),
            ),
          ],
        ],
      ),
    );
  }
}
