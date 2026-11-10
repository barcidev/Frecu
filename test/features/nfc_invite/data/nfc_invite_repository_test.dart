// Invitar por NFC (corte 9 de la épica de hardware V1), con el gestor de
// NFC simulado: leer devuelve la invitación de Frecu de la etiqueta o del
// teléfono; grabar escribe un registro URI si la etiqueta se puede grabar y
// cabe; cancelar corta la espera; y solo Android hace de etiqueta.
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/core/error/failure.dart';
import 'package:frecu/features/nfc_invite/data/repositories/nfc_invite_repository_impl.dart';
import 'package:frecu/features/nfc_invite/domain/entities/ndef_uri.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nfc_manager/ndef_record.dart';
import 'package:nfc_manager/nfc_manager.dart';

class _MockNfcManager extends Mock implements NfcManager {}

/// Etiqueta de prueba: lo que trae y lo que se le graba.
class _Tag implements NfcNdefTag {
  _Tag({this.message, this.isWritable = true, this.maxSize = 512});

  final NdefMessage? message;
  NdefMessage? written;

  @override
  final bool isWritable;

  @override
  final int maxSize;

  @override
  Future<NdefMessage?> read() async => message;

  @override
  Future<void> write(NdefMessage message) async => written = message;
}

const _invite = 'frecu://join?h=192.168.49.1&p=47800&r=room-1&c=4827';

NdefRecord _uri(String uri) => NdefRecord(
  typeNameFormat: TypeNameFormat.wellKnown,
  type: Uint8List.fromList(NdefUri.type),
  identifier: Uint8List(0),
  payload: Uint8List.fromList(NdefUri.payload(uri)),
);

const _texts = (
  read: 'leer',
  write: 'grabar',
  done: 'listo',
  notInvite: 'no es',
  failed: 'falló',
);

void main() {
  late _MockNfcManager manager;
  late void Function(NfcTag tag) discovered;
  late _Tag? tag;
  late List<(String, Object?)> calls;

  NfcInviteRepositoryImpl repository({bool hosts = true}) =>
      NfcInviteRepositoryImpl(
        texts: () => _texts,
        manager: manager,
        ndefOf: (_) => tag,
        invoke: (method, arguments) async {
          calls.add((method, arguments));
          return true;
        },
        supported: true,
        hosts: hosts,
      );

  setUp(() {
    manager = _MockNfcManager();
    tag = null;
    calls = [];
    when(
      () => manager.startSession(
        pollingOptions: any(named: 'pollingOptions'),
        onDiscovered: any(named: 'onDiscovered'),
        alertMessageIos: any(named: 'alertMessageIos'),
        onSessionErrorIos: any(named: 'onSessionErrorIos'),
      ),
    ).thenAnswer((call) async {
      discovered =
          call.namedArguments[#onDiscovered] as void Function(NfcTag tag);
    });
    when(
      () => manager.stopSession(
        alertMessageIos: any(named: 'alertMessageIos'),
        errorMessageIos: any(named: 'errorMessageIos'),
      ),
    ).thenAnswer((_) async {});
    when(() => manager.checkAvailability())
        .thenAnswer((_) async => NfcAvailability.disabled);
  });

  Future<T> withTag<T>(Future<T> pending, _Tag? next) async {
    await pumpEventQueue();
    tag = next;
    discovered(const NfcTag(data: Object()));
    return pending;
  }

  test(
    'con NFC (aunque esté apagado) se ofrece; sin la plataforma, no',
    () async {
      expect(await repository().isSupported(), isTrue);
      expect(
        await NfcInviteRepositoryImpl(
          texts: () => _texts,
          manager: manager,
          supported: false,
        ).isSupported(),
        isFalse,
      );
    },
  );

  test('leer devuelve la invitación de Frecu, aunque venga después de otro '
      'registro, y cierra con «listo»', () async {
    final result = await withTag(
      repository().readInvite(),
      _Tag(
        message: NdefMessage(
          records: [_uri('https://frecu.app'), _uri(_invite)],
        ),
      ),
    );

    expect(result.dataOrNull, _invite);
    verify(() => manager.stopSession(alertMessageIos: 'listo')).called(1);
  });

  test('una etiqueta sin invitación de Frecu, o que no es NDEF, no '
      'sirve', () async {
    final other = await withTag(
      repository().readInvite(),
      _Tag(message: NdefMessage(records: [_uri('https://frecu.app')])),
    );
    expect(other.failureOrNull, const Failure.nfc(NfcFailureReason.notInvite));
    verify(() => manager.stopSession(errorMessageIos: 'no es')).called(1);

    final notNdef = await withTag(repository().readInvite(), null);
    expect(
      notNdef.failureOrNull,
      const Failure.nfc(NfcFailureReason.notInvite),
    );
  });

  test('grabar escribe un registro URI con la invitación', () async {
    final target = _Tag();
    final result = await withTag(repository().writeInvite(_invite), target);

    expect(result.isSuccess, isTrue);
    final record = target.written!.records.single;
    expect(record.typeNameFormat, TypeNameFormat.wellKnown);
    expect(NdefUri.parse(record.type, record.payload), _invite);
  });

  test('una etiqueta de solo lectura o pequeña no se graba', () async {
    final readOnly = _Tag(isWritable: false);
    expect(
      (await withTag(
        repository().writeInvite(_invite),
        readOnly,
      )).failureOrNull,
      const Failure.nfc(NfcFailureReason.readOnly),
    );
    expect(readOnly.written, isNull);

    final small = _Tag(maxSize: 16);
    expect(
      (await withTag(repository().writeInvite(_invite), small)).failureOrNull,
      const Failure.nfc(NfcFailureReason.tooSmall),
    );
    expect(small.written, isNull);
  });

  test('cancelar corta la espera y cierra la sesión', () async {
    final nfc = repository();
    final pending = nfc.readInvite();
    await pumpEventQueue();

    await nfc.cancel();

    expect(
      (await pending).failureOrNull,
      const Failure.nfc(NfcFailureReason.cancelled),
    );
    verify(() => manager.stopSession()).called(1);
  });

  test('hacer de etiqueta pasa la invitación al canal (y nula para dejar), '
      'solo en Android', () async {
    expect(await repository().share(_invite), isTrue);
    expect(await repository().share(null), isTrue);
    expect(calls, [('share', _invite), ('share', null)]);

    expect(await repository(hosts: false).share(_invite), isFalse);
    expect(calls, hasLength(2));
  });
}
