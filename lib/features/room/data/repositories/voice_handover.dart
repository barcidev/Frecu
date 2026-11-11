import 'package:frecu/features/room/domain/entities/participant.dart';
import 'package:frecu/features/room/domain/entities/room_succession.dart';

/// Lo que la voz sabe del traspaso de la frecu por la señalización que ya
/// recibe: si la frecu sobrevive a la salida del anfitrión ([keepsVoice]) y
/// quién la lleva ([hostId]). En una frecu con traspaso la malla entre
/// invitados no depende del anfitrión: sin él, la voz sigue.
class VoiceHandover {
  bool _handover = false;
  String? _hostId;

  /// La frecu admite traspaso: perder el socket con el anfitrión no corta la
  /// voz entre los demás.
  bool get keepsVoice => _handover;

  /// Id de quien lleva la frecu, si se sabe.
  String? get hostId => _hostId;

  /// Toma de [participants] (`welcome`) a quien lleva la frecu y devuelve
  /// el anfitrión anterior si cambió, como [onRoomState].
  String? onWelcome(List<Participant> participants, {String? localId}) =>
      _setHost(participants.where((p) => p.isHost).firstOrNull?.id, localId);

  /// Guarda la sucesión que llegó (`room_state`, el anfitrión primero) y
  /// devuelve el anfitrión anterior si cambió y no es [localId]: su enlace
  /// de voz ya no sirve. Nulo si no cambió.
  String? onRoomState(RoomSuccession state, {String? localId}) {
    _handover = state.handover;
    return _setHost(state.members.firstOrNull?.id, localId);
  }

  String? _setHost(String? host, String? localId) {
    if (host == null) return null;
    final previous = _hostId;
    _hostId = host;
    if (previous == null || previous == host || previous == localId) {
      return null;
    }
    return previous;
  }

  /// Olvida la frecu al salir de ella.
  void reset() {
    _handover = false;
    _hostId = null;
  }
}
