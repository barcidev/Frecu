import 'package:freezed_annotation/freezed_annotation.dart';

part 'quick_message.freezed.dart';

/// Mensajes rápidos predefinidos de la frecu, y el SOS.
///
/// Solo hay mensajes predefinidos: Frecu no tiene chat de texto. Viajan por
/// su nombre, así que se pueden sumar tipos sin cambiar el protocolo.
enum QuickMessageKind {
  /// «Me quedé atrás».
  behind,

  /// «Parada en la próxima».
  stop,

  /// «Necesito combustible».
  fuel,

  /// «Todo bien».
  ok,

  /// «Voy en camino», la respuesta a un SOS.
  onMyWay,

  /// Alarma: alguien necesita ayuda.
  sos;

  /// Los que se eligen en la hoja de mensajes, en su orden.
  static const List<QuickMessageKind> presets = [behind, stop, fuel, ok];

  /// El tipo de nombre [name], o nulo si no se conoce (p. ej. de una versión
  /// más nueva de la app).
  static QuickMessageKind? fromName(String name) => values.asNameMap()[name];
}

/// Mensaje rápido recibido de otra persona de la frecu.
@freezed
abstract class QuickMessage with _$QuickMessage {
  /// Crea el mensaje de [senderId] de tipo [kind].
  const factory QuickMessage({
    /// Id en la frecu de quien lo envió.
    required String senderId,

    /// Qué dice.
    required QuickMessageKind kind,
  }) = _QuickMessage;
}
