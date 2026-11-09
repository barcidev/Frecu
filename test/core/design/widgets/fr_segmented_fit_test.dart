// P134: CUANDO un `FrSegmented` se muestra en un teléfono de 390 px con las fuentes de la app ENTONCES ninguna etiqueta se corta: «OSCURO» cabe entero en el selector de tema de Ajustes (196 px, `.v-settings .row .seg`) y «ABIERTO», con su ícono, en el selector de modo de la frecu (`.ctrls .seg`, junto a la pastilla de audio); si una etiqueta no cabe, se achica en vez de cortarse.
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/app/theme/app_theme.dart';
import 'package:frecu/core/design/icons/fr_icon.dart';
import 'package:frecu/core/design/icons/fr_icons.dart';
import 'package:frecu/core/design/widgets/fr_segmented.dart';
import 'package:frecu/i18n/strings.g.dart';

/// Ancho de la pastilla de audio a 390 px, medido con las fuentes de la app:
/// «Altavoz» (la ruta por defecto) y «Bluetooth» (la más ancha).
const double _speakerPill = 149;
const double _bluetoothPill = 165;

bool _fontsLoaded = false;

/// Carga Martian Mono y Archivo: con la fuente de prueba cada letra mide un
/// em y las medidas no se parecen a las del teléfono.
Future<void> _loadFonts(WidgetTester tester) async {
  if (_fontsLoaded) return;
  await tester.runAsync(() async {
    for (final (family, asset) in [
      ('Martian Mono', 'assets/fonts/martianmono/MartianMono.ttf'),
      ('Archivo', 'assets/fonts/archivo/Archivo.ttf'),
    ]) {
      await (FontLoader(family)..addFont(rootBundle.load(asset))).load();
    }
  });
  _fontsLoaded = true;
}

Future<void> _pumpPhone(WidgetTester tester, Widget child) async {
  await _loadFonts(tester);
  tester.view
    ..physicalSize = const Size(1170, 2532)
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(body: Center(child: child)),
    ),
  );
}

/// La etiqueta [label] se ve entera dentro de su segmento [index], achicada
/// como mucho hasta [minScale] (1: tal cual).
void expectWhole(
  WidgetTester tester,
  String label,
  int index, {
  double minScale = 1,
}) {
  final text = find.text(label);
  expect(text, findsOneWidget, reason: label);
  final paragraph = tester.renderObject<RenderParagraph>(text);
  expect(paragraph.didExceedMaxLines, isFalse, reason: label);
  expect(paragraph.text.toPlainText(), label);
  final shown = tester.getRect(text);
  final laid = tester.getSize(text);
  expect(
    laid.width,
    closeTo(paragraph.getMaxIntrinsicWidth(double.infinity), 0.01),
    reason: '$label se dibuja con su ancho completo',
  );
  final scale = shown.width / laid.width;
  expect(scale, lessThanOrEqualTo(1.0001), reason: label);
  expect(scale, greaterThanOrEqualTo(minScale), reason: label);
  final segment = tester.getRect(find.byKey(ValueKey('fr-segment-$index')));
  expect(segment.contains(shown.topLeft), isTrue, reason: label);
  expect(segment.contains(shown.bottomRight), isTrue, reason: label);
}

/// Selector de tema de Ajustes: 196 px a la derecha de su fila, de [height]
/// px de alto.
Widget _themeSelector({double height = 48}) => Align(
  alignment: Alignment.centerRight,
  child: Padding(
    padding: const EdgeInsets.only(right: 36),
    child: SizedBox(
      width: 196,
      child: FrSegmented<int>(
        value: 0,
        onChanged: (_) {},
        height: height,
        segments: [
          FrSegment(value: 0, label: t.settings.themeMode.auto),
          FrSegment(value: 1, label: t.settings.themeMode.light),
          FrSegment(value: 2, label: t.settings.themeMode.dark),
        ],
      ),
    ),
  ),
);

/// Fila de controles de la frecu (`.ctrls`): la pastilla de audio de
/// [pill] px y el selector de modo, de hasta 204 px, con 20 px a los lados.
Widget _modeRow(double pill) => Padding(
  padding: const EdgeInsets.symmetric(horizontal: 20),
  child: SizedBox(
    height: 52,
    child: Row(
      children: [
        SizedBox(width: pill, height: 48),
        const SizedBox(width: 10),
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 204),
              child: FrSegmented<int>(
                value: 0,
                onChanged: (_) {},
                segments: [
                  FrSegment(
                    value: 0,
                    label: t.room.talk.modePtt,
                    icon: const FrIcon(FrIcons.walkie),
                  ),
                  FrSegment(
                    value: 1,
                    label: t.room.talk.modeOpen,
                    icon: const FrIcon(FrIcons.openMic),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  ),
);

void main() {
  for (final locale in [AppLocale.es, AppLocale.en]) {
    group('FrSegmented a 390 px (${locale.languageCode})', () {
      tearDown(() => LocaleSettings.setLocaleSync(AppLocale.es));

      testWidgets('P134: el tema de Ajustes muestra Oscuro entero', (
        tester,
      ) async {
        await tester.runAsync(() => LocaleSettings.setLocale(locale));
        await _pumpPhone(tester, _themeSelector());

        expectWhole(tester, t.settings.themeMode.auto.toUpperCase(), 0);
        expectWhole(tester, t.settings.themeMode.light.toUpperCase(), 1);
        expectWhole(tester, t.settings.themeMode.dark.toUpperCase(), 2);

        // Con el alto de las filas de Ajustes (40 px) tampoco se corta.
        await _pumpPhone(tester, _themeSelector(height: 40));
        expect(tester.getSize(find.byType(FrSegmented<int>)).height, 40);
        expectWhole(tester, t.settings.themeMode.dark.toUpperCase(), 2);
      });

      testWidgets(
        'P134: el modo de la frecu muestra Abierto entero junto a Altavoz',
        (tester) async {
          await tester.runAsync(() => LocaleSettings.setLocale(locale));
          await _pumpPhone(tester, _modeRow(_speakerPill));

          expectWhole(tester, t.room.talk.modePtt.toUpperCase(), 0);
          expectWhole(tester, t.room.talk.modeOpen.toUpperCase(), 1);
        },
      );

      testWidgets(
        'P134: con la pastilla más ancha Abierto se achica sin cortarse',
        (tester) async {
          await tester.runAsync(() => LocaleSettings.setLocale(locale));
          await _pumpPhone(tester, _modeRow(_bluetoothPill));

          expectWhole(
            tester,
            t.room.talk.modeOpen.toUpperCase(),
            1,
            minScale: 0.9,
          );
        },
      );
    });
  }
}
