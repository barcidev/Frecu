import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frecu/app/router/app_router.gr.dart';
import 'package:frecu/core/design/widgets/fr_scaffold.dart';
import 'package:frecu/core/usecase/usecase.dart';
import 'package:frecu/features/lobby/domain/entities/nearby_room.dart';
import 'package:frecu/features/lobby/presentation/providers/discovery_provider.dart';
import 'package:frecu/features/lobby/presentation/widgets/ip_join_sheet.dart';
import 'package:frecu/features/lobby/presentation/widgets/lobby_sections.dart';
import 'package:frecu/features/lobby/presentation/widgets/lobby_tuner.dart';
import 'package:frecu/features/lobby/presentation/widgets/nearby_room_tile.dart';
import 'package:frecu/features/lobby/presentation/widgets/pin_join_sheet.dart';
import 'package:frecu/features/lobby/presentation/widgets/rise_in.dart';
import 'package:frecu/features/network/domain/entities/network_state.dart';
import 'package:frecu/features/network/presentation/providers/network_provider.dart';
import 'package:frecu/features/room/domain/entities/room.dart';
import 'package:frecu/features/room/presentation/providers/room_provider.dart';

/// Inicio en Portadora (pantalla `lobby` del prototipo): la marca, el
/// estado de la red local y Ajustes; el sintonizador de dos octavas con un
/// pico por frecu cercana; la lista de frecus o la búsqueda vacía, o el
/// aviso sin red; y abajo Crear frecu, Escanear y Conectar por IP.
///
/// Tocar una frecu la elige (tarjeta encendida y aguja a su nota) y, cuando
/// la aguja llega, abre la hoja de código ([PinJoinSheet]); Conectar por IP
/// abre [IpJoinSheet]. La elección sigue hasta cerrar la hoja sin unirse,
/// hasta volver de la frecu o hasta que esa frecu desaparece de la lista.
///
/// El inicio sigue montado debajo de la frecu activa: mientras dura, la
/// búsqueda queda en pausa ([nearbyRoomsProvider]) y, cuando termina, retira
/// su anuncio mDNS (`StopPublishingRoom`) y vuelve a buscar. Si la búsqueda
/// no puede empezar, lo dice y la reintenta cada [searchRetry].
@RoutePage()
class LobbyPage extends ConsumerStatefulWidget {
  /// Constructor constante.
  const LobbyPage({super.key});

  /// Espera entre elegir una frecu y abrir su hoja: la aguja llega a su
  /// nota. Con movimiento reducido el sistema la acorta.
  static const Duration pickDelay = Duration(milliseconds: 380);

  /// Espera antes de reintentar una búsqueda que no pudo empezar.
  static const Duration searchRetry = Duration(seconds: 5);

  @override
  ConsumerState<LobbyPage> createState() => _LobbyPageState();
}

class _LobbyPageState extends ConsumerState<LobbyPage>
    with SingleTickerProviderStateMixin {
  /// Estado de la red local; hasta el primer valor no se sabe.
  late final Stream<NetworkState> _network;

  /// Espera de [LobbyPage.pickDelay] entre elegir y abrir la hoja.
  late final AnimationController _pick = AnimationController(
    vsync: this,
    duration: LobbyPage.pickDelay,
  );

  /// Reintento programado de la búsqueda.
  Timer? _retry;

  /// Frecu elegida.
  String? _selectedRoomId;

  @override
  void initState() {
    super.initState();
    _network = ref.read(networkRepositoryProvider).watchNetworkState();
    ref
      ..listenManual<Room?>(roomNotifierProvider, _onRoomChanged)
      ..listenManual<AsyncValue<List<NearbyRoom>>>(
        nearbyRoomsProvider,
        _onRooms,
        fireImmediately: true,
      );
  }

  @override
  void dispose() {
    _retry?.cancel();
    _pick.dispose();
    super.dispose();
  }

  /// Abre la hoja de conexión por IP y, si se une, la frecu activa.
  Future<void> _joinByIp() async {
    final room = await IpJoinSheet.show(context);
    _open(room);
  }

  /// Elige [room] y, cuando la aguja llega a su nota, abre su hoja de
  /// código; si se une, la frecu activa, y si la cierra, la suelta.
  Future<void> _select(NearbyRoom room) async {
    setState(() => _selectedRoomId = room.roomId);
    try {
      await _pick.forward(from: 0).orCancel;
    } on TickerCanceled {
      // Otra elección empezó su espera, o el inicio se cerró.
      return;
    }
    if (!mounted || _selectedRoomId != room.roomId) return;
    final joined = await PinJoinSheet.show(context, room);
    if (!mounted) return;
    if (joined == null) {
      _deselect();
    } else {
      _open(joined);
    }
  }

  void _deselect() {
    if (_selectedRoomId != null) setState(() => _selectedRoomId = null);
  }

  void _open(Room? room) {
    if (room == null || !mounted) return;
    unawaited(context.router.push(RoomRoute(roomId: room.id)));
  }

  Future<void> _openWifiSettings() async {
    await ref.read(systemSettingsRepositoryProvider).openWifiSettings();
  }

  /// Cuando la frecu activa termina, retira su anuncio (si este teléfono la
  /// anunciaba) y suelta la elección.
  void _onRoomChanged(Room? previous, Room? next) {
    if (previous == null || next != null) return;
    unawaited(ref.read(stopPublishingRoomProvider)(const NoParams()));
    _deselect();
  }

  /// Suelta la frecu elegida si desaparece y reintenta la búsqueda si no
  /// pudo empezar.
  void _onRooms(
    AsyncValue<List<NearbyRoom>>? previous,
    AsyncValue<List<NearbyRoom>> next,
  ) {
    final rooms = _roomsOf(next);
    if (_selectedRoomId != null &&
        !rooms.any((room) => room.roomId == _selectedRoomId)) {
      _deselect();
    }
    if (next.hasError && !next.isLoading) _scheduleRetry();
  }

  /// Frecus de la búsqueda; si no pudo empezar, ninguna: sin búsqueda en
  /// marcha la lista anterior ya no es fiable.
  static List<NearbyRoom> _roomsOf(AsyncValue<List<NearbyRoom>> search) =>
      search.hasError ? const [] : search.value ?? const [];

  void _scheduleRetry() {
    _retry?.cancel();
    _retry = Timer(LobbyPage.searchRetry, () {
      _retry = null;
      if (mounted) ref.invalidate(nearbyRoomsProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final search = ref.watch(nearbyRoomsProvider);
    final rooms = _roomsOf(search);
    final failed = search.hasError;
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
                paused: offline || failed,
              ),
              Expanded(
                child: rooms.isNotEmpty
                    ? _roomList(rooms)
                    : offline
                    ? LobbyOfflineNotice(onOpenSettings: _openWifiSettings)
                    : LobbyEmptySearch(failed: failed),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Una tarjeta por frecu cercana, que entra con `rise`; la elegida,
  /// encendida.
  Widget _roomList(List<NearbyRoom> rooms) => ListView.separated(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 200),
    itemCount: rooms.length,
    separatorBuilder: (_, _) => const SizedBox(height: 10),
    findItemIndexCallback: (key) {
      final index = rooms.indexWhere((room) => ValueKey(room.roomId) == key);
      return index < 0 ? null : index;
    },
    itemBuilder: (context, index) {
      final room = rooms[index];
      return RiseIn(
        key: ValueKey(room.roomId),
        delay: RiseIn.staggerOf(index),
        child: NearbyRoomTile(
          room: room,
          selected: room.roomId == _selectedRoomId,
          onPressed: () => _select(room),
        ),
      );
    },
  );
}
