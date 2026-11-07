import 'package:freezed_annotation/freezed_annotation.dart';

part 'network_state.freezed.dart';

/// Representa el estado de la conexión de red local en el dispositivo.
@freezed
sealed class NetworkState with _$NetworkState {
  const NetworkState._();

  /// Sin interfaz activa o sin dirección IP local válida asignada.
  const factory NetworkState.disconnected() = NetworkDisconnected;

  /// Conectado a una interfaz de red local con dirección IPv4 no loopback.
  const factory NetworkState.connected({
    required String ipAddress,
    required String interfaceName,
    required bool isHotspot,
  }) = NetworkConnected;

  /// Indica si el dispositivo está actualmente conectado a una red local activa.
  bool get isConnected => this is NetworkConnected;

  /// Indica si el estado de red corresponde a un hotspot activo.
  bool get isHotspot => when(
        disconnected: () => false,
        connected: (_, __, isHotspot) => isHotspot,
      );
}
