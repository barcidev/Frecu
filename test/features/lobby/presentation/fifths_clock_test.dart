// AC7: CUANDO se dibuja el reloj de quintas ENTONCES sus 12 notas van cada 30° desde las 12 en el orden del círculo de quintas (Do, Sol, Re, La, Mi, Si, Fa♯, Re♭, La♭, Mi♭, Si♭, Fa; C, G, D… en inglés), la aguja de la hora apunta a (hora mod 12 + minutos/60) · 30° y la de los minutos a minutos · 6°, en sentido horario desde las 12, y se enciende la posición de la nota recibida.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/app/theme/app_theme.dart';
import 'package:frecu/features/lobby/presentation/widgets/fifths_clock.dart';
import 'package:frecu/features/room/domain/entities/room_note.dart';
import 'package:frecu/i18n/strings.g.dart';

/// 30° en radianes.
const double _hourStep = math.pi / 6;

/// Las 12 en punto: arriba.
const double _top = -math.pi / 2;

FifthsClockPainter _painter(WidgetTester tester) {
  final paint = tester.widget<CustomPaint>(
    find.descendant(
      of: find.byType(FifthsClock),
      matching: find.byType(CustomPaint),
    ),
  );
  return paint.painter! as FifthsClockPainter;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => LocaleSettings.setLocaleSync(AppLocale.es));

  Future<void> pumpClock(
    WidgetTester tester, {
    required int hour,
    required int minute,
    required RoomNote note,
    ThemeData? theme,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: theme ?? AppTheme.dark,
        home: Center(
          child: FifthsClock(hour: hour, minute: minute, note: note),
        ),
      ),
    );
  }

  group('Reloj de quintas', () {
    test('AC7: las 12 notas van en el orden del círculo de quintas', () {
      expect(fifthsLabels(t.lobby.noteNames), [
        'Do',
        'Sol',
        'Re',
        'La',
        'Mi',
        'Si',
        'Fa♯',
        'Re♭',
        'La♭',
        'Mi♭',
        'Si♭',
        'Fa',
      ]);
    });

    testWidgets('AC7: en inglés las notas del reloj son C, G, D…', (
      tester,
    ) async {
      await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.en));
      addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.es));

      expect(fifthsLabels(t.lobby.noteNames), [
        'C',
        'G',
        'D',
        'A',
        'E',
        'B',
        'F♯',
        'D♭',
        'A♭',
        'E♭',
        'B♭',
        'F',
      ]);
    });

    test('AC7: cada posición va 30° más allá en sentido horario desde las '
        '12', () {
      expect(fifthsAngle(0), closeTo(_top, 1e-9));
      expect(fifthsAngle(3), closeTo(0, 1e-9));
      expect(fifthsAngle(6), closeTo(math.pi / 2, 1e-9));
      for (var position = 0; position < 12; position++) {
        expect(
          fifthsAngle(position.toDouble()),
          closeTo(_top + position * _hourStep, 1e-9),
        );
      }
    });

    test('AC7: la aguja de la hora apunta a (hora mod 12 + minutos/60) · '
        '30°', () {
      expect(fifthsHourAngle(0, 0), closeTo(_top, 1e-9));
      expect(fifthsHourAngle(12, 0), closeTo(_top, 1e-9));
      expect(fifthsHourAngle(16, 24), closeTo(_top + 4.4 * _hourStep, 1e-9));
      expect(fifthsHourAngle(4, 24), closeTo(fifthsHourAngle(16, 24), 1e-9));
      expect(fifthsHourAngle(23, 30), closeTo(_top + 11.5 * _hourStep, 1e-9));
    });

    test('AC7: la aguja de los minutos apunta a minutos · 6°', () {
      expect(fifthsMinuteAngle(0), closeTo(_top, 1e-9));
      expect(fifthsMinuteAngle(15), closeTo(0, 1e-9));
      expect(fifthsMinuteAngle(24), closeTo(_top + 24 * math.pi / 30, 1e-9));
      expect(fifthsMinuteAngle(45), closeTo(math.pi, 1e-9));
    });

    testWidgets('AC7: el reloj recibe la hora y enciende la posición de la '
        'nota', (tester) async {
      // 16:24: la hora señala Mi y la frecu suena en Mi5.
      await pumpClock(
        tester,
        hour: 16,
        minute: 24,
        note: const RoomNote(semitone: 16),
      );

      final painter = _painter(tester);
      expect(painter.hour, 16);
      expect(painter.minute, 24);
      expect(painter.position, 4);
      expect(painter.labels[painter.position], 'Mi');
      expect(
        find.bySemanticsLabel('Reloj de quintas: 16:24, Mi5'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('AC7: si la nota avanzó a otra quinta, se enciende la suya '
        'y la aguja sigue en la hora', (tester) async {
      // A las 16:24 Mi5 estaba ocupada: la frecu suena en Si5.
      await pumpClock(
        tester,
        hour: 16,
        minute: 24,
        note: const RoomNote(semitone: 23),
        theme: AppTheme.light,
      );

      final painter = _painter(tester);
      expect(painter.position, 5);
      expect(painter.labels[painter.position], 'Si');
      expect(painter.hour, 16);
      expect(
        find.bySemanticsLabel('Reloj de quintas: 16:24, Si5'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  });
}
