import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:frecu/core/logging/app_logger.dart';
import 'package:frecu/features/room/data/datasources/peer_connection_datasource.dart';
import 'package:frecu/features/room/domain/entities/link_quality.dart';

/// Cada cuánto se mide la calidad de los enlaces.
const Duration linkQualityInterval = Duration(seconds: 2);

/// Tiempo de ida y vuelta a partir del cual una medida cuenta como mala. En
/// una zona Wi-Fi local lo normal son unos pocos milisegundos.
const double weakLinkRttMs = 400;

/// Fracción de paquetes perdidos en un intervalo a partir de la cual una
/// medida cuenta como mala.
const double weakLinkLoss = 0.08;

/// Medidas malas seguidas para pasar a débil (unos 4 s).
const int weakLinkBadSamples = 2;

/// Medidas buenas seguidas para volver a bueno (unos 6 s): más que para
/// empeorar, para que el aviso no parpadee.
const int weakLinkGoodSamples = 3;

/// Decide la calidad de cada enlace a partir de sus [LinkSample], con
/// histéresis: pasa a débil tras [weakLinkBadSamples] medidas malas seguidas
/// y vuelve a bueno tras [weakLinkGoodSamples] buenas.
///
/// Una medida es mala si el tiempo de ida y vuelta supera [weakLinkRttMs] o
/// si en el intervalo se perdió al menos [weakLinkLoss] de los paquetes. Sin
/// paquetes nuevos en el intervalo la pérdida no cuenta (no se sabe).
class LinkQualityClassifier {
  final Map<String, LinkSample> _last = {};
  final Map<String, int> _bad = {};
  final Map<String, int> _good = {};
  final Map<String, LinkQuality> _quality = {};

  /// Calidad actual de cada enlace conocido.
  Map<String, LinkQuality> get quality => Map.unmodifiable(_quality);

  /// Suma una medida de cada enlace y devuelve la calidad de todos. Los
  /// enlaces que ya no aparecen se olvidan.
  Map<String, LinkQuality> add(Map<String, LinkSample> samples) {
    for (final id in [..._quality.keys]) {
      if (!samples.containsKey(id)) _forget(id);
    }
    for (final MapEntry(key: id, value: sample) in samples.entries) {
      final bad = _isBad(sample, _last[id]);
      _last[id] = sample;
      final current = _quality[id] ?? LinkQuality.good;
      if (bad) {
        _good[id] = 0;
        final count = _bad[id] = (_bad[id] ?? 0) + 1;
        _quality[id] = count >= weakLinkBadSamples ? LinkQuality.weak : current;
      } else {
        _bad[id] = 0;
        final count = _good[id] = (_good[id] ?? 0) + 1;
        _quality[id] = count >= weakLinkGoodSamples
            ? LinkQuality.good
            : current;
      }
    }
    return quality;
  }

  /// Olvida todo, p. ej. al salir de la frecu.
  void reset() {
    _last.clear();
    _bad.clear();
    _good.clear();
    _quality.clear();
  }

  void _forget(String id) {
    _last.remove(id);
    _bad.remove(id);
    _good.remove(id);
    _quality.remove(id);
  }

  static bool _isBad(LinkSample sample, LinkSample? previous) {
    final rtt = sample.rttMs;
    if (rtt != null && rtt > weakLinkRttMs) return true;
    final loss = _lossBetween(previous, sample);
    return loss != null && loss >= weakLinkLoss;
  }

  /// Fracción perdida entre dos medidas acumuladas, o nula si no se sabe.
  static double? _lossBetween(LinkSample? before, LinkSample after) {
    final r1 = after.packetsReceived;
    final l1 = after.packetsLost;
    final r0 = before?.packetsReceived;
    final l0 = before?.packetsLost;
    if (r1 == null || l1 == null || r0 == null || l0 == null) return null;
    final received = r1 - r0;
    final lost = l1 - l0;
    // Contadores que vuelven atrás (un enlace nuevo con el mismo id).
    if (received < 0 || lost < 0) return null;
    final expected = received + lost;
    if (expected == 0) return null;
    return lost / expected;
  }
}

/// Mide la calidad de los enlaces cada [linkQualityInterval] mientras
/// alguien escucha [watch], con un [LinkQualityClassifier]. Cuando nadie
/// escucha deja de medir y olvida lo medido.
class LinkQualityMonitor {
  /// Crea el monitor con la función que lee las medidas.
  LinkQualityMonitor(this._read, {this.interval = linkQualityInterval});

  final Future<Map<String, LinkSample>> Function() _read;

  /// Cada cuánto se mide.
  final Duration interval;
  final LinkQualityClassifier _classifier = LinkQualityClassifier();

  late final StreamController<Map<String, LinkQuality>> _controller =
      StreamController<Map<String, LinkQuality>>.broadcast(
        onListen: _sync,
        onCancel: _sync,
      );

  Timer? _timer;
  bool _reading = false;
  bool _disposed = false;
  Map<String, LinkQuality> _quality = const {};

  /// Calidad de cada enlace por id del par: la actual y después cada cambio.
  Stream<Map<String, LinkQuality>> watch() async* {
    yield _quality;
    yield* _controller.stream;
  }

  void _sync() {
    if (_controller.hasListener && !_disposed) {
      _timer ??= Timer.periodic(interval, (_) => unawaited(_tick()));
      return;
    }
    _stop();
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
    _classifier.reset();
    _quality = const {};
  }

  Future<void> _tick() async {
    if (_reading) return;
    _reading = true;
    try {
      final samples = await _read();
      if (_timer == null) return;
      final quality = _classifier.add(samples);
      if (!mapEquals(quality, _quality)) {
        _quality = quality;
        _controller.add(_quality);
      }
    } on Object catch (e, st) {
      AppLogger.w('Failed to read link quality', e, st);
    } finally {
      _reading = false;
    }
  }

  /// Deja de medir y cierra el flujo.
  Future<void> dispose() async {
    _disposed = true;
    _stop();
    await _controller.close();
  }
}
