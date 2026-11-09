import 'package:frecu/features/network/domain/entities/wifi_credentials.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'local_hotspot.freezed.dart';

/// La red de la frecu que creó este teléfono (Android, `LocalOnlyHotspot`):
/// sin internet, con nombre y clave nuevos cada vez.
@freezed
sealed class LocalHotspot with _$LocalHotspot {
  /// Crea la red con sus [credentials]; [interfaceName] y [address] son la
  /// interfaz y la IPv4 del teléfono en ella, si Android las dio a conocer.
  const factory LocalHotspot({
    required WifiCredentials credentials,
    String? interfaceName,
    String? address,
  }) = _LocalHotspot;
}
