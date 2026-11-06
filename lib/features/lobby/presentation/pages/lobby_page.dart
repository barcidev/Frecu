import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:frecu/app/router/app_router.gr.dart';
import 'package:frecu/i18n/strings.g.dart';

/// Pantalla principal (Lobby) para crear o unirse a una frecu.
@RoutePage()
class LobbyPage extends StatelessWidget {
  /// Constructor constante.
  const LobbyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(t.lobby.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.router.push(const SettingsRoute()),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FilledButton.icon(
                icon: const Icon(Icons.add_circle_outline),
                label: Text(t.lobby.createRoom),
                onPressed: () => context.router.push(const CreateRoomRoute()),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                icon: const Icon(Icons.qr_code_scanner),
                label: Text(t.lobby.scanQr),
                onPressed: () => context.router.push(const ScanQrRoute()),
              ),
              const SizedBox(height: 32),
              Text(
                t.lobby.nearbyRooms,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                t.lobby.noRoomsNearby,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
