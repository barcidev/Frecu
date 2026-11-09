import 'dart:async';

/// Stream que a cada suscriptor le entrega primero el valor actual
/// ([current]) y después cada cambio de [changes], sin hueco entre los dos:
/// quien se suscribe tarde (una pantalla que se abre después del `welcome`)
/// no se queda sin el estado.
Stream<T> currentThen<T>(T Function() current, Stream<T> changes) {
  late final StreamController<T> controller;
  StreamSubscription<T>? subscription;
  controller = StreamController<T>(
    onListen: () {
      controller.add(current());
      subscription = changes.listen(
        controller.add,
        onError: controller.addError,
        onDone: controller.close,
      );
    },
    onPause: () => subscription?.pause(),
    onResume: () => subscription?.resume(),
    // Soltar un stream de difusión es inmediato: no se espera, para que
    // `first` y compañía terminen enseguida.
    onCancel: () => unawaited(subscription?.cancel()),
  );
  return controller.stream;
}
