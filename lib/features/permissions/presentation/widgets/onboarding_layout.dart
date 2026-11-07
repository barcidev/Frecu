import 'package:flutter/widgets.dart';
import 'package:frecu/core/design/fr_theme.dart';
import 'package:frecu/core/design/icons/fr_icons.dart';
import 'package:frecu/core/design/widgets/fr_icon_button.dart';
import 'package:frecu/core/design/widgets/fr_steps.dart';
import 'package:frecu/i18n/strings.g.dart';

/// Línea superior del recorrido (`.topline`): Atrás si hay paso anterior, los
/// pasos con el actual encendido y el contador «01 / 03».
class OnboardingTopLine extends StatelessWidget {
  /// Crea la línea del paso [step] (desde 0).
  const OnboardingTopLine({required this.step, this.onBack, super.key});

  /// Pasos del recorrido: bienvenida, nombre y permisos.
  static const int stepCount = 3;

  /// Paso actual, desde 0.
  final int step;

  /// Vuelve al paso anterior; sin él no hay botón Atrás.
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final fr = context.fr;
    final onBack = this.onBack;
    return Padding(
      padding: EdgeInsets.fromLTRB(onBack == null ? 22 : 10, 10, 22, 0),
      child: SizedBox(
        height: 40,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (onBack != null)
              FrIconButton.drawn(
                icon: FrIcons.back,
                semanticLabel: t.permissions.back,
                onPressed: onBack,
                variant: FrIconButtonVariant.ghost,
                compact: true,
              ),
            FrSteps(count: stepCount, current: step),
            Text(
              t.permissions.stepOf(
                current: _twoDigits(step + 1),
                total: _twoDigits(stepCount),
              ),
              style: fr.type.labelS.copyWith(color: fr.colors.tx3),
            ),
          ],
        ),
      ),
    );
  }

  static String _twoDigits(int value) => value.toString().padLeft(2, '0');
}

/// Título y texto de un paso (`.h-screen` y `.p-screen`).
class OnboardingHeading extends StatelessWidget {
  /// Crea el encabezado con [title] y [message].
  const OnboardingHeading({
    required this.title,
    required this.message,
    super.key,
  });

  /// Título del paso.
  final String title;

  /// Texto bajo el título.
  final String message;

  @override
  Widget build(BuildContext context) {
    final fr = context.fr;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: onboardingTitleStyle(fr)),
          const SizedBox(height: 10),
          Text(message, style: onboardingMessageStyle(fr)),
        ],
      ),
    );
  }
}

/// Contenido desplazable de un paso, con espacio abajo para el dock.
class OnboardingScroll extends StatelessWidget {
  /// Crea el contenido con [children] en columna.
  const OnboardingScroll({required this.children, super.key});

  /// Alto del dock con un botón: 34 + 58 + 30.
  static const double dockClearance = 122;

  /// Contenido del paso.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        bottom: dockClearance + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

/// Título de un paso: Archivo 720 a 30 px, ancho 122 (`.h-screen`).
TextStyle onboardingTitleStyle(FrTheme fr) => fr.type.display.copyWith(
  color: fr.colors.tx1,
  fontSize: 30,
  height: 1.06,
  letterSpacing: -0.6,
  fontWeight: const FontWeight(720),
  fontVariations: const [FontVariation.weight(720), FontVariation.width(122)],
);

/// Texto de un paso: 15,5 px con alto 1,55 en `tx2` (`.p-screen`).
TextStyle onboardingMessageStyle(FrTheme fr) =>
    fr.type.body.copyWith(color: fr.colors.tx2, fontSize: 15.5, height: 1.55);
