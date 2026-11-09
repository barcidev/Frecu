import 'dart:async';
import 'dart:io';

import 'package:frecu/core/error/failure.dart';
import 'package:frecu/core/result/result.dart';
import 'package:frecu/features/network/domain/entities/local_hotspot.dart';
import 'package:frecu/features/network/presentation/providers/network_provider.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'local_hotspot_provider.freezed.dart';
part 'local_hotspot_provider.g.dart';

/// En qué está la red de la frecu de este teléfono.
@freezed
sealed class LocalHotspotState with _$LocalHotspotState {
  /// Apagada: no se creó o se apagó a pedido.
  const factory LocalHotspotState.off() = LocalHotspotOff;

  /// Android la está creando.
  const factory LocalHotspotState.starting() = LocalHotspotStarting;

  /// Al aire.
  const factory LocalHotspotState.ready(LocalHotspot hotspot) =
      LocalHotspotReady;

  /// No se pudo crear, por [reason].
  const factory LocalHotspotState.failed(HotspotFailureReason reason) =
      LocalHotspotFailed;

  /// Android la apagó por su cuenta (se encendió la zona Wi-Fi, modo
  /// avión…): los invitados se desconectaron.
  const factory LocalHotspotState.lost() = LocalHotspotLost;
}

/// Si este teléfono crea la red de la frecu desde la app: solo Android (en
/// Android 7, el intento falla con `unsupported`).
@Riverpod(keepAlive: true)
bool localHotspotAvailable(Ref ref) => Platform.isAndroid;

/// La red de la frecu que crea el anfitrión Android: se crea al tocar
/// «Crear la red» y se apaga al cerrar la frecu o al salir de la creación
/// sin abrirla.
@Riverpod(keepAlive: true)
class LocalHotspotNotifier extends _$LocalHotspotNotifier {
  /// Cada intento de crearla; uno viejo no pisa al nuevo ni a un apagado.
  int _attempt = 0;

  @override
  LocalHotspotState build() {
    final stopped = ref
        .watch(localHotspotRepositoryProvider)
        .watchStopped()
        .listen((_) {
          if (state is LocalHotspotReady || state is LocalHotspotStarting) {
            _attempt++;
            state = const LocalHotspotState.lost();
          }
        });
    ref.onDispose(stopped.cancel);
    return const LocalHotspotState.off();
  }

  /// Interfaz de la red al aire, para que la invitación lleve su IPv4.
  String? get interfaceName => switch (state) {
    LocalHotspotReady(:final hotspot) => hotspot.interfaceName,
    _ => null,
  };

  /// Crea la red (o la vuelve a crear tras perderla) y devuelve en qué
  /// quedó. Si ya está al aire o se está creando, no hace nada.
  Future<LocalHotspotState> start() async {
    if (state is LocalHotspotReady || state is LocalHotspotStarting) {
      return state;
    }
    final attempt = ++_attempt;
    final repository = ref.read(localHotspotRepositoryProvider);
    state = const LocalHotspotState.starting();
    final result = await repository.start();
    if (attempt != _attempt || !ref.mounted) {
      // Se canceló mientras Android la creaba: que no quede al aire.
      if (result.isSuccess) await repository.stop();
      return ref.mounted ? state : const LocalHotspotState.off();
    }
    state = switch (result) {
      Success(:final data) => LocalHotspotState.ready(data),
      FailureResult(:final failure) => LocalHotspotState.failed(
        failure.maybeWhen(
          hotspot: (reason) => reason,
          orElse: () => HotspotFailureReason.failed,
        ),
      ),
    };
    return state;
  }

  /// Apaga la red, también si se estaba creando.
  Future<void> stop() async {
    _attempt++;
    final wasOff = state is LocalHotspotOff;
    state = const LocalHotspotState.off();
    if (!wasOff) await ref.read(localHotspotRepositoryProvider).stop();
  }
}
