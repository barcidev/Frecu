import 'package:frecu/features/lobby/data/datasources/mdns_datasource.dart';
import 'package:frecu/features/lobby/data/repositories/discovery_repository_impl.dart';
import 'package:frecu/features/lobby/domain/entities/nearby_room.dart';
import 'package:frecu/features/lobby/domain/repositories/discovery_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'discovery_provider.g.dart';

/// Proveedor global singleton del repositorio de descubrimiento.
@Riverpod(keepAlive: true)
DiscoveryRepository discoveryRepository(Ref ref) {
  final mdns = MdnsDataSource();
  final repository = DiscoveryRepositoryImpl(mdnsDataSource: mdns);
  ref.onDispose(repository.dispose);
  return repository;
}

/// Stream reactivo de las frecus cercanas anunciadas en la red local.
@riverpod
Stream<List<NearbyRoom>> nearbyRooms(Ref ref) {
  final repository = ref.watch(discoveryRepositoryProvider);
  return repository.watchNearbyRooms();
}
