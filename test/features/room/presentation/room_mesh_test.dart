// AC1: CUANDO el usuario está en una frecu activa ENTONCES ve la malla de 6 lugares sobre un lienzo de 390 × 304 (centro en (195, 138), radio 104, a 90°, 150°, 210°, 270°, 330° y 30°) con un nodo por participante: su firma de señal (`SignalSignature` de su nombre), su nombre debajo y su papel («Tú», «Tú · anfitrión» o «Anfitrión»); la persona propia está en el lugar 0 con el color de la señal, cada participante conserva su lugar y su color mientras siga y quien llega toma el primer lugar libre; hay una arista entre cada par de nodos y cada lugar vacío muestra un círculo punteado con «+» y «Libre», que al tocarlo abre la invitación QR.
// AC2: CUANDO alguien habla (un participante remoto en `speakingPeers` o con `isSpeaking`, o la persona propia al transmitir) ENTONCES su nodo crece con halo y anillo de su color, su firma ondula con su nivel de voz, su etiqueta dice «Hablando» (o «Al aire» si es la propia) en su color, sus aristas se degradan desde su nodo y salen paquetes de voz hacia cada nodo conectado; CUANDO deja de hablar ENTONCES el nodo vuelve al reposo y los paquetes se acaban.
// AC3: CUANDO la frecu está reconectando ENTONCES todas las aristas son punteadas en ámbar, los anillos son punteados en ámbar, las firmas pasan a «enlazando», las etiquetas dicen «Reconectando» en ámbar y no hay halos ni paquetes aunque alguien hable; CUANDO la frecu está conectando o un participante está conectando ENTONCES su etiqueta dice «Conectando», su firma está enlazando y sus aristas son punteadas; un participante silenciado dice «Silenciado» con la firma aplanada.
// AC4: CUANDO alguien se une ENTONCES su nodo aparece con el resorte del prototipo (escala `1 − e^(−6a)·cos(11a)` entre 0 y 1,25 durante 1,6 s) y sus aristas se funden en 0,7 s; CUANDO el sistema pide reducir el movimiento ENTONCES los nodos aparecen a escala 1 sin resorte, la malla no anima ni lanza paquetes y quien habla se sigue viendo por su halo, su anillo y su etiqueta.
// AC6: CUANDO el usuario está en la frecu activa ENTONCES ... con tema claro, la etiqueta y la firma propias y el texto «Hablando» del micrófono abierto van en `signalFg`, nunca en verde sobre blanco.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/app/theme/app_theme.dart';
import 'package:frecu/core/design/tokens/fr_colors.dart';
import 'package:frecu/core/design/widgets/signal_signature.dart';
import 'package:frecu/features/room/domain/entities/participant.dart';
import 'package:frecu/features/room/domain/entities/room_status.dart';
import 'package:frecu/features/room/presentation/widgets/room_mesh.dart';
import 'package:frecu/features/room/presentation/widgets/room_mesh_scene.dart';
import 'package:frecu/i18n/strings.g.dart';

import 'room_mesh_support.dart';

void reduceMotion(WidgetTester tester) {
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
}

Future<void> pumpMesh(
  WidgetTester tester, {
  required List<Participant> participants,
  String? localId = 'p-1',
  Set<String> speakingPeers = const {},
  bool localTalking = false,
  Map<String, double> levels = const {},
  RoomStatus status = const RoomStatus.connected(),
  VoidCallback? onInvite,
  ThemeData? theme,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: theme ?? AppTheme.dark,
      home: Scaffold(
        body: Center(
          child: RoomMesh(
            participants: participants,
            localParticipantId: localId,
            speakingPeers: speakingPeers,
            localTalking: localTalking,
            levels: levels,
            status: status,
            onInvite: onInvite,
          ),
        ),
      ),
    ),
  );
}

Finder signatureOf(String name) => find.byWidgetPredicate(
  (widget) => widget is SignalSignature && widget.name == name,
);

SignalSignature signature(WidgetTester tester, String name) =>
    tester.widget<SignalSignature>(signatureOf(name));

Offset meshOrigin(WidgetTester tester) =>
    tester.getTopLeft(find.byType(RoomMesh));

Offset slotCenter(WidgetTester tester, int slot) =>
    meshOrigin(tester) + meshSlots(meshCanvas)[slot];

Color? textColor(WidgetTester tester, String text) =>
    tester.widget<Text>(find.text(text)).style?.color;

double silentLevel(WidgetTester tester, String name) =>
    signature(tester, name).levelOf?.call(0) ?? 0;

void main() {
  setUpAll(() {
    LocaleSettings.setLocaleSync(AppLocale.es);
  });

  group('RoomMesh', () {
    testWidgets(
      'AC1: cada participante tiene su firma en su lugar del hexágono, con su '
      'nombre, su papel y su color',
      (tester) async {
        reduceMotion(tester);
        await pumpMesh(tester, participants: const [ana, jorge, leo]);
        await tester.pumpAndSettle();

        expect(find.byType(SignalSignature), findsNWidgets(3));
        expect(
          tester.getCenter(signatureOf('Jorge')),
          offsetMoreOrLessEquals(slotCenter(tester, 0), epsilon: 0.5),
        );
        expect(
          tester.getCenter(signatureOf('Ana')),
          offsetMoreOrLessEquals(slotCenter(tester, 3), epsilon: 0.5),
        );
        expect(
          tester.getCenter(signatureOf('Leo')),
          offsetMoreOrLessEquals(slotCenter(tester, 1), epsilon: 0.5),
        );

        expect(find.text('Jorge'), findsOneWidget);
        expect(find.text('Ana'), findsOneWidget);
        expect(find.text('Leo'), findsOneWidget);
        expect(find.text('TÚ · ANFITRIÓN'), findsOneWidget);
        expect(find.text('LIBRE'), findsNWidgets(3));

        const colors = FrColors.dark;
        expect(signature(tester, 'Jorge').color, colors.signalFg);
        expect(signature(tester, 'Ana').color, colors.p1);
        expect(signature(tester, 'Leo').color, colors.p2);
      },
    );

    testWidgets(
      'AC1: cada uno conserva su lugar y su color y quien llega toma el primer '
      'lugar libre',
      (tester) async {
        reduceMotion(tester);
        await pumpMesh(tester, participants: const [jorge, ana, leo]);
        await tester.pumpAndSettle();

        await pumpMesh(tester, participants: const [jorge, leo]);
        await tester.pumpAndSettle();

        expect(find.text('Ana'), findsNothing);
        expect(find.text('LIBRE'), findsNWidgets(4));
        expect(
          tester.getCenter(signatureOf('Leo')),
          offsetMoreOrLessEquals(slotCenter(tester, 1), epsilon: 0.5),
        );
        expect(signature(tester, 'Leo').color, FrColors.dark.p2);

        await pumpMesh(tester, participants: const [jorge, leo, sofi]);
        await tester.pumpAndSettle();

        expect(
          tester.getCenter(signatureOf('Sofi')),
          offsetMoreOrLessEquals(slotCenter(tester, 3), epsilon: 0.5),
        );
        expect(signature(tester, 'Sofi').color, FrColors.dark.p1);
        expect(
          tester.getCenter(signatureOf('Leo')),
          offsetMoreOrLessEquals(slotCenter(tester, 1), epsilon: 0.5),
        );
      },
    );

    testWidgets(
      'AC1: un lugar libre muestra «LIBRE» y al tocarlo pide la invitación',
      (tester) async {
        reduceMotion(tester);
        var invites = 0;
        await pumpMesh(
          tester,
          participants: const [jorge],
          onInvite: () => invites++,
        );
        await tester.pumpAndSettle();

        expect(find.text('LIBRE'), findsNWidgets(5));
        expect(find.byKey(const Key('mesh_free_slot_0')), findsNothing);
        final freeSlot = find.byKey(const Key('mesh_free_slot_3'));
        expect(freeSlot, findsOneWidget);
        expect(
          tester.getCenter(freeSlot),
          offsetMoreOrLessEquals(slotCenter(tester, 3), epsilon: 0.5),
        );

        await tester.tap(freeSlot);
        await tester.pump();

        expect(invites, 1);
      },
    );

    testWidgets(
      'AC2: quien habla dice «Hablando» en su color y la persona propia «Al '
      'aire», y al callar vuelven al reposo',
      (tester) async {
        reduceMotion(tester);
        await pumpMesh(
          tester,
          participants: const [jorge, ana, leo],
          speakingPeers: const {'p-2'},
          localTalking: true,
          levels: const {'p-2': 0.6, 'p-3': 0.9},
        );
        await tester.pumpAndSettle();

        const colors = FrColors.dark;
        expect(find.text('HABLANDO'), findsOneWidget);
        expect(find.text('AL AIRE'), findsOneWidget);
        expect(textColor(tester, 'HABLANDO'), colors.p1);
        expect(textColor(tester, 'Ana'), colors.p1);
        expect(textColor(tester, 'AL AIRE'), colors.signalFg);
        expect(find.byKey(const Key('speaking_indicator_p-2')), findsOneWidget);
        expect(find.byKey(const Key('speaking_indicator_p-1')), findsOneWidget);
        expect(find.byKey(const Key('speaking_indicator_p-3')), findsNothing);
        expect(signature(tester, 'Ana').levelOf?.call(0), closeTo(0.6, 1e-9));
        expect(silentLevel(tester, 'Leo'), 0);

        await pumpMesh(tester, participants: const [jorge, ana, leo]);
        await tester.pumpAndSettle();

        expect(find.text('HABLANDO'), findsNothing);
        expect(find.text('AL AIRE'), findsNothing);
        expect(find.byKey(const Key('speaking_indicator_p-2')), findsNothing);
        expect(silentLevel(tester, 'Ana'), 0);
      },
    );

    testWidgets('AC2: un participante con isSpeaking también se ve hablando', (
      tester,
    ) async {
      reduceMotion(tester);
      await pumpMesh(
        tester,
        participants: const [
          jorge,
          Participant(id: 'p-2', displayName: 'Ana', isSpeaking: true),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.text('HABLANDO'), findsOneWidget);
      expect(find.byKey(const Key('speaking_indicator_p-2')), findsOneWidget);
    });

    testWidgets(
      'AC3: al reconectar todos dicen «Reconectando» en ámbar, las firmas '
      'enlazan y nadie se ve hablando',
      (tester) async {
        reduceMotion(tester);
        await pumpMesh(
          tester,
          participants: const [jorge, ana],
          speakingPeers: const {'p-2'},
          status: const RoomStatus.reconnecting(),
        );
        await tester.pumpAndSettle();

        final reconnecting = find.text('RECONECTANDO');
        expect(reconnecting, findsNWidgets(2));
        for (final text in tester.widgetList<Text>(reconnecting)) {
          expect(text.style?.color, FrColors.dark.warn);
        }
        expect(find.text('HABLANDO'), findsNothing);
        expect(find.byKey(const Key('speaking_indicator_p-2')), findsNothing);
        expect(signature(tester, 'Jorge').mode, SignatureMode.link);
        expect(signature(tester, 'Ana').mode, SignatureMode.link);
        expect(silentLevel(tester, 'Ana'), 0);
      },
    );

    testWidgets('AC3: conectando dice «Conectando» con la firma enlazando y un '
        'silenciado dice «Silenciado» con la firma aplanada', (tester) async {
      reduceMotion(tester);
      const pepe = Participant(
        id: 'p-3',
        displayName: 'Pepe',
        connectionState: PeerConnectionState.connecting,
      );
      const rita = Participant(id: 'p-4', displayName: 'Rita', isMuted: true);
      await pumpMesh(tester, participants: const [jorge, pepe, rita]);
      await tester.pumpAndSettle();

      expect(find.text('CONECTANDO'), findsOneWidget);
      expect(signature(tester, 'Pepe').mode, SignatureMode.link);
      expect(find.text('SILENCIADO'), findsOneWidget);
      expect(signature(tester, 'Rita').mode, SignatureMode.muted);

      await pumpMesh(
        tester,
        participants: const [jorge, rita],
        status: const RoomStatus.connecting(),
      );
      await tester.pumpAndSettle();

      expect(find.text('CONECTANDO'), findsNWidgets(2));
      expect(signature(tester, 'Jorge').mode, SignatureMode.link);
    });

    testWidgets('AC4: quien se une aparece con el resorte del prototipo', (
      tester,
    ) async {
      await pumpMesh(tester, participants: const [jorge]);
      await tester.pump(const Duration(seconds: 2));

      await pumpMesh(tester, participants: const [jorge, ana]);
      double width() => tester.getRect(signatureOf('Ana')).width;

      expect(width(), lessThan(20));

      await tester.pump(const Duration(milliseconds: 300));
      expect(width(), greaterThan(41));
      expect(width(), lessThanOrEqualTo(50));

      await tester.pump(const Duration(seconds: 2));
      expect(width(), closeTo(40, 0.01));
      expect(tester.getRect(signatureOf('Jorge')).width, closeTo(40, 0.01));
    });

    testWidgets(
      'AC4: con movimiento reducido quien se une aparece a escala 1 sin '
      'resorte y quien habla se sigue viendo',
      (tester) async {
        reduceMotion(tester);
        await pumpMesh(tester, participants: const [jorge]);
        await tester.pumpAndSettle();

        await pumpMesh(
          tester,
          participants: const [jorge, ana],
          speakingPeers: const {'p-2'},
          levels: const {'p-2': 0.6},
        );
        expect(tester.getRect(signatureOf('Ana')).width, closeTo(40, 0.01));

        await tester.pumpAndSettle();
        expect(tester.getRect(signatureOf('Ana')).width, closeTo(40, 0.01));
        expect(find.text('HABLANDO'), findsOneWidget);
        expect(signature(tester, 'Ana').levelOf?.call(0), closeTo(0.6, 1e-9));
      },
    );

    testWidgets(
      'AC6: de día la etiqueta y la firma propias van en signalFg, nunca en '
      'verde',
      (tester) async {
        reduceMotion(tester);
        await pumpMesh(
          tester,
          participants: const [jorge, ana],
          localTalking: true,
          theme: AppTheme.light,
        );
        await tester.pumpAndSettle();

        const colors = FrColors.light;
        expect(signature(tester, 'Jorge').color, colors.signalFg);
        expect(signature(tester, 'Jorge').color, isNot(colors.signal));
        expect(textColor(tester, 'AL AIRE'), colors.signalFg);
        expect(textColor(tester, 'Jorge'), colors.signalFg);
      },
    );
  });
}
