import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frecu/app/router/app_router.gr.dart';
import 'package:frecu/core/constants/network_constants.dart';
import 'package:frecu/core/result/result.dart';
import 'package:frecu/features/lobby/domain/entities/nearby_room.dart';
import 'package:frecu/features/lobby/presentation/providers/discovery_provider.dart';
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

  Future<void> _showPinDialog(BuildContext context, NearbyRoom room) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => _PinJoinDialog(room: room),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nearbyAsync = ref.watch(nearbyRoomsProvider);

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
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            FilledButton.icon(
              icon: const Icon(Icons.add_circle_outline),
              label: Text(t.lobby.createRoom),
              onPressed: () => context.router.push(const CreateRoomRoute()),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.wifi),
              label: Text(t.lobby.joinRoom),
              onPressed: () => _showJoinDialog(context),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.qr_code_scanner),
              label: Text(t.lobby.scanQr),
              onPressed: () => context.router.push(ScanQrRoute()),
            ),
            const SizedBox(height: 24),
            Text(
              t.lobby.nearbyRooms,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _NearbyRoomsList(
                nearbyAsync: nearbyAsync,
                onRoomSelected: (room) => _showPinDialog(context, room),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NearbyRoomsList extends StatelessWidget {
  const _NearbyRoomsList({
    required this.nearbyAsync,
    required this.onRoomSelected,
  });

  final AsyncValue<List<NearbyRoom>> nearbyAsync;
  final ValueChanged<NearbyRoom> onRoomSelected;

  @override
  Widget build(BuildContext context) {
    return nearbyAsync.when(
      data: (rooms) {
        if (rooms.isEmpty) {
          return Center(
            child: Text(
              t.lobby.noRoomsNearby,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          );
        }
        return ListView.builder(
          itemCount: rooms.length,
          itemBuilder: (context, index) {
            final room = rooms[index];
            return Card(
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.radio)),
                title: Text(room.name),
                subtitle: Text('IP: ${room.hostAddress}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => onRoomSelected(room),
              ),
            );
          },
        );
      },
      loading: () => Center(
        child: Text(
          t.lobby.noRoomsNearby,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

class _PinJoinDialog extends ConsumerStatefulWidget {
  const _PinJoinDialog({required this.room});

  final NearbyRoom room;

  @override
  ConsumerState<_PinJoinDialog> createState() => _PinJoinDialogState();
}

class _PinJoinDialogState extends ConsumerState<_PinJoinDialog> {
  final _pinController = TextEditingController(text: '1234');
  final _nameController = TextEditingController(text: 'Participante');
  bool _isLoading = false;

  @override
  void dispose() {
    _pinController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleJoin() async {
    setState(() => _isLoading = true);
    final result = await ref
        .read(roomNotifierProvider.notifier)
        .joinRoom(
          hostAddress: widget.room.hostAddress,
          port: widget.room.port,
          accessCode: _pinController.text.trim(),
          displayName: _nameController.text.trim(),
        );

    if (!mounted) return;
    setState(() => _isLoading = false);
    Navigator.of(context).pop();

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
      title: Text('Unirse a ${widget.room.name}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _pinController,
            decoration: InputDecoration(labelText: t.lobby.accessCode),
            keyboardType: TextInputType.number,
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
        FilledButton(
          key: const Key('pin_join_button'),
          onPressed: _isLoading ? null : _handleJoin,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Unirse'),
        ),
      ],
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
