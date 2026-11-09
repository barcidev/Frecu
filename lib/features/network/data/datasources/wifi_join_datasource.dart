import 'dart:io';

import 'package:flutter/services.dart';
import 'package:frecu/core/logging/app_logger.dart';

/// Fallo del canal al conectar a la red, con el código nativo.
class WifiJoinException implements Exception {
  /// Crea el fallo con el [code] nativo: `unsupported`, `declined`,
  /// `not_found` o `failed`.
  const WifiJoinException(this.code);

  /// Código nativo del fallo.
  final String code;

  @override
  String toString() => 'WifiJoinException($code)';
}

/// Canal `frecu/wifi`: conectar el teléfono del invitado a la red de la
/// frecu (Android, `WifiNetworkSpecifier`; iOS, `NEHotspotConfiguration`) y,
/// en Android, atar la app a esa red. Más la prueba de si el anfitrión
/// responde.
///
/// El canal solo existe en Android e iOS, y atarse a la red solo hace falta
/// en Android: en otra plataforma (las pruebas) no se llama, porque esperar
/// una respuesta que no llega detendría la unión.
///
/// Las pruebas reemplazan el canal, la prueba de conexión y la plataforma.
class WifiJoinDataSource {
  /// Crea el datasource; [routes] y [native] dicen si la plataforma ata la
  /// app a la red (Android) y si tiene la parte nativa (Android e iOS).
  WifiJoinDataSource({
    Future<Object?> Function(String method, Object? arguments)? invoke,
    Future<bool> Function(String host, int port, Duration timeout)? probe,
    bool? routes,
    bool? native,
  }) : _invoke = invoke ?? _channelInvoke,
       _probe = probe ?? _socketProbe,
       _routes = routes ?? Platform.isAndroid,
       _native = native ?? (Platform.isAndroid || Platform.isIOS);

  /// Canal nativo.
  static const MethodChannel channel = MethodChannel('frecu/wifi');

  final Future<Object?> Function(String method, Object? arguments) _invoke;
  final Future<bool> Function(String host, int port, Duration timeout) _probe;
  final bool _routes;
  final bool _native;

  static Future<Object?> _channelInvoke(String method, Object? arguments) =>
      channel.invokeMethod<Object?>(method, arguments);

  static Future<bool> _socketProbe(
    String host,
    int port,
    Duration timeout,
  ) async {
    try {
      final socket = await Socket.connect(host, port, timeout: timeout);
      socket.destroy();
      return true;
    } on Object {
      return false;
    }
  }

  /// Ata la app a la red en la que está [host] (Android). Verdadero si la
  /// encontró; falso en iOS o si el canal no está.
  Future<bool> route(String host) async {
    if (!_routes) return false;
    try {
      return await _invoke('route', {'host': host}) == true;
    } on Object catch (e) {
      AppLogger.d('Wi-Fi route unavailable: $e');
      return false;
    }
  }

  /// Conecta el teléfono a la red [ssid] con el aviso del sistema. Lanza
  /// [WifiJoinException] con el código nativo.
  Future<void> join(String ssid, String? passphrase) async {
    if (!_native) throw const WifiJoinException('unsupported');
    try {
      await _invoke('join', {'ssid': ssid, 'passphrase': passphrase});
    } on PlatformException catch (e) {
      throw WifiJoinException(e.code);
    } on MissingPluginException {
      throw const WifiJoinException('unsupported');
    }
  }

  /// Suelta la red que conectó la app y desata la app; un fallo se registra
  /// y no rompe nada.
  Future<void> release() async {
    if (!_native) return;
    try {
      await _invoke('release', null);
    } on Object catch (e) {
      AppLogger.d('Wi-Fi release unavailable: $e');
    }
  }

  /// Verdadero si [host]:[port] acepta una conexión antes de [timeout].
  Future<bool> probe(String host, int port, Duration timeout) =>
      _probe(host, port, timeout);
}
