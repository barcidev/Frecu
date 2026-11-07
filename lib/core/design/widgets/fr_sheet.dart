import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:frecu/core/design/fr_theme.dart';
import 'package:frecu/core/design/motion/fr_transitions.dart';
import 'package:frecu/core/design/motion/reduced_motion.dart';
import 'package:frecu/core/design/tokens/fr_colors.dart';
import 'package:frecu/core/design/tokens/fr_motion.dart';

/// Hoja de Portadora para tareas cortas (código, invitar, audio, salir):
/// asa, título, mensaje y contenido sobre el degradado de las hojas.
///
/// Se muestra con [showFrSheet] o [FrSheetRoute].
class FrSheet extends StatelessWidget {
  /// Crea una hoja.
  const FrSheet({
    this.title,
    this.message,
    this.trailing,
    this.children = const <Widget>[],
    super.key,
  });

  /// Título.
  final String? title;

  /// Mensaje bajo el título.
  final String? message;

  /// Acción a la derecha del título (p. ej. cerrar).
  final Widget? trailing;

  /// Contenido, separado por 18 px.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final fr = context.fr;
    final c = fr.colors;
    final radius = fr.radii.sheet;
    final hasHeader = title != null || message != null || trailing != null;
    return DecoratedBox(
      decoration: _decoration(c, radius),
      child: Stack(
        children: [
          // Filo especular arriba.
          Positioned(
            top: 1,
            left: radius * 0.6,
            right: radius * 0.6,
            height: 1,
            child: ColoredBox(color: c.spec),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 22),
            child: DefaultTextStyle(
              style: fr.type.body.copyWith(color: c.tx1),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _Grab(),
                  if (hasHeader) ...[
                    const SizedBox(height: 18),
                    _SheetHeader(
                      title: title,
                      message: message,
                      trailing: trailing,
                    ),
                  ],
                  for (final child in children) ...[
                    const SizedBox(height: 18),
                    child,
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  ShapeDecoration _decoration(FrColors c, double radius) => ShapeDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [c.sheetA, c.sheetB],
      stops: const [0, 0.3],
    ),
    shape: RoundedSuperellipseBorder(
      borderRadius: BorderRadius.circular(radius),
      side: BorderSide(color: c.line2),
    ),
    shadows: [
      BoxShadow(
        color: c.shadow,
        offset: const Offset(0, 18),
        blurRadius: 40,
        spreadRadius: -16,
      ),
    ],
  );
}

/// Asa de 38 × 5 px.
class _Grab extends StatelessWidget {
  const _Grab();

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: SizedBox(
        width: 38,
        height: 5,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: context.fr.colors.bg4,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    ),
  );
}

/// Título, mensaje y acción de la hoja.
class _SheetHeader extends StatelessWidget {
  const _SheetHeader({this.title, this.message, this.trailing});

  final String? title;
  final String? message;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final fr = context.fr;
    final title = this.title;
    final message = this.message;
    final trailing = this.trailing;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title != null)
                Text(
                  title,
                  style: fr.type.titleL.copyWith(color: fr.colors.tx1),
                ),
              if (title != null && message != null) const SizedBox(height: 6),
              if (message != null)
                Text(
                  message,
                  style: fr.type.body.copyWith(color: fr.colors.tx2),
                ),
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 12), trailing],
      ],
    );
  }
}

/// Ruta de una hoja elástica: el velo `scrim` desenfoca el fondo, la hoja
/// sube con el resorte `flow` y la pantalla de abajo se aleja
/// ([FrTransitions.recede]). Tocar el velo o volver la cierra en 400 ms.
///
/// Con movimiento reducido el velo y la hoja se funden en su lugar en
/// [FrTransitions.reducedDuration] y la pantalla de abajo no se mueve.
class FrSheetRoute<T> extends PopupRoute<T> {
  /// Crea la ruta de la hoja que construye [builder].
  FrSheetRoute({required this.builder, this.barrierLabel, super.settings});

  /// Construye la hoja, normalmente un [FrSheet].
  final WidgetBuilder builder;

  /// Etiqueta accesible del velo, que cierra la hoja al tocarlo.
  @override
  final String? barrierLabel;

  /// Entrada nominal; la hoja sube con un resorte.
  static const Duration openDuration = Duration(milliseconds: 640);

  /// Salida: baja acelerando.
  static const Duration closeDuration = Duration(milliseconds: 400);

  static const Curve _closeCurve = Cubic(0.4, 0, 1, 1);

  bool _reduce = false;

  @override
  Color? get barrierColor => null;

  @override
  bool get barrierDismissible => true;

  @override
  Duration get transitionDuration =>
      _reduce ? FrTransitions.reducedDuration : openDuration;

  @override
  Duration get reverseTransitionDuration =>
      _reduce ? FrTransitions.reducedDuration : closeDuration;

  @override
  DelegatedTransitionBuilder? get delegatedTransition => FrTransitions.recede;

  @override
  void install() {
    final context = navigator?.context;
    _reduce =
        context
            ?.getInheritedWidgetOfExactType<MediaQuery>()
            ?.data
            .disableAnimations ??
        false;
    super.install();
  }

  /// Con movimiento reducido el sistema acorta las animaciones normales; el
  /// fundido conserva sus 280 ms.
  @override
  AnimationController createAnimationController() => AnimationController(
    duration: transitionDuration,
    reverseDuration: reverseTransitionDuration,
    debugLabel: debugLabel,
    vsync: navigator!,
    animationBehavior: AnimationBehavior.preserve,
  );

  @override
  Simulation? createSimulation({required bool forward}) {
    if (!forward || _reduce) return null;
    return SpringSimulation(
      FrMotion.standard.springFlow,
      controller?.value ?? 0,
      1,
      0,
    );
  }

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) => Material(type: MaterialType.transparency, child: builder(context));

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final media = MediaQuery.of(context);
    final padding = EdgeInsets.fromLTRB(
      8,
      media.padding.top + 8,
      8,
      8 + media.viewPadding.bottom + media.viewInsets.bottom,
    );
    if (context.reduceMotion) {
      return FadeTransition(opacity: animation, child: _layout(padding, child));
    }
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, sheet) {
        final closing = animation.status == AnimationStatus.reverse;
        final value = animation.value;
        final shown = closing ? _closeCurve.flipped.transform(value) : value;
        final veil = closing
            ? const Interval(0.3, 1).transform(value)
            : const Interval(0, 0.5).transform(value);
        return _layout(padding, sheet!, veil: veil, shift: 1.05 * (1 - shown));
      },
    );
  }

  /// Velo detrás y hoja abajo, corrida [shift] veces su alto.
  Widget _layout(
    EdgeInsets padding,
    Widget sheet, {
    double veil = 1,
    double shift = 0,
  }) => Stack(
    fit: StackFit.expand,
    children: [
      Opacity(opacity: veil, child: const _Scrim()),
      Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: padding,
          child: FractionalTranslation(
            translation: Offset(0, shift),
            child: sheet,
          ),
        ),
      ),
    ],
  );
}

/// Velo `scrim` que desenfoca 6 px el fondo; no recibe toques (los recibe
/// la barrera de la ruta).
class _Scrim extends StatelessWidget {
  const _Scrim();

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
      child: ColoredBox(color: context.fr.colors.scrim),
    ),
  );
}

/// Abre [builder] en una [FrSheetRoute] sobre el navegador de [context].
///
/// [barrierLabel] es la etiqueta accesible del velo; por defecto, la de
/// cerrar de `MaterialLocalizations`.
Future<T?> showFrSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  String? barrierLabel,
  bool useRootNavigator = false,
}) => Navigator.of(context, rootNavigator: useRootNavigator).push(
  FrSheetRoute<T>(
    builder: builder,
    barrierLabel:
        barrierLabel ??
        Localizations.of<MaterialLocalizations>(
          context,
          MaterialLocalizations,
        )?.modalBarrierDismissLabel,
  ),
);
