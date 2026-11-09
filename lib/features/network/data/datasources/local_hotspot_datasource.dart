import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:frecu/core/logging/app_logger.dart';
import 'package:permission_handler/permission_handler.dart';

/// Lo que Android dice de la red recién creada.
@immutable
class LocalHotspotInfo {
  /// Crea los datos de la red [ssid].
  const LocalHotspotInfo({
    required this.ssid,
    this.passphrase,
    this.interfaceName,
    this.address,
  });

  /// Nombre de la red.
  final String ssid;

  /// Clave; nula si la red es abierta.
  final String? passphrase;

  /// Interfaz de la red en este teléfono, si Android la dio a conocer.
  final String? interfaceName;

  /// IPv4 de este teléfono en la red, si Android la dio a conocer.
  final String? address;
}

/// Fallo del canal al crear la red, con el código nativo.
class LocalHotspotException implements Exception {
  /// Crea el fallo con el [code] nativo: `unsupported`, `permission_nearby`,
  /// `permission_location`, `location_off`, `incompatible_mode`, `failed`…
  const LocalHotspotException(this.code);

  /// Código nativo del fallo.
  final String code;

  @override
  String toString() => 'LocalHotspotException($code)';
}

/// Canal `frecu/hotspot`: la red de la frecu que crea Android para la app
/// (`LocalOnlyHotspot`), y el permiso que exige.
///
/// Android avisa con `stopped` cuando apaga la red sin que la app lo pida.
/// Las pruebas reemplazan el canal, el aviso y la petición del permiso.
class LocalHotspotDataSource {
  /// Crea el datasource.
  LocalHotspotDataSource({
    Future<Object?> Function(String method)? invoke,
    Stream<void>? stopped,
    Future<PermissionStatus> Function(Permission permission)? requestPermission,
  }) : _invoke = invoke ?? _channelInvoke,
       _stoppedOverride = stopped,
       _requestPermission = requestPermission ?? _request;

  /// Canal nativo.
  static const MethodChannel channel = MethodChannel('frecu/hotspot');

  static final StreamController<void> _channelStopped =
      StreamController<void>.broadcast();
  static bool _listening = false;

  final Future<Object?> Function(String method) _invoke;
  final Stream<void>? _stoppedOverride;
  final Future<PermissionStatus> Function(Permission permission)
  _requestPermission;

  static Future<Object?> _channelInvoke(String method) =>
      channel.invokeMethod<Object?>(method);

  static Future<PermissionStatus> _request(Permission permission) =>
      permission.request();

  /// Cada vez que Android apaga la red por su cuenta.
  Stream<void> get stopped => _stoppedOverride ?? _listenChannel();

  static Stream<void> _listenChannel() {
    if (!_listening) {
      try {
        channel.setMethodCallHandler((call) async {
          if (call.method == 'stopped') _channelStopped.add(null);
        });
        _listening = true;
      } on Object catch (e) {
        AppLogger.d('Hotspot channel unavailable: $e');
      }
    }
    return _channelStopped.stream;
  }

  /// Crea la red o devuelve la que ya estaba al aire. Lanza
  /// [LocalHotspotException] con el código nativo.
  Future<LocalHotspotInfo> start() async {
    // Escucha antes de crearla: un apagado temprano no se pierde.
    if (_stoppedOverride == null) _listenChannel();
    final Object? raw;
    try {
      raw = await _invoke('start');
    } on PlatformException catch (e) {
      throw LocalHotspotException(e.code);
    } on MissingPluginException {
      throw const LocalHotspotException('unsupported');
    }
    final map = raw is Map ? raw : const <Object?, Object?>{};
    final ssid = map['ssid'];
    if (ssid is! String || ssid.isEmpty) {
      throw const LocalHotspotException('failed');
    }
    String? text(String key) {
      final value = map[key];
      return value is String && value.isNotEmpty ? value : null;
    }

    return LocalHotspotInfo(
      ssid: ssid,
      passphrase: text('passphrase'),
      interfaceName: text('interface'),
      address: text('address'),
    );
  }

  /// Apaga la red; un fallo se registra y no rompe nada.
  Future<void> stop() async {
    try {
      await _invoke('stop');
    } on Object catch (e) {
      AppLogger.d('Could not stop the local hotspot: $e');
    }
  }

  /// Pide el permiso de dispositivos cercanos (Android 13 o posterior) o,
  /// sin [nearby], el de ubicación. Verdadero si quedó concedido.
  Future<bool> requestPermission({required bool nearby}) async {
    try {
      final status = await _requestPermission(
        nearby ? Permission.nearbyWifiDevices : Permission.locationWhenInUse,
      );
      return status.isGranted || status.isLimited;
    } on Object catch (e) {
      AppLogger.w('Could not request the hotspot permission: $e');
      return false;
    }
  }
}
