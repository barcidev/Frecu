/// Vuelta de la red durante una espera de reconexión: en lugar de esperar
/// el plazo completo, se despierta en cuanto el teléfono estrena una
/// dirección de red (Wi-Fi, punto de acceso o datos móviles).
library;

import 'dart:async';
import 'dart:io';

import 'package:frecu/core/constants/network_constants.dart';

/// Fuente de las interfaces de red (`NetworkInterface.list` en la app).
typedef NetworkInterfacesSource = Future<List<NetworkInterface>> Function();

/// Vigía que sondea las interfaces mientras dura una espera y la corta si
/// aparece una dirección que no estaba en la consulta anterior.
///
/// Solo cuentan las apariciones: si la red se cae no se adelanta nada,
/// para no gastar intentos de reconexión sin red.
class NetworkReturnWatcher {
  /// Crea el vigía; [interfaces] y [pollInterval] se inyectan en pruebas.
  NetworkReturnWatcher({
    NetworkInterfacesSource? interfaces,
    this.pollInterval = NetworkConstants.networkReturnPollInterval,
  }) : _interfaces = interfaces ?? NetworkInterface.list;

  final NetworkInterfacesSource _interfaces;

  /// Cada cuánto se consultan las interfaces durante la espera.
  final Duration pollInterval;

  /// Direcciones IPv4/IPv6 que no son loopback, o nulo si no se pudieron
  /// consultar.
  Future<Set<String>?> addresses() async {
    try {
      final interfaces = await _interfaces();
      return {
        for (final interface in interfaces)
          for (final address in interface.addresses)
            if (!address.isLoopback) address.address,
      };
    } on Object {
      return null;
    }
  }

  /// Espera [delay] o menos: `true` si terminó antes porque apareció una
  /// dirección nueva respecto a la consulta anterior (la primera se compara
  /// con [baseline]; sin ella, la primera consulta es la referencia).
  ///
  /// `false` si se cumplió el plazo o [cancelled] dio verdadero; en ambos
  /// casos deja de consultar.
  Future<bool> wait(
    Duration delay, {
    Set<String>? baseline,
    bool Function()? cancelled,
  }) {
    final done = Completer<bool>();
    var previous = baseline;
    var polling = false;
    Timer? ticker;
    late final Timer deadline;

    void finish(bool early) {
      if (done.isCompleted) return;
      deadline.cancel();
      ticker?.cancel();
      done.complete(early);
    }

    Future<void> poll() async {
      if (polling || done.isCompleted) return;
      if (cancelled?.call() ?? false) return finish(false);
      polling = true;
      try {
        final now = await addresses();
        if (now == null || done.isCompleted) return;
        final before = previous;
        previous = now;
        if (before != null && now.difference(before).isNotEmpty) {
          finish(true);
        }
      } finally {
        polling = false;
      }
    }

    deadline = Timer(delay, () => finish(false));
    ticker = Timer.periodic(pollInterval, (_) => unawaited(poll()));
    if (baseline == null) unawaited(poll());
    return done.future;
  }
}
