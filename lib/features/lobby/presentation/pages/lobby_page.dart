import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frecu/app/router/app_router.gr.dart';
import 'package:frecu/core/constants/network_constants.dart';
import 'package:frecu/core/result/result.dart';
import 'package:frecu/features/room/presentation/providers/room_provider.dart';
import 'package:frecu/i18n/strings.g.dart';

/// Pantalla principal (Lobby) para crear o unirse a una frecu.
@RoutePage()
class LobbyPage extends ConsumerWidget {
  /// Constructor constante.
  const LobbyPage({super.key});

  Future<void> _showJoinDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => const _JoinRoomDialog(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                icon: const Icon(Icons.wifi),
                label: Text(t.lobby.joinRoom),
                onPressed: () => _showJoinDialog(context),
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

class _JoinRoomDialog extends ConsumerStatefulWidget {
  const _JoinRoomDialog();

  @override
  ConsumerState<_JoinRoomDialog> createState() => _JoinRoomDialogState();
}

class _JoinRoomDialogState extends ConsumerState<_JoinRoomDialog> {
  final _ipController = TextEditingController(text: '192.168.43.1');
  final _codeController = TextEditingController(text: '1234');
  final _nameController = TextEditingController(text: 'Participante');

  @override
  void dispose() {
    _ipController.dispose();
    _codeController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleConnect() async {
    Navigator.of(context).pop();
    final result = await ref
        .read(roomNotifierProvider.notifier)
        .joinRoom(
          hostAddress: _ipController.text.trim(),
          port: NetworkConstants.signalingPort,
          accessCode: _codeController.text.trim(),
          displayName: _nameController.text.trim(),
        );
    if (!mounted) return;
    switch (result) {
      case Success(:final data):
        unawaited(context.router.push(RoomRoute(roomId: data.id)));
      case FailureResult(:final failure):
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(failure.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(t.lobby.joinRoom),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _ipController,
            decoration: const InputDecoration(labelText: 'IP del anfitrión'),
          ),
          TextField(
            controller: _codeController,
            decoration: InputDecoration(labelText: t.lobby.accessCode),
            maxLength: 4,
          ),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(labelText: t.lobby.yourName),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _handleConnect, child: const Text('Conectar')),
      ],
    );
  }
}
