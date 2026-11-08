import 'dart:async';
import 'dart:io';

import 'package:frecu/core/error/failure.dart';
import 'package:frecu/core/network/lan_address.dart';
import 'package:frecu/core/result/result.dart';
import 'package:frecu/features/network/data/datasources/network_interface_datasource.dart';
import 'package:frecu/features/network/domain/entities/network_state.dart';
import 'package:frecu/features/network/domain/repositories/network_repository.dart';

/// Implementación del repositorio de red inspeccionando interfaces de red locales.
class NetworkRepositoryImpl implements NetworkRepository {
  /// Constructor que recibe el datasource de interfaces de red.
  const NetworkRepositoryImpl({required NetworkInterfaceDataSource dataSource})
    : _interfaceDataSource = dataSource;

  final NetworkInterfaceDataSource _interfaceDataSource;

  static const List<String> _hotspotPrefixes = [
    '192.168.43.',
    '172.20.10.',
    '192.168.49.',
  ];

  static const List<String> _hotspotInterfaceKeywords = [
    'ap',
    'softap',
    'swlan',
    'tether',
  ];

  @override
  Future<Result<NetworkState>> getNetworkState() async {
    try {
      final interfaces = await _interfaceDataSource.getInterfaces();
      final activeInfo = _extractActiveInterfaceInfo(interfaces);

      if (activeInfo == null) {
        return const Result.success(NetworkState.disconnected());
      }

      final isHotspot =
          activeInfo.kind == LanKind.hotspot ||
          _detectIsHotspot(activeInfo.address, activeInfo.interfaceName);

      final state = NetworkState.connected(
        ipAddress: activeInfo.address,
        interfaceName: activeInfo.interfaceName,
        isHotspot: isHotspot,
      );

      return Result.success(state);
    } on Object catch (e) {
      return Result.failure(Failure.network(message: e.toString()));
    }
  }

  @override
  Stream<NetworkState> watchNetworkState({
    Duration pollInterval = const Duration(seconds: 3),
  }) async* {
    final initialState = await _resolveCurrentState();
    yield initialState;

    yield* Stream<void>.periodic(pollInterval)
        .asyncMap((_) => _resolveCurrentState())
        .distinct();
  }

  Future<NetworkState> _resolveCurrentState() async {
    final result = await getNetworkState();
    return result.when(
      success: (state) => state,
      failure: (_) => const NetworkState.disconnected(),
    );
  }

  /// La IPv4 de la Wi-Fi o del punto de acceso; con solo datos móviles o
  /// VPN no hay red local ([selectLanAddress]).
  LanAddress? _extractActiveInterfaceInfo(List<NetworkInterface> interfaces) =>
      selectLanAddress(interfaces.map(LanInterface.fromIo));

  bool _detectIsHotspot(String ipAddress, String interfaceName) {
    final ipMatches = _hotspotPrefixes.any(ipAddress.startsWith);
    if (ipMatches) {
      return true;
    }

    final lowerName = interfaceName.toLowerCase();
    return _hotspotInterfaceKeywords.any(lowerName.contains);
  }
}
