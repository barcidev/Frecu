import 'package:flutter/widgets.dart';
import 'package:frecu/core/design/fr_theme.dart';
import 'package:frecu/core/design/icons/fr_icons.dart';
import 'package:frecu/core/design/widgets/fr_icon_button.dart';
import 'package:frecu/features/room/domain/entities/room_reach.dart';
import 'package:frecu/i18n/strings.g.dart';

/// Cabecera de 60 px de la creación de una frecu (`.appbar` con `.ttl`):
/// Atrás, el paso y el título centrados y un hueco del ancho del botón.
class CreateRoomAppBar extends StatelessWidget {
  /// Crea la cabecera del paso [step] de [steps] con su [title]; sin
  /// [step], solo el título.
  const CreateRoomAppBar({
    required this.step,
    required this.steps,
    required this.title,
    required this.onBack,
    super.key,
  });

  /// Pasos de la creación según el tipo de frecu: Local tiene el tipo, la
  /// red y la nueva frecu; Por internet, el tipo y la nueva frecu.
  static int stepsFor(RoomReach reach) => switch (reach) {
    RoomReach.local => 3,
    RoomReach.internet => 2,
  };

  /// Paso actual, desde 1; nulo si la pantalla se abre fuera de la creación.
  final int? step;

  /// Total de pasos de la creación.
  final int steps;

  /// Título del paso.
  final String title;

  /// Vuelve atrás.
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            FrIconButton.drawn(
              icon: FrIcons.back,
              semanticLabel: t.lobby.newRoom.back,
              variant: FrIconButtonVariant.ghost,
              onPressed: onBack,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StepTitle(step: step, steps: steps, title: title),
            ),
            const SizedBox(width: 58),
          ],
        ),
      ),
    );
  }
}

/// «Paso N de M» sobre el título, centrados (`.ttl`).
class _StepTitle extends StatelessWidget {
  const _StepTitle({
    required this.step,
    required this.steps,
    required this.title,
  });

  final int? step;
  final int steps;
  final String title;

  @override
  Widget build(BuildContext context) {
    final fr = context.fr;
    final c = fr.colors;
    final step = this.step;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (step != null) ...[
          Text(
            t.lobby.newRoom.step(current: step, total: steps).toUpperCase(),
            maxLines: 1,
            style: fr.type.labelS.copyWith(color: c.tx3),
          ),
          const SizedBox(height: 3),
        ],
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: fr.type.title.copyWith(
            color: c.tx1,
            fontSize: 16,
            height: 1,
            fontWeight: const FontWeight(640),
            fontVariations: const [
              FontVariation.weight(640),
              FontVariation.width(110),
            ],
          ),
        ),
      ],
    );
  }
}

/// Contenido desplazable de un paso, con espacio abajo para su dock.
class CreateRoomScroll extends StatelessWidget {
  /// Crea el contenido con [children] en columna y [dockHeight] libre abajo.
  const CreateRoomScroll({
    required this.children,
    required this.dockHeight,
    super.key,
  });

  /// Alto del dock con un botón: 34 + 58 + 30.
  static const double oneButtonDock = 122;

  /// Alto del dock con un botón y uno ghost: 34 + 58 + 10 + 48 + 30.
  static const double twoButtonDock = 180;

  /// Contenido del paso.
  final List<Widget> children;

  /// Alto del dock que tapa el final del contenido.
  final double dockHeight;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        bottom: dockHeight + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

/// Título de un paso: Archivo 720 a 26/30, ancho 122 (`.h-screen`).
TextStyle createRoomTitleStyle(FrTheme fr) => fr.type.display.copyWith(
  color: fr.colors.tx1,
  fontSize: 26,
  height: 30 / 26,
  letterSpacing: -0.52,
  fontWeight: const FontWeight(720),
  fontVariations: const [FontVariation.weight(720), FontVariation.width(122)],
);

/// Texto de un paso: 15,5 px con alto 1,55 en `tx2` (`.p-screen`).
TextStyle createRoomMessageStyle(FrTheme fr) =>
    fr.type.body.copyWith(color: fr.colors.tx2, fontSize: 15.5, height: 1.55);

/// Ocupa todo el ancho y, si el botón no cabe (un teléfono de 360 px o un
/// texto largo), lo encoge en lugar de desbordarlo.
class CreateRoomFitWidth extends StatelessWidget {
  /// Ajusta [child] al ancho disponible.
  const CreateRoomFitWidth({required this.child, super.key});

  /// Botón que se ajusta.
  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) => FittedBox(
      fit: BoxFit.scaleDown,
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: box.maxWidth),
        child: IntrinsicWidth(child: child),
      ),
    ),
  );
}
