import 'package:frecu/features/network/data/datasources/local_hotspot_datasource.dart';
import 'package:frecu/features/network/data/datasources/network_interface_datasource.dart';
import 'package:frecu/features/network/data/datasources/system_settings_datasource.dart';
import 'package:frecu/features/network/data/datasources/wifi_join_datasource.dart';
import 'package:frecu/features/network/data/repositories/local_hotspot_repository_impl.dart';
import 'package:frecu/features/network/data/repositories/network_repository_impl.dart';
import 'package:frecu/features/network/data/repositories/system_settings_repository_impl.dart';
import 'package:frecu/features/network/data/repositories/wifi_join_repository_impl.dart';
import 'package:frecu/features/network/domain/entities/network_state.dart';
import 'package:frecu/features/network/domain/repositories/local_hotspot_repository.dart';
import 'package:frecu/features/network/domain/repositories/network_repository.dart';
import 'package:frecu/features/network/domain/repositories/system_settings_repository.dart';
import 'package:frecu/features/network/domain/repositories/wifi_join_repository.dart';
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

/// Proveedor de los Ajustes del sistema (Wi-Fi, punto de acceso y los de la
/// app).
@Riverpod(keepAlive: true)
SystemSettingsRepository systemSettingsRepository(Ref ref) =>
    SystemSettingsRepositoryImpl(dataSource: SystemSettingsDataSource());

/// La red de la frecu que crea el anfitrión Android (`LocalOnlyHotspot`).
@Riverpod(keepAlive: true)
LocalHotspotRepository localHotspotRepository(Ref ref) =>
    LocalHotspotRepositoryImpl(dataSource: LocalHotspotDataSource());

/// Cómo llega el invitado a la red del anfitrión.
@Riverpod(keepAlive: true)
WifiJoinRepository wifiJoinRepository(Ref ref) =>
    WifiJoinRepositoryImpl(dataSource: WifiJoinDataSource());
