// AC1: CUANDO el anfitrión crea una frecu ENTONCES la sala se inicializa en el estado conectado, el servidor de señalización se activa y se muestra la IP local del anfitrión.
// AC2: CUANDO un participante ingresa la IP del anfitrión y el código de acceso ENTONCES se une a la sala mediante WebSocket y ambos teléfonos ven la lista actualizada de participantes.
// AC3: CUANDO un participante o el anfitrión abandona la sala ENTONCES la conexión se cierra limpiamente y se actualiza el estado de la sala en los participantes restantes.
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Room use cases', () {
    // AC1
    test(
      'AC1: CreateRoom use case creates a room and returns success Result',
      () async {
        fail('CreateRoom not implemented yet');
      },
    );

    // AC2
    test(
      'AC2: JoinRoom use case joins room with host address and access code',
      () async {
        fail('JoinRoom not implemented yet');
      },
    );

    // AC3
    test('AC3: LeaveRoom use case leaves the current room cleanly', () async {
      fail('LeaveRoom not implemented yet');
    });
  });
}
