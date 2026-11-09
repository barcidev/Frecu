import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:frecu/features/location/data/datasources/position_datasource.dart';
import 'package:frecu/features/location/data/repositories/location_repository_impl.dart';
import 'package:frecu/features/location/domain/entities/behind_tracker.dart';
import 'package:frecu/features/location/domain/entities/geo_point.dart';
import 'package:frecu/features/location/domain/repositories/location_repository.dart';
import 'package:frecu/features/permissions/domain/entities/app_permission.dart';
import 'package:frecu/features/permissions/presentation/providers/permission_provider.dart';
import 'package:frecu/features/room/presentation/providers/room_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'location_provider.g.dart';

/// Repositorio de la ubicación compartida sobre la señalización.
@Riverpod(keepAlive: true)
LocationRepository locationRepository(Ref ref) {
  final repository = LocationRepositoryImpl(
    PositionDataSource(),
    ref.watch(signalingClientProvider),
    ref.watch(foregroundServiceDataSourceProvider),
  );
  ref.onDispose(repository.dispose);
  return repository;
}

/// Ubicación compartida en la frecu activa.
@immutable
class LocationState {
  /// Crea el estado; por defecto nadie comparte nada.
  const LocationState({
    this.sharing = false,
    this.own,
    this.peers = const {},
    this.behind = const {},
  });

  /// Se comparte la propia.
  final bool sharing;

  /// Posición propia, si se comparte y ya hay medida.
  final GeoPoint? own;

  /// Posición de cada persona que comparte la suya, por id.
  final Map<String, GeoPoint> peers;

  /// Quiénes se quedaron atrás (puede incluir el id propio).
  final Set<String> behind;

  /// Distancia en metros y rumbo hacia [peerId], si ambos comparten.
  ({double meters, double bearing})? towards(String peerId) {
    final from = own;
    final to = peers[peerId];
    if (from == null || to == null) return null;
    return (meters: from.distanceTo(to), bearing: from.bearingTo(to));
  }

  /// Copia con los campos dados.
  LocationState copyWith({
    bool? sharing,
    GeoPoint? own,
    bool clearOwn = false,
    Map<String, GeoPoint>? peers,
    Set<String>? behind,
  }) => LocationState(
    sharing: sharing ?? this.sharing,
    own: clearOwn ? null : own ?? this.own,
    peers: peers ?? this.peers,
    behind: behind ?? this.behind,
  );
}

/// Resultado de activar «Compartir mi ubicación».
enum ShareLocationOutcome {
  /// Ya se comparte.
  sharing,

  /// La persona no dio el permiso de ubicación.
  denied,

  /// No dio el permiso y el teléfono ya no lo vuelve a pedir: hay que ir a
  /// los ajustes.
  deniedForever,

  /// Falló al empezar.
  failed,
}

/// Comparte la ubicación propia (si se activa), recibe la de los demás y
/// decide quién se quedó atrás. La pantalla de la frecu deja de compartir
/// al terminar o al salir.
@Riverpod(keepAlive: true)
class LocationSharing extends _$LocationSharing {
  final BehindTracker _tracker = BehindTracker();

  @override
  LocationState build() {
    final repository = ref.watch(locationRepositoryProvider);
    final peersSub = repository.watchPeers().listen((peers) {
      _update(state.copyWith(peers: peers));
    });
    final ownSub = repository.watchOwn().listen((own) {
      _update(state.copyWith(own: own));
    });
    ref.onDispose(() {
      unawaited(peersSub.cancel());
      unawaited(ownSub.cancel());
    });
    return const LocationState();
  }

  void _update(LocationState next) {
    final localId = ref.read(roomRepositoryProvider).localParticipantId;
    final own = next.own;
    final everyone = {
      ...next.peers,
      if (next.sharing && own != null && localId != null) localId: own,
    };
    state = next.copyWith(behind: _tracker.update(everyone, DateTime.now()));
  }

  /// Deja de compartir si se estaba compartiendo (p. ej. al salir de la
  /// frecu); con la app cerrándose no hace nada.
  Future<void> stop() async {
    if (!ref.mounted || !state.sharing) return;
    await setSharing(on: false);
  }

  /// Empieza o deja de compartir la ubicación propia; al empezar pide el
  /// permiso de ubicación si falta.
  Future<ShareLocationOutcome> setSharing({required bool on}) async {
    final repository = ref.read(locationRepositoryProvider);
    if (!on) {
      await repository.stopSharing();
      _tracker.reset();
      if (ref.mounted) {
        state = state.copyWith(sharing: false, clearOwn: true, behind: {});
      }
      return ShareLocationOutcome.sharing;
    }
    final permission = await ref
        .read(permissionRepositoryProvider)
        .request(AppPermission.location);
    final status = permission.dataOrNull;
    if (status != AppPermissionStatus.granted) {
      return status == AppPermissionStatus.permanentlyDenied
          ? ShareLocationOutcome.deniedForever
          : ShareLocationOutcome.denied;
    }
    final started = await repository.startSharing();
    if (started.isFailure) return ShareLocationOutcome.failed;
    if (ref.mounted) state = state.copyWith(sharing: true);
    return ShareLocationOutcome.sharing;
  }
}
