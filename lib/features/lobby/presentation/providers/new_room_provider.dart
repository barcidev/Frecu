import 'dart:math' as math;

import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'new_room_provider.g.dart';

/// Reloj de la nueva frecu: la hora con la que se calcula su nota.
///
/// Se inyecta para que las pruebas fijen la hora en lugar de leer la del
/// teléfono.
@riverpod
DateTime Function() newRoomClock(Ref ref) => DateTime.now;

/// Generador del código de acceso de una frecu nueva: cuatro cifras de 1000
/// a 9999 al azar.
@riverpod
String Function() accessCodeGenerator(Ref ref) {
  final random = math.Random.secure();
  return () => '${1000 + random.nextInt(9000)}';
}
