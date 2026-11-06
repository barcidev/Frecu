// AC1: CUANDO el anfitrión crea una frecu ENTONCES se publica el servicio mDNS `_frecu._tcp` con los atributos `roomId`, `name` y versión de protocolo `v`.
// AC2: CUANDO un participante abre el lobby en la misma red local ENTONCES descubre automáticamente las frecus activas anunciadas por mDNS y las muestra en la lista de frecus cercanas.
// AC3: CUANDO un participante selecciona una frecu descubierta e ingresa el código de acceso ENTONCES se conecta a la sala si el código es válido o recibe notificación de rechazo si es incorrecto.
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Discovery use cases', () {
    // AC1
    test('AC1: PublishRoom use case calls repository publishRoom', () async {
      fail('PublishRoom not implemented yet');
    });

    // AC2
    test(
      'AC2: DiscoverRooms use case calls repository watchNearbyRooms',
      () async {
        fail('DiscoverRooms not implemented yet');
      },
    );
  });
}
