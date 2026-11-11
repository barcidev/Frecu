import 'dart:async';

import 'package:frecu/features/room/data/repositories/current_then.dart';
import 'package:frecu/features/room/domain/entities/participant.dart';
import 'package:frecu/features/room/domain/entities/room_note.dart';
import 'package:frecu/features/room/domain/entities/room_reach.dart';
import 'package:frecu/features/room/domain/entities/room_succession.dart';

/// Sucesión de la frecu que lleva este teléfono como anfitrión: el turno,
/// el tipo de frecu y quiénes están, en orden de llegada, con su IP y su
/// hora de llegada. El servidor de señalización la reparte en `room_state`.
class SuccessionLedger {
  int _term = 1;
  RoomReach _reach = RoomReach.local;
  bool _hostOwnsNetwork = false;
  String? _hostAddress;
  String? _internetId;
  String? _hostSecret;
  String? _hostId;
  final Map<String, RoomMember> _members = {};

  /// Turno vigente del anfitrión.
  int get term => _term;

  /// La frecu sobrevive a la salida del anfitrión, como `Room.handover`.
  bool get handover => _reach == RoomReach.internet || !_hostOwnsNetwork;

  /// Fija cómo es la frecu antes de abrirla: su tipo, si su red la crea el
  /// anfitrión, la IPv4 de su invitación y, por internet, su id y el
  /// secreto de anfitrión.
  void configure({
    required RoomReach reach,
    required bool hostOwnsNetwork,
    String? hostAddress,
    String? internetId,
    String? hostSecret,
    int term = 1,
  }) {
    _term = term;
    _reach = reach;
    _hostOwnsNetwork = hostOwnsNetwork;
    _hostAddress = hostAddress;
    _internetId = internetId;
    _hostSecret = hostSecret;
  }

  /// Suma a [participant] al final de la sucesión. El anfitrión lleva la
  /// IPv4 de la invitación; un invitado, la de su socket local ([address]).
  /// Quien vuelve a su lugar heredado lo conserva, con su hora de llegada.
  void add(Participant participant, {String? address}) {
    if (participant.isHost) _hostId = participant.id;
    _members[participant.id] = RoomMember(
      id: participant.id,
      displayName: participant.displayName,
      joinedAt: _members[participant.id]?.joinedAt ?? DateTime.now(),
      address: participant.isHost ? _hostAddress : address,
    );
  }

  /// Guarda el lugar heredado de [member] en una frecu que se toma, con su
  /// id y su hora de llegada, hasta que vuelva o se vaya.
  void seed(RoomMember member) => _members[member.id] = member;

  /// Saca a [peerId] de la sucesión.
  void remove(String peerId) => _members.remove(peerId);

  /// Vacía la sucesión al abrir una frecu nueva.
  void clear() {
    _members.clear();
    _hostId = null;
  }

  /// La sucesión con el estado de la frecu, para `room_state`.
  RoomSuccession snapshot({
    required String name,
    required String accessCode,
    RoomNote? note,
  }) => RoomSuccession(
    term: _term,
    handover: handover,
    name: name,
    accessCode: accessCode,
    note: note,
    reach: _reach,
    internetId: _internetId,
    hostSecret: _hostSecret,
    // El anfitrión primero; los demás, por orden de llegada.
    members: List.unmodifiable([
      ?_members[_hostId],
      for (final member in _members.values)
        if (member.id != _hostId) member,
    ]),
  );
}

/// Frecu que toma este teléfono: su sucesión ([state]), quién la toma
/// ([host]), quién la llevaba ([previous]) y por qué cambió ([reason]:
/// `left` si se la pasó al salir, `lost` si se cayó).
class InheritedRoom {
  /// Crea la frecu heredada.
  const InheritedRoom(
    this.state, {
    required this.host,
    required this.previous,
    this.reason = 'left',
  });

  /// Sucesión y estado heredados.
  final RoomSuccession state;

  /// Id de quien la toma.
  final String host;

  /// Id de quien la llevaba.
  final String previous;

  /// Por qué cambió el anfitrión.
  final String reason;

  /// A quiénes se guarda lugar: todos menos quien la llevaba.
  Iterable<RoomMember> get seats =>
      state.members.where((member) => member.id != previous);

  /// El mayor número de los ids heredados (`peer_N`): los nuevos siguen.
  int get lastPeerNumber => state.members
      .map((member) => int.tryParse(member.id.replaceFirst('peer_', '')) ?? 0)
      .fold(0, (a, b) => a > b ? a : b);
}

/// La última sucesión que mandó el anfitrión a este teléfono.
class KnownSuccession {
  final StreamController<RoomSuccession?> _controller =
      StreamController<RoomSuccession?>.broadcast();
  RoomSuccession? _current;

  /// La sucesión vigente, o nula sin frecu o antes del primer `room_state`.
  RoomSuccession? get current => _current;

  /// La sucesión vigente y sus cambios.
  Stream<RoomSuccession?> watch() =>
      currentThen(() => _current, _controller.stream);

  /// Guarda la sucesión que llegó, o la olvida con `null`.
  void update(RoomSuccession? succession) {
    if (succession == _current) return;
    _current = succession;
    if (!_controller.isClosed) _controller.add(succession);
  }

  /// Libera el stream.
  Future<void> dispose() => _controller.close();
}
