import 'package:flutter/foundation.dart';
import 'package:frecu/features/room/domain/entities/participant.dart';
import 'package:frecu/features/room/domain/entities/room_reach.dart';
import 'package:frecu/features/room/domain/entities/room_status.dart';
import 'package:frecu/features/room/domain/entities/room_succession.dart';
import 'package:frecu/i18n/strings.g.dart';

/// Espera de un invitado cuando el anfitrión de una frecu con traspaso deja
/// de responder (`guestSearching` del prototipo del anfitrión): la isla dice
/// quién no responde, solo el anfitrión se ve reconectando, el PTT sigue
/// habilitado y la pista dice quién toma la frecu si no vuelve.
@immutable
class HostSilence {
  /// Crea la espera de [hostName] ([hostId]); si no vuelve, la toma
  /// [successor], que es este teléfono con [youNext].
  const HostSilence({
    required this.hostId,
    required this.hostName,
    required this.successor,
    this.youNext = false,
  });

  /// La espera de la frecu, o nula si no hay: la frecu reconecta, su
  /// [succession] admite traspaso, este teléfono ([localId]) no la lleva y
  /// hay a quién pasarla. El sucesor es el del plan de caída: la primera
  /// persona de la sucesión, sin el anfitrión, que sigue en [participants]
  /// y, en una frecu local, tiene IP o es este teléfono.
  static HostSilence? find({
    required RoomStatus? status,
    required RoomSuccession? succession,
    required List<Participant> participants,
    required String? localId,
  }) {
    final reconnecting =
        status?.maybeWhen(reconnecting: (_, _) => true, orElse: () => false) ??
        false;
    if (!reconnecting || succession == null || !succession.handover) {
      return null;
    }
    final (hostId, hostName) = _host(succession, participants);
    if (localId == null || hostId == null || hostId == localId) return null;
    final next = _successor(succession, hostId, participants, localId);
    if (hostName == null || next == null) return null;
    return HostSilence(
      hostId: hostId,
      hostName: hostName,
      successor: next.displayName,
      youNext: next.id == localId,
    );
  }

  /// Id y nombre del anfitrión: el de [participants] o, sin él, el primero
  /// de la sucesión.
  static (String?, String?) _host(
    RoomSuccession succession,
    List<Participant> participants,
  ) {
    final host = participants.where((p) => p.isHost).firstOrNull;
    if (host != null) return (host.id, host.displayName);
    final first = succession.members.firstOrNull;
    return (first?.id, first?.displayName);
  }

  /// Quien toma la frecu de [hostId] si no vuelve, como en el plan de caída.
  static RoomMember? _successor(
    RoomSuccession succession,
    String hostId,
    List<Participant> participants,
    String localId,
  ) {
    final present = {for (final p in participants) p.id};
    final local = succession.reach == RoomReach.local;
    bool reachable(RoomMember m) =>
        !local || m.id == localId || m.address != null;
    return succession.members
        .where(
          (m) =>
              m.id != hostId &&
              (present.isEmpty || present.contains(m.id)) &&
              reachable(m),
        )
        .firstOrNull;
  }

  /// [participants] como se ven en la espera: el anfitrión, reconectando.
  static List<Participant> showParticipants(
    HostSilence? silence,
    List<Participant> participants,
  ) => silence == null
      ? participants
      : [
          for (final p in participants)
            if (p.id == silence.hostId)
              p.copyWith(connectionState: PeerConnectionState.reconnecting)
            else
              p,
        ];

  /// [status] como se ve en la espera: la frecu sigue conectada.
  static RoomStatus? showStatus(HostSilence? silence, RoomStatus? status) =>
      silence == null ? status : const RoomStatus.connected();

  /// Id del anfitrión que no responde.
  final String hostId;

  /// Nombre del anfitrión que no responde.
  final String hostName;

  /// Nombre de quien toma la frecu si el anfitrión no vuelve.
  final String successor;

  /// Quien la toma es este teléfono.
  final bool youNext;

  /// Pista bajo el núcleo PTT.
  String get hint {
    final hint = t.room.talk.hint;
    return youNext ? hint.hostSilentYou : hint.hostSilent(name: successor);
  }

  /// Texto de la isla tras [seconds] sin respuesta.
  String islandLabel(int? seconds) {
    final island = t.room.talk.island;
    return seconds != null && seconds > 0
        ? island.hostSilentFor(name: hostName, seconds: '$seconds')
        : island.hostSilent(name: hostName);
  }

  @override
  bool operator ==(Object other) =>
      other is HostSilence &&
      other.hostId == hostId &&
      other.hostName == hostName &&
      other.successor == successor &&
      other.youNext == youNext;

  @override
  int get hashCode => Object.hash(hostId, hostName, successor, youNext);
}
