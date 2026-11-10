import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:frecu/core/error/failure.dart';
import 'package:frecu/core/logging/app_logger.dart';
import 'package:frecu/core/result/result.dart';
import 'package:frecu/features/nfc_invite/domain/entities/ndef_uri.dart';
import 'package:frecu/features/nfc_invite/domain/repositories/nfc_invite_repository.dart';
import 'package:nfc_manager/ndef_record.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/nfc_manager_ios.dart';
import 'package:nfc_manager_ndef/nfc_manager_ndef.dart';

/// Lo que se hace con una etiqueta NDEF; las pruebas lo reemplazan.
abstract interface class NfcNdefTag {
  /// Si se puede grabar.
  bool get isWritable;

  /// Bytes que caben.
  int get maxSize;

  /// El mensaje leído al acercarla, o nulo.
  Future<NdefMessage?> read();

  /// Graba [message].
  Future<void> write(NdefMessage message);
}

class _PluginTag implements NfcNdefTag {
  _PluginTag(this._ndef);

  final Ndef _ndef;

  @override
  bool get isWritable => _ndef.isWritable;

  @override
  int get maxSize => _ndef.maxSize;

  @override
  Future<NdefMessage?> read() async => _ndef.cachedMessage ?? _ndef.read();

  @override
  Future<void> write(NdefMessage message) => _ndef.write(message: message);
}

/// Textos del aviso de NFC de iPhone.
typedef NfcIosTexts = ({
  String read,
  String write,
  String done,
  String notInvite,
  String failed,
});

/// Invitación por NFC con `nfc_manager` (leer y grabar etiquetas, en
/// Android e iPhone) y el canal `frecu/nfc_host` (el teléfono Android como
/// etiqueta, Host Card Emulation).
///
/// Solo en Android e iOS: en otra plataforma (las pruebas) no hay NFC. Las
/// pruebas reemplazan el gestor, la lectura de la etiqueta y el canal.
class NfcInviteRepositoryImpl implements NfcInviteRepository {
  /// Crea el repositorio; [texts] da los textos del aviso de iPhone.
  NfcInviteRepositoryImpl({
    required this.texts,
    this.manager,
    NfcNdefTag? Function(NfcTag tag)? ndefOf,
    Future<Object?> Function(String method, Object? arguments)? invoke,
    bool? supported,
    bool? hosts,
  }) : _ndefOf = ndefOf ?? _pluginTag,
       _invoke = invoke ?? _channelInvoke,
       _supported = supported ?? (Platform.isAndroid || Platform.isIOS),
       _hosts = hosts ?? Platform.isAndroid;

  static const MethodChannel _host = MethodChannel('frecu/nfc_host');

  /// Textos del aviso de NFC de iPhone, en el idioma de la app.
  final NfcIosTexts Function() texts;

  /// Gestor de NFC; si falta, el del paquete.
  final NfcManager? manager;
  final NfcNdefTag? Function(NfcTag tag) _ndefOf;
  final Future<Object?> Function(String method, Object? arguments) _invoke;
  final bool _supported;
  final bool _hosts;

  /// Lectura o grabación en curso: una a la vez.
  Completer<Object?>? _session;

  NfcManager get _nfc => manager ?? NfcManager.instance;

  static NfcNdefTag? _pluginTag(NfcTag tag) {
    final ndef = Ndef.from(tag);
    return ndef == null ? null : _PluginTag(ndef);
  }

  static Future<Object?> _channelInvoke(String method, Object? arguments) =>
      _host.invokeMethod<Object?>(method, arguments);

  static Result<T> _fail<T>(NfcFailureReason reason) =>
      Result.failure(Failure.nfc(reason));

  @override
  Future<bool> isSupported() async {
    if (!_supported) return false;
    try {
      return await _nfc.checkAvailability() != NfcAvailability.unsupported;
    } on Object catch (error) {
      AppLogger.d('NFC availability: $error');
      return false;
    }
  }

  @override
  Future<Result<String>> readInvite() => _run<String>(
    prompt: texts().read,
    onTag: (tag) async {
      final message = await tag.read();
      for (final record in message?.records ?? const <NdefRecord>[]) {
        if (record.typeNameFormat != TypeNameFormat.wellKnown) continue;
        final uri = NdefUri.parse(record.type, record.payload);
        if (uri != null && uri.toLowerCase().startsWith('frecu:')) {
          return Result.success(uri);
        }
      }
      return _fail(NfcFailureReason.notInvite);
    },
  );

  @override
  Future<Result<void>> writeInvite(String uri) => _run<void>(
    prompt: texts().write,
    onTag: (tag) async {
      if (!tag.isWritable) return _fail(NfcFailureReason.readOnly);
      final message = NdefMessage(
        records: [
          NdefRecord(
            typeNameFormat: TypeNameFormat.wellKnown,
            type: Uint8List.fromList(NdefUri.type),
            identifier: Uint8List(0),
            payload: Uint8List.fromList(NdefUri.payload(uri)),
          ),
        ],
      );
      if (message.byteLength > tag.maxSize) {
        return _fail(NfcFailureReason.tooSmall);
      }
      await tag.write(message);
      return const Result.success(null);
    },
  );

  /// Abre una sesión, espera una etiqueta, hace [onTag] con ella y cierra.
  Future<Result<T>> _run<T>({
    required String prompt,
    required Future<Result<T>> Function(NfcNdefTag tag) onTag,
  }) async {
    if (!_supported) return _fail(NfcFailureReason.failed);
    await cancel();
    final session = Completer<Object?>();
    _session = session;
    final ios = texts();
    try {
      await _nfc.startSession(
        pollingOptions: const {
          NfcPollingOption.iso14443,
          NfcPollingOption.iso15693,
        },
        alertMessageIos: prompt,
        onDiscovered: (raw) async {
          if (session.isCompleted) return;
          Result<T> result;
          try {
            final tag = _ndefOf(raw);
            result = tag == null
                ? _fail(NfcFailureReason.notInvite)
                : await onTag(tag);
          } on Object catch (error) {
            AppLogger.d('NFC tag: $error');
            result = _fail(NfcFailureReason.failed);
          }
          if (session.isCompleted) return;
          session.complete(result);
          await _stop(
            failed: result.isFailure,
            reason: result.failureOrNull,
            texts: ios,
          );
        },
        onSessionErrorIos: (error) {
          if (session.isCompleted) return;
          session.complete(
            _fail<T>(
              error.code ==
                      NfcReaderErrorCodeIos
                          .readerSessionInvalidationErrorUserCanceled
                  ? NfcFailureReason.cancelled
                  : NfcFailureReason.failed,
            ),
          );
        },
      );
    } on Object catch (error) {
      AppLogger.w('Could not start NFC', error);
      if (!session.isCompleted) {
        session.complete(_fail<T>(NfcFailureReason.failed));
      }
    }
    final result = await session.future;
    if (identical(_session, session)) _session = null;
    // Cancelar no sabe el tipo de la sesión: deja solo el motivo.
    if (result is NfcFailureReason) return _fail(result);
    return result! as Result<T>;
  }

  Future<void> _stop({
    required bool failed,
    required Failure? reason,
    required NfcIosTexts texts,
  }) async {
    try {
      if (!failed) {
        await _nfc.stopSession(alertMessageIos: texts.done);
      } else {
        await _nfc.stopSession(
          errorMessageIos:
              reason == const Failure.nfc(NfcFailureReason.notInvite)
              ? texts.notInvite
              : texts.failed,
        );
      }
    } on Object catch (error) {
      AppLogger.d('NFC stop: $error');
    }
  }

  @override
  Future<void> cancel() async {
    final session = _session;
    _session = null;
    if (session == null || session.isCompleted) return;
    session.complete(NfcFailureReason.cancelled);
    try {
      await _nfc.stopSession();
    } on Object catch (error) {
      AppLogger.d('NFC cancel: $error');
    }
  }

  @override
  Future<bool> share(String? uri) async {
    if (!_hosts) return false;
    try {
      return await _invoke('share', uri) == true;
    } on Object catch (error) {
      AppLogger.d('NFC host: $error');
      return false;
    }
  }
}
