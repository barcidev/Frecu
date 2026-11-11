import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:share_plus/share_plus.dart';

part 'share_provider.g.dart';

/// Abre la hoja de compartir del sistema con un texto.
typedef ShareText = Future<void> Function(String text);

/// Compartir del sistema (WhatsApp, mensajes…); en pruebas se reemplaza.
@Riverpod(keepAlive: true)
ShareText shareText(Ref ref) =>
    (text) => SharePlus.instance.share(ShareParams(text: text));
