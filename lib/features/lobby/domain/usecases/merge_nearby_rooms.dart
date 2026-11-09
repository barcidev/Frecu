import 'package:frecu/features/lobby/domain/entities/nearby_room.dart';

/// Une las frecus encontradas en la red ([local], mDNS) con las encontradas
/// por Bluetooth ([bluetooth]). Una frecu que está en las dos va una sola
/// vez, la de la red: ya se está en ella y se entra directo.
List<NearbyRoom> mergeNearbyRooms(
  List<NearbyRoom> local,
  List<NearbyRoom> bluetooth,
) {
  if (bluetooth.isEmpty) return local;
  final ids = {for (final room in local) room.roomId};
  return [
    ...local,
    for (final room in bluetooth)
      if (ids.add(room.roomId)) room,
  ];
}
