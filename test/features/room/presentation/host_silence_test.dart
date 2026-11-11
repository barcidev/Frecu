// AC1: CUANDO el anfitrión de una frecu con traspaso deja de responder ENTONCES la isla, en tono de aviso, dice ««anfitrión» no responde · N s» con los segundos que lleva sin responder, por encima de los eventos pasajeros.
// AC2: CUANDO el anfitrión de una frecu con traspaso deja de responder ENTONCES en la malla solo el anfitrión aparece en «Reconectando» y los demás siguen con su enlace de voz.
// AC3: CUANDO el anfitrión de una frecu con traspaso deja de responder ENTONCES el PTT sigue habilitado («Mantén») y la pista dice «Siguen hablando · si no vuelve, «sucesor» toma la frecu», o «Siguen hablando · si no vuelve, tomas la frecu» si el sucesor es este teléfono.
// AC4: CUANDO la frecu no tiene traspaso, no hay sucesor o el anfitrión vuelve ENTONCES se ve lo de hoy: la reconexión con su cuenta atrás o la frecu conectada.
// AC5: CUANDO los textos de la espera se muestran en español o en inglés ENTONCES salen de slang, no suponen género y no dicen «router».
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/features/room/domain/entities/participant.dart';
import 'package:frecu/features/room/domain/entities/room_reach.dart';
import 'package:frecu/features/room/domain/entities/room_status.dart';
import 'package:frecu/features/room/domain/entities/room_succession.dart';
import 'package:frecu/features/room/domain/repositories/room_handover.dart';
import 'package:frecu/features/room/domain/repositories/room_repository.dart';
import 'package:frecu/features/room/presentation/providers/host_silence_provider.dart';
import 'package:frecu/features/room/presentation/providers/room_provider.dart';
import 'package:frecu/features/room/presentation/widgets/host_silence.dart';
import 'package:frecu/i18n/strings.g.dart';
import 'package:mocktail/mocktail.dart';

class _MockRooms extends Mock implements RoomRepository, RoomHandover {}

const _andres = Participant(id: 'peer_1', displayName: 'Andrés', isHost: true);
const _ana = Participant(id: 'peer_2', displayName: 'Ana');
const _leo = Participant(id: 'peer_3', displayName: 'Leo');

const _reconnecting = RoomStatus.reconnecting(
  retryIn: Duration(seconds: 2),
  attempt: 1,
);

RoomMember _member(String id, String name, {String? address}) => RoomMember(
  id: id,
  displayName: name,
  joinedAt: DateTime(2026, 11, 11, 16, 20),
  address: address,
);

/// Sucesión de Andrés (anfitrión), Ana y Leo en una Wi-Fi compartida.
RoomSuccession _succession({
  bool handover = true,
  RoomReach reach = RoomReach.local,
  List<RoomMember>? members,
}) => RoomSuccession(
  term: 1,
  handover: handover,
  name: 'Ruta 40',
  accessCode: '4821',
  reach: reach,
  members:
      members ??
      [
        _member('peer_1', 'Andrés', address: '192.168.1.20'),
        _member('peer_2', 'Ana', address: '192.168.1.21'),
        _member('peer_3', 'Leo', address: '192.168.1.22'),
      ],
);

HostSilence? _find({
  RoomStatus? status = _reconnecting,
  RoomSuccession? succession,
  List<Participant> participants = const [_andres, _ana, _leo],
  String? localId = 'peer_3',
}) => HostSilence.find(
  status: status,
  succession: succession ?? _succession(),
  participants: participants,
  localId: localId,
);

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.es));

  group('HostSilence.find', () {
    test('AC3: nombra al anfitrión y a la primera persona de la sucesión '
        'que sigue en la frecu', () {
      final silence = _find();

      expect(silence, isNotNull);
      expect(silence!.hostId, 'peer_1');
      expect(silence.hostName, 'Andrés');
      expect(silence.successor, 'Ana');
      expect(silence.youNext, isFalse);
    });

    test('AC3: si la sucesión sigue con este teléfono, eres tú', () {
      final silence = _find(localId: 'peer_2');

      expect(silence!.successor, 'Ana');
      expect(silence.youNext, isTrue);
    });

    test('AC3: salta a quien ya no está y, en local, a quien no tiene IP', () {
      final gone = _find(participants: const [_andres, _leo]);
      expect(gone!.successor, 'Leo');

      final noAddress = _find(
        succession: _succession(
          members: [
            _member('peer_1', 'Andrés', address: '192.168.1.20'),
            _member('peer_2', 'Ana'),
            _member('peer_3', 'Leo', address: '192.168.1.22'),
          ],
        ),
      );
      expect(noAddress!.successor, 'Leo');
      expect(noAddress.youNext, isTrue);
    });

    test('AC4: sin traspaso, sin reconectar, sin sucesor o siendo el '
        'anfitrión no hay espera', () {
      expect(_find(succession: _succession(handover: false)), isNull);
      expect(_find(status: const RoomStatus.connected()), isNull);
      expect(_find(status: const RoomStatus.connecting()), isNull);
      expect(_find(localId: 'peer_1'), isNull);
      expect(_find(localId: null), isNull);
      expect(
        HostSilence.find(
          status: _reconnecting,
          succession: null,
          participants: const [_andres, _ana],
          localId: 'peer_2',
        ),
        isNull,
      );
      expect(
        _find(
          participants: const [_andres],
          succession: _succession(
            members: [_member('peer_1', 'Andrés', address: '192.168.1.20')],
          ),
        ),
        isNull,
      );
    });

    test('AC4: sin la lista de participantes, el anfitrión es el primero de '
        'la sucesión', () {
      final silence = _find(participants: const []);

      expect(silence!.hostName, 'Andrés');
      expect(silence.successor, 'Ana');
    });
  });

  group('La vista de la espera', () {
    test('AC2: solo el anfitrión queda reconectando; los demás siguen igual '
        'y la frecu se ve conectada', () {
      final silence = _find()!;

      final shown = HostSilence.showParticipants(silence, const [
        _andres,
        _ana,
        _leo,
      ]);

      expect(shown[0].connectionState, PeerConnectionState.reconnecting);
      expect(shown[1], _ana);
      expect(shown[2], _leo);
      expect(
        HostSilence.showStatus(silence, _reconnecting),
        const RoomStatus.connected(),
      );
    });

    test('AC4: sin espera, la frecu se ve como llega', () {
      expect(HostSilence.showParticipants(null, const [_andres, _ana]), const [
        _andres,
        _ana,
      ]);
      expect(HostSilence.showStatus(null, _reconnecting), _reconnecting);
    });
  });

  group('Textos de la espera', () {
    test('AC3: la pista nombra al sucesor, o dice que la tomas tú', () {
      expect(
        _find()!.hint,
        'Siguen hablando · si no vuelve, Ana toma la frecu',
      );
      expect(
        _find(localId: 'peer_2')!.hint,
        'Siguen hablando · si no vuelve, tomas la frecu',
      );
    });

    test('AC1: la isla dice quién no responde y, desde 1 s, cuánto lleva', () {
      final silence = _find()!;

      expect(silence.islandLabel(null), 'Andrés no responde');
      expect(silence.islandLabel(0), 'Andrés no responde');
      expect(silence.islandLabel(3), 'Andrés no responde · 3 s');
    });

    test('AC5: en inglés, sin género ni «router»', () async {
      await LocaleSettings.setLocale(AppLocale.en);
      final silence = _find()!;
      final texts = [
        silence.hint,
        _find(localId: 'peer_2')!.hint,
        silence.islandLabel(3),
      ];

      const still = "Everyone can still talk · if they don't come back,";
      expect(texts, [
        '$still Ana takes the frecu',
        '$still you take the frecu',
        "Andrés isn't responding · 3 s",
      ]);
      for (final text in texts) {
        expect(text.toLowerCase(), isNot(contains('router')));
        expect(text, isNot(matches(RegExp(r'\b(he|she|him|her)\b'))));
      }
    });

    test('AC5: en español, sin «router»', () {
      final silence = _find()!;
      for (final text in [silence.hint, silence.islandLabel(3)]) {
        expect(text.toLowerCase(), isNot(contains('router')));
      }
    });
  });

  group('Providers de la espera', () {
    late _MockRooms rooms;
    late StreamController<RoomStatus> status;
    late StreamController<List<Participant>> participants;

    setUp(() {
      rooms = _MockRooms();
      status = StreamController<RoomStatus>.broadcast();
      participants = StreamController<List<Participant>>.broadcast();
      when(() => rooms.watchStatus()).thenAnswer((_) => status.stream);
      when(() => rooms.watchParticipants())
          .thenAnswer((_) => participants.stream);
      when(() => rooms.localParticipantId).thenReturn('peer_3');
      when(() => rooms.succession).thenReturn(_succession());
      when(() => rooms.watchSuccession())
          .thenAnswer((_) => Stream.value(_succession()));
      when(() => rooms.watchHostChanges())
          .thenAnswer((_) => const Stream.empty());
    });

    tearDown(() async {
      await status.close();
      await participants.close();
    });

    /// Deja pasar los eventos de los streams y los avisos de Riverpod.
    Future<void> flush(WidgetTester tester) async {
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump(const Duration(milliseconds: 1));
    }

    testWidgets('AC1: la espera cuenta los segundos hacia arriba y se va '
        'cuando el anfitrión vuelve (AC4)', (tester) async {
      final container = ProviderContainer(
        overrides: [roomRepositoryProvider.overrideWithValue(rooms)],
      );
      addTearDown(container.dispose);
      final silenceSub = container.listen(hostSilenceProvider, (_, _) {});
      final clockSub = container.listen(hostSilenceClockProvider, (_, _) {});
      addTearDown(silenceSub.close);
      addTearDown(clockSub.close);

      participants.add(const [_andres, _ana, _leo]);
      status.add(const RoomStatus.connected());
      await flush(tester);
      expect(container.read(hostSilenceProvider), isNull);
      expect(container.read(hostSilenceClockProvider), isNull);

      status.add(_reconnecting);
      await flush(tester);
      expect(container.read(hostSilenceProvider)?.hostName, 'Andrés');
      expect(container.read(hostSilenceClockProvider), 0);

      await tester.pump(const Duration(seconds: 1));
      // Otro intento del mismo plan no reinicia la cuenta.
      status.add(
        const RoomStatus.reconnecting(
          retryIn: Duration(seconds: 4),
          attempt: 2,
        ),
      );
      await flush(tester);
      await tester.pump(const Duration(seconds: 2));
      expect(container.read(hostSilenceClockProvider), 3);

      status.add(const RoomStatus.connected());
      await flush(tester);
      expect(container.read(hostSilenceProvider), isNull);
      expect(container.read(hostSilenceClockProvider), isNull);
    });
  });
}
