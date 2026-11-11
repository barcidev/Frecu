import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frecu/features/bluetooth_invite/domain/repositories/bluetooth_invite_repository.dart';
import 'package:frecu/features/bluetooth_invite/presentation/providers/bluetooth_invite_provider.dart';
import 'package:frecu/features/room/domain/entities/room_invite.dart';
import 'package:frecu/features/room/presentation/providers/room_provider.dart';

/// Invitación por Bluetooth en la frecu activa: el anfitrión que conoce la
/// red de la frecu (la que creó Frecu o su zona Wi-Fi guardada) la anuncia,
/// para que quien esté cerca, aunque no esté en esa red, entre con el
/// código. Sin red que entregar no se anuncia.
class RoomBluetoothInvite {
  BluetoothInviteRepository? _repository;
  ProviderSubscription<RoomInvite?>? _watch;
  RoomInvite? _current;

  /// Empieza a seguir la frecu con [ref] (en el `initState`).
  void start(WidgetRef ref) {
    _repository = ref.read(bluetoothInviteRepositoryProvider);
    _watch = ref.listenManual<RoomInvite?>(
      _served,
      (_, next) => _apply(next),
      fireImmediately: true,
    );
  }

  /// La invitación que se entrega por Bluetooth, o nula si no se anuncia.
  static final _served = Provider.autoDispose<RoomInvite?>((ref) {
    final room = ref.watch(roomNotifierProvider);
    final wifi = room?.wifi;
    if (room == null || !room.hosting || wifi == null) return null;
    return RoomInvite(
      host: room.hostAddress,
      port: room.port,
      roomId: room.id,
      accessCode: room.accessCode,
      note: room.note,
      name: room.name,
      wifi: wifi,
      internetId: room.internetId,
    );
  });

  void _apply(RoomInvite? invite) {
    final repository = _repository;
    if (repository == null || invite == _current) return;
    final was = _current;
    _current = invite;
    if (invite != null) {
      unawaited(repository.advertise(invite));
    } else if (was != null) {
      unawaited(repository.stopAdvertising());
    }
  }

  /// Deja de anunciar y de escuchar (en el `dispose`).
  void stop() {
    _watch?.close();
    _watch = null;
    if (_current != null) unawaited(_repository?.stopAdvertising());
    _current = null;
    _repository = null;
  }
}
