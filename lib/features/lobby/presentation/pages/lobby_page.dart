import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frecu/app/router/app_router.gr.dart';
import 'package:frecu/core/constants/network_constants.dart';
import 'package:frecu/core/design/widgets/fr_scaffold.dart';
import 'package:frecu/core/result/result.dart';
import 'package:frecu/features/lobby/domain/entities/nearby_room.dart';
import 'package:frecu/features/lobby/presentation/extensions/display_name_extension.dart';
import 'package:frecu/features/lobby/presentation/providers/discovery_provider.dart';
import 'package:frecu/features/lobby/presentation/widgets/lobby_sections.dart';
import 'package:frecu/features/lobby/presentation/widgets/lobby_tuner.dart';
import 'package:frecu/features/lobby/presentation/widgets/nearby_room_tile.dart';
import 'package:frecu/features/lobby/presentation/widgets/pin_join_sheet.dart';
import 'package:frecu/features/network/domain/entities/network_state.dart';
import 'package:frecu/features/network/presentation/providers/network_provider.dart';
import 'package:frecu/features/room/domain/entities/room.dart';
import 'package:frecu/features/room/presentation/extensions/failure_extension.dart';
import 'package:frecu/features/room/presentation/providers/room_provider.dart';
import 'package:frecu/i18n/strings.g.dart';

/// Inicio en Portadora (pantalla `lobby` del prototipo): la marca, el
/// estado de la red local y Ajustes; el sintonizador de dos octavas con un
/// pico por frecu cercana; la lista de frecus o la búsqueda vacía, o el
/// aviso sin red; y abajo Crear frecu, Escanear y Conectar por IP.
///
/// Tocar una frecu la elige (tarjeta encendida y aguja a su nota) y abre la
/// hoja de código ([PinJoinSheet]); la elección sigue hasta tocar otra o
/// hasta que esa frecu desaparece de la lista.
@RoutePage()
class LobbyPage extends ConsumerStatefulWidget {
  /// Constructor constante.
  const LobbyPage({super.key});

  @override
  ConsumerState<LobbyPage> createState() => _LobbyPageState();
}

class _LobbyPageState extends ConsumerState<LobbyPage> {
  /// Estado de la red local; hasta el primer valor no se sabe.
  late final Stream<NetworkState> _network;

  /// Frecu elegida.
  String? _selectedRoomId;

  @override
  void initState() {
    super.initState();
    _network = ref.read(networkRepositoryProvider).watchNetworkState();
  }

  Future<void> _showJoinDialog() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => const _JoinRoomDialog(),
    );
  }

  /// Elige [room] y abre su hoja de código; si se une, la frecu activa.
  Future<void> _select(NearbyRoom room) async {
    setState(() => _selectedRoomId = room.roomId);
    final joined = await PinJoinSheet.show(context, room);
    _open(joined);
  }

  void _open(Room? room) {
    if (room == null || !mounted) return;
    unawaited(context.router.push(RoomRoute(roomId: room.id)));
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(nearbyRoomsProvider, (_, next) {
      final rooms = next.value ?? const <NearbyRoom>[];
      if (_selectedRoomId != null &&
          !rooms.any((room) => room.roomId == _selectedRoomId)) {
        setState(() => _selectedRoomId = null);
      }
    });
    final rooms = ref.watch(nearbyRoomsProvider).value ?? const <NearbyRoom>[];
    final selected = rooms
        .where((room) => room.roomId == _selectedRoomId)
        .firstOrNull;
    return StreamBuilder<NetworkState>(
      stream: _network,
      builder: (context, snapshot) {
        final network = snapshot.data;
        final offline = rooms.isEmpty && network is NetworkDisconnected;
        return FrScaffold(
          dock: LobbyDock(onJoinByIp: _showJoinDialog),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LobbyHeader(network: network),
              LobbyHeading(count: rooms.length),
              LobbyTuner(
                notes: rooms.map((room) => room.note).nonNulls.toList(),
                signalCount: rooms.length,
                selected: selected?.note,
                paused: offline,
              ),
              Expanded(
                child: rooms.isNotEmpty
                    ? _roomList(rooms)
                    : offline
                    ? const LobbyOfflineNotice()
                    : const LobbyEmptySearch(),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Una tarjeta por frecu cercana; la elegida, encendida.
  Widget _roomList(List<NearbyRoom> rooms) => ListView.separated(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 200),
    itemCount: rooms.length,
    separatorBuilder: (_, _) => const SizedBox(height: 10),
    itemBuilder: (context, index) {
      final room = rooms[index];
      return NearbyRoomTile(
        room: room,
        selected: room.roomId == _selectedRoomId,
        onPressed: () => _select(room),
      );
    },
  );
}

class _JoinRoomDialog extends ConsumerStatefulWidget {
  const _JoinRoomDialog();

  @override
  ConsumerState<_JoinRoomDialog> createState() => _JoinRoomDialogState();
}

class _JoinRoomDialogState extends ConsumerState<_JoinRoomDialog> {
  final _ipController = TextEditingController(text: '192.168.43.1');
  final _codeController = TextEditingController(text: '1234');

  @override
  void dispose() {
    _ipController.dispose();
    _codeController.dispose();
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
          displayName: ref.joinDisplayName,
        );
    if (!mounted) return;
    switch (result) {
      case Success(:final data):
        unawaited(context.router.push(RoomRoute(roomId: data.id)));
      case FailureResult(:final failure):
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(failure.toLocalizedMessage())));
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
