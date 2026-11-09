import 'package:frecu/core/result/result.dart';
import 'package:frecu/features/network/domain/entities/wifi_credentials.dart';

/// Cómo llega el invitado a la red del anfitrión.
///
/// En Android, una Wi-Fi sin internet (como la red de la frecu) no es la red
/// por defecto si hay datos móviles: la app se ata a la Wi-Fi que alcanza al
/// anfitrión mientras dura la frecu. En iOS no hace falta.
abstract interface class WifiJoinRepository {
  /// Ata la app a la red en la que está [host], si el teléfono ya está en
  /// ella. Verdadero si la encontró.
  Future<bool> route(String host);

  /// Verdadero si [host]:[port] responde ya, después de atar la app a su
  /// red ([route]).
  Future<bool> reaches(String host, int port);

  /// Conecta el teléfono a la red [credentials] con el aviso del sistema y
  /// espera a que [host]:[port] responda. Falla con `Failure.wifiJoin`.
  Future<Result<void>> join(
    WifiCredentials credentials, {
    required String host,
    required int port,
  });

  /// Suelta la red que conectó la app (el teléfono vuelve a su Wi-Fi) y
  /// desata la app.
  Future<void> release();
}
