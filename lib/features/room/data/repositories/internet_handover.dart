import 'package:frecu/core/constants/cloud_config.dart';
import 'package:frecu/features/room/data/datasources/cloud_relay_datasource.dart';
import 'package:frecu/features/room/data/datasources/signaling_server_datasource.dart';
import 'package:frecu/features/room/domain/entities/room_succession.dart';

/// Traspaso de una frecu por internet. El punto de encuentro no cambia (el
/// mismo id, el mismo enlace y el mismo QR): tomar la frecu es abrir el relé
/// de anfitrión con el mismo secreto y un turno mayor, y seguir a quien la
/// toma es volver al mismo socket de invitado con el id propio.
abstract final class InternetHandover {
  /// WebSocket del anfitrión de la frecu [internetId] con su [secret] y su
  /// turno [term]: el punto de encuentro acepta al de turno igual o mayor,
  /// rechaza al de turno menor y, si se cae, espera a su sucesor.
  static Uri hostSocket(
    CloudConfig config,
    String internetId,
    String secret,
    int term,
  ) {
    final uri = config.hostSocket(internetId, secret);
    return uri.replace(
      queryParameters: {...uri.queryParameters, 'term': '$term'},
    );
  }

  /// Abre el relé de quien toma la frecu por internet de [state] con el
  /// turno [term], y entrega cada invitado a [onGuest]. Lanza el error si no
  /// hay punto de encuentro, si falta el secreto o si la nube lo rechaza.
  static Future<void> openRelay(
    CloudRelayDataSource relay,
    CloudConfig config, {
    required RoomSuccession state,
    required int term,
    required void Function(SignalingConnection connection) onGuest,
  }) async {
    final internetId = state.internetId;
    final secret = state.hostSecret;
    if (!config.isEnabled || internetId == null || secret == null) {
      throw StateError('Cannot take an internet room without its secret');
    }
    await relay.start(
      hostSocket(config, internetId, secret, term),
      onGuest: onGuest,
    );
  }
}
