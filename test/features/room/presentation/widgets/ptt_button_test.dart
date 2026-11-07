// AC1: CUANDO el usuario se encuentra en modo PTT y mantiene presionado el botón de hablar (`onPointerDown`) ENTONCES se activa la transmisión de voz (`startTalking()`) y el botón refleja visualmente el estado de habla hasta que el usuario lo suelta o cancela la pulsación (`onPointerUp`/`onPointerCancel`), silenciando el micrófono (`stopTalking()`).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/features/room/presentation/widgets/ptt_button.dart';

void main() {
  group('PttButton widget', () {
    testWidgets(
      'AC1: PttButton calls onStartTalking on pointer down and onStopTalking on pointer up',
      (tester) async {
        var started = false;
        var stopped = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: PttButton(
                  isTalking: false,
                  onStartTalking: () => started = true,
                  onStopTalking: () => stopped = true,
                ),
              ),
            ),
          ),
        );

        final pttFinder = find.byKey(const Key('ptt_button'));
        expect(pttFinder, findsOneWidget);

        final gesture = await tester.startGesture(tester.getCenter(pttFinder));
        await tester.pump();
        expect(started, isTrue);
        expect(stopped, isFalse);

        await gesture.up();
        await tester.pump();
        expect(stopped, isTrue);
      },
    );

    testWidgets(
      'AC1: PttButton calls onStopTalking when pointer is cancelled',
      (tester) async {
        var started = false;
        var stopped = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: PttButton(
                  isTalking: false,
                  onStartTalking: () => started = true,
                  onStopTalking: () => stopped = true,
                ),
              ),
            ),
          ),
        );

        final pttFinder = find.byKey(const Key('ptt_button'));
        final gesture = await tester.startGesture(tester.getCenter(pttFinder));
        await tester.pump();
        expect(started, isTrue);

        await gesture.cancel();
        await tester.pump();
        expect(stopped, isTrue);
      },
    );

    testWidgets(
      'PttButton reflects visual state when isTalking is true or false',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: PttButton(
                  isTalking: true,
                  onStartTalking: () {},
                  onStopTalking: () {},
                ),
              ),
            ),
          ),
        );

        expect(find.byIcon(Icons.mic), findsOneWidget);
        expect(find.byKey(const Key('ptt_button_active')), findsOneWidget);
      },
    );
  });
}
