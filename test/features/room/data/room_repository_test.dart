// AC1: CUANDO el anfitrión crea una frecu ENTONCES la sala se inicializa en el estado conectado, el servidor de señalización se activa y se muestra la IP local del anfitrión.
// AC2: CUANDO un participante ingresa la IP del anfitrión y el código de acceso ENTONCES se une a la sala mediante WebSocket y ambos teléfonos ven la lista actualizada de participantes.
// AC3: CUANDO un participante o el anfitrión abandona la sala ENTONCES la conexión se cierra limpiamente y se actualiza el estado de la sala en los participantes restantes.
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RoomRepository integration', () {
    // AC1
    test(
      'AC1: createRoom starts signaling server and connects loopback client',
      () async {
        fail('RoomRepository.createRoom not implemented yet');
      },
    );

    // AC2
    test(
      'AC2: joinRoom connects remote peer and synchronizes participant list',
      () async {
        fail('RoomRepository.joinRoom not implemented yet');
      },
    );

    // AC3
    test(
      'AC3: leaveRoom closes connection and updates participant list',
      () async {
        fail('RoomRepository.leaveRoom not implemented yet');
      },
    );
  });
}
