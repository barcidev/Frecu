import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:frecu/core/constants/cloud_config.dart';
import 'package:frecu/core/logging/app_logger.dart';
import 'package:frecu/features/room/domain/entities/ice_server.dart';

/// Pide al punto de encuentro los servidores STUN y TURN de una frecu por
/// internet. Si no responden, la voz queda con el STUN público: conecta
/// directo cuando el NAT lo deja, sin relé.
class TurnCredentialsDataSource {
  /// Crea la fuente con el [config] del modo internet.
  TurnCredentialsDataSource({
    this.config = CloudConfig.fromEnvironment,
    this.timeout = const Duration(seconds: 5),
    HttpClient Function()? httpClientFactory,
  }) : _httpClientFactory = httpClientFactory ?? HttpClient.new;

  /// Punto de encuentro.
  final CloudConfig config;

  /// Espera máxima de la respuesta.
  final Duration timeout;

  final HttpClient Function() _httpClientFactory;

  /// Servidores para la frecu [internetId]; nunca falla.
  Future<List<IceServer>> fetch(String internetId) async {
    if (!config.isEnabled) return const [IceServer.cloudflareStun];
    final client = _httpClientFactory();
    try {
      final request = await client
          .postUrl(config.turnCredentials(internetId))
          .timeout(timeout);
      final response = await request.close().timeout(timeout);
      final body = await response
          .transform(utf8.decoder)
          .join()
          .timeout(timeout);
      if (response.statusCode != HttpStatus.ok) {
        AppLogger.w('TURN credentials refused: ${response.statusCode}');
        return const [IceServer.cloudflareStun];
      }
      final servers = parse(body);
      return servers.isEmpty ? const [IceServer.cloudflareStun] : servers;
    } on Object catch (e) {
      AppLogger.w('Could not fetch TURN credentials: $e');
      return const [IceServer.cloudflareStun];
    } finally {
      client.close(force: true);
    }
  }

  /// Lee `{"iceServers":[{urls, username?, credential?}]}`; `urls` puede
  /// ser un texto o una lista. Lo que no se entiende se descarta.
  static List<IceServer> parse(String body) {
    try {
      final json = jsonDecode(body);
      if (json is! Map<String, dynamic>) return const [];
      final raw = json['iceServers'];
      final entries = raw is List ? raw : [raw];
      return [
        for (final entry in entries)
          if (entry is Map<String, dynamic>)
            if (_urls(entry['urls']) case final urls when urls.isNotEmpty)
              IceServer(
                urls: urls,
                username: entry['username'] as String?,
                credential: entry['credential'] as String?,
              ),
      ];
    } on Object {
      return const [];
    }
  }

  static List<String> _urls(Object? value) => switch (value) {
    final String url => [url],
    final List<dynamic> urls => [
      for (final url in urls)
        if (url is String) url,
    ],
    _ => const [],
  };
}
