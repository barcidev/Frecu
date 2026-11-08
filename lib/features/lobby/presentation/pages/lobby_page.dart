import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frecu/app/router/app_router.gr.dart';
import 'package:frecu/core/design/widgets/fr_scaffold.dart';
import 'package:frecu/features/lobby/domain/entities/nearby_room.dart';
import 'package:frecu/features/lobby/presentation/providers/discovery_provider.dart';
import 'package:frecu/features/lobby/presentation/widgets/ip_join_sheet.dart';
import 'package:frecu/features/lobby/presentation/widgets/lobby_sections.dart';
import 'package:frecu/features/lobby/presentation/widgets/lobby_tuner.dart';
import 'package:frecu/features/lobby/presentation/widgets/nearby_room_tile.dart';
import 'package:frecu/features/lobby/presentation/widgets/pin_join_sheet.dart';
import 'package:frecu/features/network/domain/entities/network_state.dart';
import 'package:frecu/features/network/presentation/providers/network_provider.dart';
import 'package:frecu/features/room/domain/entities/room.dart';

/// Inicio en Portadora (pantalla `lobby` del prototipo): la marca, el
/// estado de la red local y Ajustes; el sintonizador de dos octavas con un
/// pico por frecu cercana; la lista de frecus o la búsqueda vacía, o el
/// aviso sin red; y abajo Crear frecu, Escanear y Conectar por IP.
///
/// Tocar una frecu la elige (tarjeta encendida y aguja a su nota) y abre la
/// hoja de código ([PinJoinSheet]); Conectar por IP abre [IpJoinSheet]. La
/// elección sigue hasta tocar otra o hasta que esa frecu desaparece de la
/// lista.
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

  /// Abre la hoja de conexión por IP y, si se une, la frecu activa.
  Future<void> _joinByIp() async {
    final room = await IpJoinSheet.show(context);
    _open(room);
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
          dock: LobbyDock(onJoinByIp: _joinByIp),
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
