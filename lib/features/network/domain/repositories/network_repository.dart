import 'package:frecu/core/result/result.dart';
import 'package:frecu/features/network/domain/entities/network_state.dart';

/// Contrato abstracto para la consulta y observación del estado de red local.
abstract interface class NetworkRepository {
  /// Obtiene el estado actual de la interfaz de red local.
  Future<Result<NetworkState>> getNetworkState();

  /// Emite periódicamente cambios en el estado de red local.
  Stream<NetworkState> watchNetworkState();
}
