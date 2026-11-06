// AC1: CUANDO el anfitrión crea una frecu ENTONCES la sala se inicializa en el estado conectado, el servidor de señalización se activa y se muestra la IP local del anfitrión.
// AC2: CUANDO un participante ingresa la IP del anfitrión y el código de acceso ENTONCES se une a la sala mediante WebSocket y ambos teléfonos ven la lista actualizada de participantes.
// AC3: CUANDO un participante o el anfitrión abandona la sala ENTONCES la conexión se cierra limpiamente y se actualiza el estado de la sala en los participantes restantes.
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Room presentation and UI flow', () {
    // AC1
    testWidgets(
      'AC1: CreateRoomPage allows host to create room and navigate to RoomPage with local IP',
      (tester) async {
        fail('CreateRoom flow not implemented yet');
      },
    );

    // AC2
    testWidgets(
      'AC2: LobbyPage allows peer to join by manual IP and navigate to RoomPage',
      (tester) async {
        fail('Join by IP flow not implemented yet');
      },
    );

    // AC3
    testWidgets('AC3: RoomPage allows leaving room and returns to LobbyPage', (
      tester,
    ) async {
      fail('Leave room flow not implemented yet');
    });
  });
}
