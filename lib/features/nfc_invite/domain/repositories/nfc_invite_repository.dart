import 'package:frecu/core/result/result.dart';

/// Invitación por NFC: leerla de una etiqueta o del teléfono del anfitrión,
/// grabarla en una etiqueta y, en Android, hacer del teléfono una etiqueta
/// con la invitación (Host Card Emulation).
abstract interface class NfcInviteRepository {
  /// Si el teléfono tiene NFC (encendido o no).
  Future<bool> isSupported();

  /// Espera a que se acerque una etiqueta o un teléfono y devuelve la
  /// invitación que trae (`frecu://join?…`). Falla con `Failure.nfc`.
  Future<Result<String>> readInvite();

  /// Espera a que se acerque una etiqueta y graba en ella [uri]. Falla con
  /// `Failure.nfc`.
  Future<Result<void>> writeInvite(String uri);

  /// Cancela la lectura o la grabación en curso.
  Future<void> cancel();

  /// Hace de este teléfono una etiqueta con [uri] para quien lo acerque, o
  /// deja de hacerlo con `null`. Devuelve si el teléfono puede (Android con
  /// NFC).
  Future<bool> share(String? uri);
}
