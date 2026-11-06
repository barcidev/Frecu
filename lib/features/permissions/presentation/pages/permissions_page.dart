import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:frecu/i18n/strings.g.dart';

/// Pantalla de onboarding y solicitud de permisos del sistema.
@RoutePage()
class PermissionsPage extends StatelessWidget {
  /// Constructor constante.
  const PermissionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(t.permissions.title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.security, size: 64),
              const SizedBox(height: 16),
              Text(t.permissions.description, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              FilledButton(onPressed: () {}, child: Text(t.permissions.grant)),
            ],
          ),
        ),
      ),
    );
  }
}
