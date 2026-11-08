import 'package:frecu/features/network/data/datasources/network_interface_datasource.dart';
import 'package:frecu/features/network/data/repositories/network_repository_impl.dart';
import 'package:frecu/features/network/domain/entities/network_state.dart';
import 'package:frecu/features/network/domain/repositories/network_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'network_provider.g.dart';

/// Proveedor del datasource de interfaces de red del sistema.
@Riverpod(keepAlive: true)
NetworkInterfaceDataSource networkInterfaceDataSource(Ref ref) {
  return NetworkInterfaceDataSource();
}

/// Proveedor del repositorio de verificación e inspección de interfaces de red.
@Riverpod(keepAlive: true)
NetworkRepository networkRepository(Ref ref) {
  final dataSource = ref.watch(networkInterfaceDataSourceProvider);
  return NetworkRepositoryImpl(dataSource: dataSource);
}

/// Proveedor del stream continuo del estado de conectividad e interfaces de red.
@Riverpod(keepAlive: true)
Raw<Stream<NetworkState>> networkStateStream(Ref ref) {
  final repository = ref.watch(networkRepositoryProvider);
  return repository.watchNetworkState();
}
