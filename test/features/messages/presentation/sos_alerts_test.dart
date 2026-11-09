// SOS (corte 3 de la épica de hardware V1): CUANDO llega un SOS ENTONCES
// queda pendiente (uno por persona) y vibra con el patrón de SOS; mientras
// siga pendiente, recordar vuelve a vibrar. CUANDO se atiende ENTONCES deja
// de estar pendiente y, con «Voy en camino», se responde a toda la frecu.
// La hoja de mensajes devuelve el mensaje elegido y el SOS solo se elige
// manteniéndolo pulsado.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/app/theme/app_theme.dart';
import 'package:frecu/core/haptics/haptics.dart';
import 'package:frecu/core/result/result.dart';
import 'package:frecu/features/messages/domain/entities/quick_message.dart';
import 'package:frecu/features/messages/domain/repositories/messages_repository.dart';
import 'package:frecu/features/messages/presentation/providers/messages_provider.dart';
import 'package:frecu/features/messages/presentation/widgets/quick_message_sheet.dart';
import 'package:frecu/features/settings/presentation/providers/vibration_provider.dart';
import 'package:frecu/i18n/strings.g.dart';

class _FakeMessages implements MessagesRepository {
  final StreamController<QuickMessage> incoming =
      StreamController<QuickMessage>.broadcast();
  final List<QuickMessageKind> sent = [];

  @override
  Stream<QuickMessage> watchIncoming() => incoming.stream;

  @override
  Future<Result<void>> send(QuickMessageKind kind) async {
    sent.add(kind);
    return const Result.success(null);
  }
}

const _sosFromAna = QuickMessage(senderId: 'ana', kind: QuickMessageKind.sos);

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.es));

  group('SosAlerts', () {
    late _FakeMessages messages;
    late List<String> vibrated;
    late ProviderContainer container;

    setUp(() {
      messages = _FakeMessages();
      vibrated = [];
      container = ProviderContainer(
        overrides: [
          messagesRepositoryProvider.overrideWithValue(messages),
          hapticsProvider.overrideWithValue(
            Haptics(invoke: (_, pattern) async => vibrated.add('$pattern')),
          ),
        ],
      )..listen(sosAlertsProvider, (_, _) {});
    });

    tearDown(() async {
      container.dispose();
      await messages.incoming.close();
    });

    test('guarda un SOS por persona, vibra y recuerda', () async {
      messages.incoming
        ..add(_sosFromAna)
        ..add(_sosFromAna)
        ..add(const QuickMessage(senderId: 'leo', kind: QuickMessageKind.ok));
      await Future<void>.delayed(Duration.zero);

      expect(container.read(sosAlertsProvider), [_sosFromAna]);
      expect(vibrated, ['sos']);

      container.read(sosAlertsProvider.notifier).remind();
      expect(vibrated, ['sos', 'sos']);
    });

    test('«Voy en camino» lo atiende y responde a la frecu', () async {
      messages.incoming.add(_sosFromAna);
      await Future<void>.delayed(Duration.zero);

      await container
          .read(sosAlertsProvider.notifier)
          .dismiss('ana', onMyWay: true);

      expect(container.read(sosAlertsProvider), isEmpty);
      expect(messages.sent, [QuickMessageKind.onMyWay]);
      container.read(sosAlertsProvider.notifier).remind();
      expect(vibrated, ['sos']);
    });

    test('«Entendido» lo atiende sin responder', () async {
      messages.incoming.add(_sosFromAna);
      await Future<void>.delayed(Duration.zero);

      await container.read(sosAlertsProvider.notifier).dismiss('ana');

      expect(container.read(sosAlertsProvider), isEmpty);
      expect(messages.sent, isEmpty);
    });
  });

  group('QuickMessageSheet', () {
    /// Abre la hoja y devuelve cómo leer lo elegido (sin esperarlo: un
    /// `Future` devuelto desde una función `async` se esperaría).
    Future<Future<QuickMessageKind?> Function()> open(
      WidgetTester tester,
    ) async {
      late Future<QuickMessageKind?> result;
      await tester.pumpWidget(
        ProviderScope(
          child: TranslationProvider(
            child: MaterialApp(
              theme: AppTheme.dark,
              home: Builder(
                builder: (context) => GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => result = QuickMessageSheet.show(context),
                  child: const SizedBox.expand(key: Key('opener')),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('opener')));
      await tester.pumpAndSettle();
      return () => result;
    }

    testWidgets('devuelve el mensaje que se toca', (tester) async {
      final result = await open(tester);
      expect(find.text('Parada en la próxima'), findsOneWidget);

      await tester.tap(find.byKey(const Key('quick_message_stop')));
      await tester.pumpAndSettle();

      expect(await result(), QuickMessageKind.stop);
    });

    testWidgets('el SOS solo sale si se mantiene pulsado', (tester) async {
      final result = await open(tester);
      final sos = find.byKey(const Key('sos_hold_button'));
      await tester.ensureVisible(sos);
      await tester.pumpAndSettle();

      // Un toque corto no envía.
      await tester.tap(sos);
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byType(QuickMessageSheet), findsOneWidget);

      final gesture = await tester.startGesture(tester.getCenter(sos));
      // El relleno empieza a contar en el primer cuadro.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.byType(QuickMessageSheet), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 700));
      await gesture.up();
      await tester.pumpAndSettle();

      expect(find.byType(QuickMessageSheet), findsNothing);
      expect(await result(), QuickMessageKind.sos);
    });
  });
}
