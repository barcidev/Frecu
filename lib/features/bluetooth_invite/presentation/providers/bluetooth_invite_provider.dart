import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frecu/features/bluetooth_invite/data/repositories/bluetooth_invite_repository_impl.dart';
import 'package:frecu/features/bluetooth_invite/domain/repositories/bluetooth_invite_repository.dart';
import 'package:frecu/features/lobby/domain/entities/nearby_room.dart';
import 'package:frecu/features/room/presentation/providers/room_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'bluetooth_invite_provider.g.dart';

/// Invitación por Bluetooth: anunciar la frecu y encontrar las cercanas.
@Riverpod(keepAlive: true)
BluetoothInviteRepository bluetoothInviteRepository(Ref ref) =>
    BluetoothInviteRepositoryImpl();

/// Frecus anunciadas por Bluetooth cerca, también fuera de su red. Como la
/// búsqueda en la red, queda en pausa con una frecu activa.
@riverpod
Stream<List<NearbyRoom>> bluetoothNearbyRooms(Ref ref) {
  final inRoom = ref.watch(roomNotifierProvider.select((room) => room != null));
  if (inRoom) return Stream<List<NearbyRoom>>.multi((_) {});
  return ref.watch(bluetoothInviteRepositoryProvider).watchNearbyRooms();
}
