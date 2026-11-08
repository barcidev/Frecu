// P109: CUANDO se confirma una acción destructiva ENTONCES `FrButton` tiene la variante `dangerSolid` (`.btn-danger-solid`): relleno de alerta, texto #1A0503, brillo blanco al 40 % en el canto superior y sombra de alerta.
// P135: CUANDO se muestran los componentes de Portadora ENTONCES siguen los detalles del prototipo: el botón pequeño tiene radio 14; el título de `FrSheet` es de 22 px con peso 680 y su mensaje de 14 px; el botón secundario, el campo, las teclas, las celdas del PIN, el pulgar del segmentado y el botón de ícono llevan el filo especular de 1 px arriba (y no las variantes encendidas, fantasma ni de función); el grano es blanco al 4,5 % fundido en `overlay`; el tema no dibuja la tinta de Material al tocar; y el teclado borra con `FrIcons.backspace`.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/app/theme/app_theme.dart';
import 'package:frecu/core/design/fr_theme.dart';
import 'package:frecu/core/design/icons/fr_icon.dart';
import 'package:frecu/core/design/icons/fr_icons.dart';
import 'package:frecu/core/design/tokens/fr_colors.dart';
import 'package:frecu/core/design/widgets/fr_button.dart';
import 'package:frecu/core/design/widgets/fr_icon_button.dart';
import 'package:frecu/core/design/widgets/fr_keypad.dart';
import 'package:frecu/core/design/widgets/fr_pin_field.dart';
import 'package:frecu/core/design/widgets/fr_scaffold.dart';
import 'package:frecu/core/design/widgets/fr_segmented.dart';
import 'package:frecu/core/design/widgets/fr_sheet.dart';
import 'package:frecu/core/design/widgets/fr_specular.dart';

const _dark = FrColors.dark;

Future<void> pumpHost(WidgetTester tester, Widget child) async {
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(
        body: Center(child: SizedBox(width: 360, child: child)),
      ),
    ),
  );
  await tester.pump();
}

/// Pintores del filo especular dentro de [finder] (los del contenido y los
/// que van delante).
List<FrSpecularPainter> specularIn(WidgetTester tester, Finder finder) => [
  for (final paint in tester.widgetList<CustomPaint>(
    find.descendant(
      of: finder,
      matching: find.byType(CustomPaint),
      matchRoot: true,
    ),
  )) ...[
    if (paint.painter case final FrSpecularPainter painter) painter,
    if (paint.foregroundPainter case final FrSpecularPainter painter) painter,
  ],
];

ShapeDecoration buttonDecoration(WidgetTester tester, Finder button) =>
    tester
            .widget<DecoratedBox>(
              find
                  .descendant(of: button, matching: find.byType(DecoratedBox))
                  .first,
            )
            .decoration
        as ShapeDecoration;

void main() {
  group('FrButton', () {
    testWidgets('P109: dangerSolid rellena de alerta con tinta #1A0503', (
      tester,
    ) async {
      await pumpHost(
        tester,
        FrButton(
          label: 'Cerrar frecu',
          onPressed: () {},
          variant: FrButtonVariant.dangerSolid,
          expand: true,
        ),
      );

      final button = find.byType(FrButton);
      final decoration = buttonDecoration(tester, button);
      expect(decoration.color, _dark.alert);
      expect(decoration.shadows, hasLength(1));
      expect(
        decoration.shadows!.single.color,
        _dark.alert.withValues(alpha: 0.7),
      );
      expect(decoration.shadows!.single.offset, const Offset(0, 10));
      final label = tester.widget<Text>(find.text('Cerrar frecu'));
      expect(label.style?.color, const Color(0xFF1A0503));
      final edges = specularIn(tester, button);
      expect(
        edges.single.color,
        const Color(0xFFFFFFFF).withValues(alpha: 0.4),
      );
      expect(edges.single.depth, 1);
    });

    testWidgets('P135: el pequeño tiene radio 14 y el normal 18', (
      tester,
    ) async {
      BorderRadiusGeometry radiusOf(FrButtonSize size) {
        final shape =
            buttonDecoration(tester, find.byType(FrButton)).shape
                as RoundedSuperellipseBorder;
        return shape.borderRadius;
      }

      await pumpHost(
        tester,
        FrButton(label: 'Unirme', onPressed: () {}, size: FrButtonSize.small),
      );
      expect(radiusOf(FrButtonSize.small), BorderRadius.circular(14));

      await pumpHost(tester, FrButton(label: 'Unirme', onPressed: () {}));
      expect(radiusOf(FrButtonSize.regular), BorderRadius.circular(18));
    });

    testWidgets('P135: el secundario lleva el filo especular y el principal '
        'su brillo y su canto inferior', (tester) async {
      await pumpHost(
        tester,
        FrButton(
          label: 'Escanear',
          onPressed: () {},
          variant: FrButtonVariant.secondary,
        ),
      );
      expect(
        specularIn(tester, find.byType(FrButton)).single.color,
        _dark.spec,
      );

      await pumpHost(tester, FrButton(label: 'Crear', onPressed: () {}));
      final edges = specularIn(tester, find.byType(FrButton));
      expect(edges.map((edge) => (edge.color, edge.depth)), [
        (const Color(0xFFFFFFFF).withValues(alpha: 0.6), 1.0),
        (const Color(0xFF000000).withValues(alpha: 0.14), -2.0),
      ]);

      await pumpHost(
        tester,
        FrButton(
          label: 'Conectar por IP',
          onPressed: () {},
          variant: FrButtonVariant.ghost,
        ),
      );
      expect(specularIn(tester, find.byType(FrButton)), isEmpty);
    });
  });

  group('Filo especular', () {
    test('P135: pinta una línea de 1 px en el canto superior', () {
      final painter = FrSpecularPainter(
        shape: RoundedSuperellipseBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: _dark.spec,
      );
      expect(
        (Canvas canvas) => painter.paint(canvas, const Size(100, 48)),
        paints..path(
          color: _dark.spec,
          includes: const [Offset(50, 0.5)],
          excludes: const [Offset(50, 1.5), Offset(50, 24), Offset(50, 47.5)],
        ),
      );
    });

    testWidgets('P135: botón de ícono, teclas, PIN y pulgar lo llevan', (
      tester,
    ) async {
      await pumpHost(
        tester,
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FrIconButton.drawn(
              key: const Key('filled'),
              icon: FrIcons.qr,
              semanticLabel: 'Invitar',
              onPressed: () {},
            ),
            FrIconButton.drawn(
              key: const Key('ghost'),
              icon: FrIcons.back,
              semanticLabel: 'Atrás',
              variant: FrIconButtonVariant.ghost,
              onPressed: () {},
            ),
            FrIconButton.drawn(
              key: const Key('on'),
              icon: FrIcons.flash,
              semanticLabel: 'Linterna',
              selected: true,
              onPressed: () {},
            ),
            FrKeypad(onDigit: (_) {}, onDelete: () {}, deleteLabel: 'Borrar'),
            const FrPinField(key: Key('pin'), value: '4'),
            FrSegmented<int>(
              value: 0,
              onChanged: (_) {},
              segments: const [
                FrSegment(value: 0, label: 'Auto'),
                FrSegment(value: 1, label: 'Claro'),
              ],
            ),
          ],
        ),
      );

      expect(specularIn(tester, find.byKey(const Key('filled'))), hasLength(1));
      expect(specularIn(tester, find.byKey(const Key('ghost'))), isEmpty);
      expect(specularIn(tester, find.byKey(const Key('on'))), isEmpty);

      Finder key(String id) => find.ancestor(
        of: find.byKey(ValueKey('fr-key-$id')),
        matching: find.byType(CustomPaint),
      );
      expect(
        tester.widget<CustomPaint>(key('5').first).foregroundPainter,
        isA<FrSpecularPainter>(),
      );
      expect(
        tester.widget<CustomPaint>(key('del').first).foregroundPainter,
        isNull,
      );

      // Celda escrita: con filo; la del cursor, sin él.
      Object? pinEdge(int index) => tester
          .widget<CustomPaint>(
            find
                .ancestor(
                  of: find.byKey(ValueKey('fr-pin-cell-$index')),
                  matching: find.byType(CustomPaint),
                )
                .first,
          )
          .foregroundPainter;
      expect(pinEdge(0), isA<FrSpecularPainter>());
      expect(pinEdge(1), isNull);

      final thumb = find.byKey(const ValueKey('fr-segmented-thumb'));
      expect(specularIn(tester, thumb).single.color, _dark.spec);
    });
  });

  group('Detalles', () {
    testWidgets('P135: el título de la hoja es 22/680 y su mensaje de 14', (
      tester,
    ) async {
      await pumpHost(
        tester,
        const FrSheet(title: 'Invitar', message: 'Escanea para unirte'),
      );

      final title = tester.widget<Text>(find.text('Invitar')).style!;
      expect(title.fontSize, 22);
      expect(title.fontWeight, const FontWeight(680));
      expect(title.height, 1.15);
      expect(title.fontVariations, contains(const FontVariation.weight(680)));
      final message = tester.widget<Text>(find.text('Escanea para unirte'));
      expect(message.style!.fontSize, 14);
      expect(message.style!.color, _dark.tx2);
      final fr = FrTheme.of(tester.element(find.text('Invitar')));
      expect(FrSheet.titleStyle(fr), title);
    });

    testWidgets('P135: el teclado borra con FrIcons.backspace', (tester) async {
      await pumpHost(
        tester,
        FrKeypad(onDigit: (_) {}, onDelete: () {}, deleteLabel: 'Borrar'),
      );

      final icon = tester.widget<FrIcon>(
        find.descendant(
          of: find.byKey(const ValueKey('fr-key-del')),
          matching: find.byType(FrIcon),
        ),
      );
      expect(icon.icon, FrIcons.backspace);
      expect(find.byType(Icon), findsNothing);
    });

    testWidgets('P135: el grano es blanco al 4,5 % fundido en overlay', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const FrScaffold(body: SizedBox()),
        ),
      );

      expect(FrBackdrop.grainOpacity, 0.045);
      expect(
        find.byType(FrBackdrop),
        paints
          ..rect(color: FrColors.light.bg0)
          ..something(
            (method, arguments) =>
                method == #drawRect &&
                (arguments[1] as Paint).shader != null &&
                (arguments[1] as Paint).blendMode == BlendMode.overlay &&
                (arguments[1] as Paint).colorFilter ==
                    const ColorFilter.mode(
                      Color.fromRGBO(255, 255, 255, 0.045),
                      BlendMode.modulate,
                    ),
          ),
      );
    });

    test('P135: el tema no dibuja la tinta de Material al tocar', () {
      expect(AppTheme.dark.splashFactory, NoSplash.splashFactory);
      expect(AppTheme.light.splashFactory, NoSplash.splashFactory);
    });
  });
}
