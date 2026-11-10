import 'dart:io';

import 'package:app_links/app_links.dart';
import 'package:frecu/core/logging/app_logger.dart';

/// Enlaces de invitación (`frecu://join?…`) que abren la app: desde otra
/// app, la cámara del sistema o, en Android, al acercar una etiqueta o el
/// teléfono del anfitrión (NFC). Incluye el que la abrió.
///
/// Solo en Android e iOS: en otra plataforma (las pruebas) no llega
/// ninguno. Las pruebas reemplazan los enlaces.
class InviteLinksDataSource {
  /// Crea la fuente; [links] reemplaza a los del sistema en pruebas.
  InviteLinksDataSource({this.links});

  /// Enlaces de prueba; si faltan, los del sistema.
  final Stream<Uri>? links;

  /// Cada enlace de invitación que llega.
  Stream<Uri> watch() {
    final incoming =
        links ??
        (Platform.isAndroid || Platform.isIOS
            ? AppLinks().uriLinkStream
            : const Stream<Uri>.empty());
    return incoming
        .where(
          (uri) =>
              uri.scheme.toLowerCase() == 'frecu' &&
              uri.host.toLowerCase() == 'join',
        )
        .handleError((Object error) => AppLogger.d('Invite links: $error'));
  }
}
