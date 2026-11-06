import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:frecu/i18n/strings.g.dart';

/// Pantalla de configuración y preferencias de la aplicación.
@RoutePage()
class SettingsPage extends StatelessWidget {
  /// Constructor constante.
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(t.settings.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: const Icon(Icons.person),
            title: Text(t.settings.displayName),
            subtitle: const Text('Usuario'),
          ),
          ListTile(
            leading: const Icon(Icons.mic),
            title: Text(t.settings.defaultTalkMode),
            subtitle: Text(t.room.pushToTalk),
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(t.settings.language),
            subtitle: const Text('Español'),
          ),
        ],
      ),
    );
  }
}
