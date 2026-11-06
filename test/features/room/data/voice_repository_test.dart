// AC1: CUANDO un participante se une a la sala del anfitrión ENTONCES se negocia automáticamente una conexión WebRTC mesh directa (SDP offer/answer e ICE local) entre ambos extremos sin servidores STUN/TURN.
// AC2: CUANDO ambos extremos tienen el micrófono activado en modo abierto ENTONCES la captura local de audio transmite en tiempo real hacia el otro teléfono y se emite señalización de estado de habla (`talk_state`).
// AC3: CUANDO un participante silencia su micrófono ENTONCES se desactiva la pista local de audio (`track.enabled = false`) sin renegociar la sesión WebRTC y se notifica a la sala el cese de habla.
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VoiceRepository integration', () {
    // AC1
    test(
      'AC1: establishes peer connection on welcome message without STUN/TURN',
      () async {
        fail('WebRTC mesh connection not implemented yet');
      },
    );

    // AC2
    test(
      'AC2: startTalking enables audio track and sends talk_state true',
      () async {
        fail('startTalking not implemented yet');
      },
    );

    // AC3
    test(
      'AC3: stopTalking disables audio track without renegotiating',
      () async {
        fail('stopTalking not implemented yet');
      },
    );
  });
}
