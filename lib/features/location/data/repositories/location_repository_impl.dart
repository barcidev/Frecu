import 'dart:async';

import 'package:frecu/core/error/failure.dart';
import 'package:frecu/core/logging/app_logger.dart';
import 'package:frecu/core/result/result.dart';
import 'package:frecu/features/location/data/datasources/position_datasource.dart';
import 'package:frecu/features/location/domain/entities/geo_point.dart';
import 'package:frecu/features/location/domain/repositories/location_repository.dart';
import 'package:frecu/features/room/data/datasources/foreground_service_datasource.dart';
import 'package:frecu/features/room/data/datasources/signaling_client_datasource.dart';
import 'package:frecu/features/room/data/models/signaling_message.dart';
import 'package:frecu/features/room/data/repositories/current_then.dart';

/// Envía la propia como mucho cada [positionSendEvery], salvo que se haya
/// movido [positionSendDistance] metros.
const Duration positionSendEvery = Duration(seconds: 5);

/// Movimiento que se envía sin esperar.
const double positionSendDistance = 20;

/// Ubicación compartida por la señalización de la frecu (`position`).
class LocationRepositoryImpl implements LocationRepository {
  /// Crea el repositorio; escucha las posiciones de los demás desde ya.
  LocationRepositoryImpl(
    this._positions,
    this._signaling,
    this._foreground, {
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now {
    _signalingSub = _signaling.messages.listen(_onMessage);
  }

  final PositionDataSource _positions;
  final SignalingClientDataSource _signaling;
  final ForegroundServiceDataSource _foreground;
  final DateTime Function() _clock;

  StreamSubscription<SignalingMessage>? _signalingSub;
  StreamSubscription<GeoPoint>? _gpsSub;

  final StreamController<Map<String, GeoPoint>> _peersController =
      StreamController<Map<String, GeoPoint>>.broadcast();
  final StreamController<GeoPoint> _ownController =
      StreamController<GeoPoint>.broadcast();

  Map<String, GeoPoint> _peers = const {};
  GeoPoint? _lastSent;
  DateTime? _lastSentAt;

  @override
  bool get isSharing => _gpsSub != null;

  @override
  Stream<Map<String, GeoPoint>> watchPeers() =>
      currentThen(() => _peers, _peersController.stream);

  @override
  Stream<GeoPoint> watchOwn() => _ownController.stream;

  void _onMessage(SignalingMessage message) {
    switch (message) {
      case SignalingPositionMessage(:final peerId, :final lat, :final lon):
        final next = {..._peers};
        if (lat == null || lon == null) {
          next.remove(peerId);
        } else {
          next[peerId] = GeoPoint(lat: lat, lon: lon);
        }
        _setPeers(next);
      case SignalingPeerLeftMessage(:final peerId):
        if (_peers.containsKey(peerId)) _setPeers({..._peers}..remove(peerId));
      // Otra frecu o una reconexión: lo de antes ya no vale.
      case SignalingWelcomeMessage() || SignalingRoomClosedMessage():
        _setPeers(const {});
      default:
        break;
    }
  }

  void _setPeers(Map<String, GeoPoint> peers) {
    _peers = Map.unmodifiable(peers);
    _peersController.add(_peers);
  }

  @override
  Future<Result<void>> startSharing() async {
    if (isSharing) return const Result.success(null);
    try {
      await _foreground.setLocationActive(active: true);
      _gpsSub = _positions.watch().listen(
        _onOwn,
        onError: (Object e) => AppLogger.w('GPS error: $e'),
      );
      return const Result.success(null);
    } on Object catch (e) {
      await stopSharing();
      return Result.failure(Failure.unexpected(message: '$e', error: e));
    }
  }

  void _onOwn(GeoPoint point) {
    _ownController.add(point);
    final last = _lastSent;
    final at = _lastSentAt;
    final now = _clock();
    final due =
        last == null ||
        at == null ||
        now.difference(at) >= positionSendEvery ||
        last.distanceTo(point) >= positionSendDistance;
    if (!due || !_signaling.isConnected) return;
    _lastSent = point;
    _lastSentAt = now;
    // El anfitrión cambia el id por el del socket que lo envía.
    _signaling.send(
      SignalingMessage.position(peerId: '', lat: point.lat, lon: point.lon),
    );
  }

  @override
  Future<void> stopSharing() async {
    final wasSharing = isSharing;
    await _gpsSub?.cancel();
    _gpsSub = null;
    _lastSent = null;
    _lastSentAt = null;
    if (wasSharing && _signaling.isConnected) {
      _signaling.send(const SignalingMessage.position(peerId: ''));
    }
    await _foreground.setLocationActive(active: false);
  }

  /// Deja de compartir y de escuchar.
  Future<void> dispose() async {
    await stopSharing();
    await _signalingSub?.cancel();
    await _peersController.close();
    await _ownController.close();
  }
}
