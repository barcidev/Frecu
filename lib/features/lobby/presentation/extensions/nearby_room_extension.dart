import 'package:frecu/features/lobby/domain/entities/nearby_room.dart';
import 'package:frecu/i18n/strings.g.dart';

/// Nombre que se muestra de una frecu cercana.
extension NearbyRoomTitle on NearbyRoom {
  /// Su nombre o, si el anuncio no trae ninguno, «Frecu sin nombre» en el
  /// idioma de la app.
  String get title => name.trim().isEmpty ? t.lobby.unnamedRoom : name;
}
