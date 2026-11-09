import 'package:freezed_annotation/freezed_annotation.dart';

part 'wifi_credentials.freezed.dart';
part 'wifi_credentials.g.dart';

/// Lo que hace falta para entrar a una red Wi-Fi: su nombre y su clave.
///
/// Es la red de la frecu: la que crea el anfitrión Android con Frecu y viaja
/// en el QR de la invitación para que el invitado entre sin pasar por
/// Ajustes.
@freezed
sealed class WifiCredentials with _$WifiCredentials {
  /// Crea los datos de la red [ssid]; sin [passphrase], la red es abierta.
  const factory WifiCredentials({required String ssid, String? passphrase}) =
      _WifiCredentials;

  /// Deserializa desde JSON.
  factory WifiCredentials.fromJson(Map<String, dynamic> json) =>
      _$WifiCredentialsFromJson(json);
}
