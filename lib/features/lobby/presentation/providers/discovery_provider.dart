import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frecu/features/lobby/data/datasources/mdns_datasource.dart';
import 'package:frecu/features/lobby/data/repositories/discovery_repository_impl.dart';
import 'package:frecu/features/lobby/domain/entities/nearby_room.dart';
import 'package:frecu/features/lobby/domain/repositories/discovery_repository.dart';
import 'package:frecu/features/lobby/domain/usecases/discovery_usecases.dart';
import 'package:frecu/features/room/presentation/providers/room_provider.dart';
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

/// Caso de uso que retira el anuncio mDNS de la frecu de este teléfono.
@riverpod
StopPublishingRoom stopPublishingRoom(Ref ref) =>
    StopPublishingRoom(ref.watch(discoveryRepositoryProvider));

/// La búsqueda la reintenta el inicio, que muestra el fallo mientras tanto.
Duration? _retryFromLobby(int retryCount, Object error) => null;

/// Stream reactivo de las frecus cercanas anunciadas en la red local.
///
/// Con una frecu activa la búsqueda queda en pausa (el inicio sigue debajo
/// de la sala) y se conserva la última lista; al terminar la frecu se busca
/// de nuevo desde cero. Si la búsqueda no puede empezar queda en error, sin
/// reintentos automáticos: los programa el inicio.
@Riverpod(retry: _retryFromLobby)
Stream<List<NearbyRoom>> nearbyRooms(Ref ref) {
  final inRoom = ref.watch(roomNotifierProvider.select((room) => room != null));
  if (inRoom) return Stream<List<NearbyRoom>>.multi((_) {});
  final repository = ref.watch(discoveryRepositoryProvider);
  return repository.watchNearbyRooms();
}
