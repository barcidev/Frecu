import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:frecu/core/logging/app_logger.dart';
import 'package:frecu/features/room/data/datasources/peer_connection_datasource.dart';

/// Cada cuánto se leen los niveles de voz: unas 10 veces por segundo.
const Duration voiceLevelInterval = Duration(milliseconds: 100);

/// Lee los niveles de voz con un solo temporizador mientras alguien escucha
/// el nivel propio o el de los pares, y emite cada flujo solo cuando cambia.
/// Cuando nadie escucha deja de leer y los niveles vuelven a 0.
class VoiceLevelSampler {
  /// Crea el muestreo con la función que lee los niveles.
  VoiceLevelSampler(this._read);

  final Future<VoiceLevels> Function() _read;

  late final StreamController<double> _localController =
      StreamController<double>.broadcast(onListen: _sync, onCancel: _sync);
  late final StreamController<Map<String, double>> _peersController =
      StreamController<Map<String, double>>.broadcast(
        onListen: _sync,
        onCancel: _sync,
      );

  Timer? _timer;
  bool _reading = false;
  bool _disposed = false;
  double _local = 0;
  Map<String, double> _peers = const {};

  /// Nivel propio: el actual y después cada cambio.
  Stream<double> watchLocal() async* {
    yield _local;
    yield* _localController.stream;
  }

  /// Nivel de cada par por id: el actual y después cada cambio.
  Stream<Map<String, double>> watchPeers() async* {
    yield _peers;
    yield* _peersController.stream;
  }

  /// Arranca el temporizador con el primer oyente y lo para, con los niveles
  /// en 0, cuando ya no queda ninguno o al liberarlo.
  void _sync() {
    final listening =
        _localController.hasListener || _peersController.hasListener;
    if (listening && !_disposed) {
      _timer ??= Timer.periodic(voiceLevelInterval, (_) => unawaited(_tick()));
      return;
    }
    _stop();
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
    _local = 0;
    _peers = const {};
  }

  /// Lee una vez, salvo si la lectura anterior no terminó.
  Future<void> _tick() async {
    if (_reading) return;
    _reading = true;
    try {
      final levels = await _read();
      if (_timer == null) return;
      if (levels.local != _local) {
        _local = levels.local;
        _localController.add(_local);
      }
      if (!mapEquals(levels.peers, _peers)) {
        _peers = Map.unmodifiable(levels.peers);
        _peersController.add(_peers);
      }
    } on Object catch (e, st) {
      AppLogger.w('Failed to read voice levels', e, st);
    } finally {
      _reading = false;
    }
  }

  /// Deja de leer y cierra los flujos.
  Future<void> dispose() async {
    _disposed = true;
    _stop();
    await _localController.close();
    await _peersController.close();
  }
}
