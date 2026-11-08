import 'package:flutter/material.dart';
import 'package:frecu/core/design/fr_theme.dart';
import 'package:frecu/core/design/icons/fr_icons.dart';
import 'package:frecu/core/design/tokens/fr_type.dart';
import 'package:frecu/core/design/widgets/fr_button.dart';
import 'package:frecu/core/design/widgets/fr_scaffold.dart';
import 'package:frecu/core/design/widgets/fr_segmented.dart';
import 'package:frecu/features/lobby/presentation/widgets/create_room_layout.dart';
import 'package:frecu/features/lobby/presentation/widgets/hotspot_illustration.dart';
import 'package:frecu/i18n/strings.g.dart';

/// Plataforma de los pasos de la guía.
enum HotspotPlatform {
  /// Zona Wi-Fi de Android.
  android,

  /// Punto de acceso personal de iPhone.
  iphone,
}

/// Guía del punto de acceso (pantalla `hotspot` del prototipo), paso 1 de 2
/// de la creación: la ilustración, cómo activar la zona Wi-Fi en Android o
/// en iPhone y abajo «Ya está activo» y «Ya estamos en la misma Wi-Fi».
class HotspotGuideStep extends StatefulWidget {
  /// Crea la guía.
  const HotspotGuideStep({
    required this.onBack,
    required this.onContinue,
    super.key,
  });

  /// Sale de la creación.
  final VoidCallback onBack;

  /// Pasa a la nueva frecu.
  final VoidCallback onContinue;

  @override
  State<HotspotGuideStep> createState() => _HotspotGuideStepState();
}

class _HotspotGuideStepState extends State<HotspotGuideStep> {
  /// Plataforma elegida; nula hasta que se toca el selector.
  HotspotPlatform? _chosen;

  HotspotPlatform get _platform =>
      _chosen ??
      (Theme.of(context).platform == TargetPlatform.iOS
          ? HotspotPlatform.iphone
          : HotspotPlatform.android);

  @override
  Widget build(BuildContext context) {
    final guide = t.lobby.newRoom.guide;
    return FrScaffold(
      dock: _GuideDock(onContinue: widget.onContinue),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CreateRoomAppBar(step: 1, title: guide.title, onBack: widget.onBack),
          Expanded(
            child: CreateRoomScroll(
              dockHeight: CreateRoomScroll.twoButtonDock,
              children: [
                const HotspotIllustration(),
                _heading(context),
                _platformPicker(),
                _steps(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// «Activa tu punto de acceso» y «Tu teléfono será la antena del grupo.».
  Widget _heading(BuildContext context) {
    final fr = context.fr;
    final guide = t.lobby.newRoom.guide;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(guide.heading, style: createRoomTitleStyle(fr)),
          const SizedBox(height: 8),
          Text(guide.message, style: createRoomMessageStyle(fr)),
        ],
      ),
    );
  }

  /// Selector Android | iPhone.
  Widget _platformPicker() {
    final guide = t.lobby.newRoom.guide;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: FrSegmented<HotspotPlatform>(
        segments: [
          FrSegment(value: HotspotPlatform.android, label: guide.android),
          FrSegment(value: HotspotPlatform.iphone, label: guide.iphone),
        ],
        value: _platform,
        onChanged: (value) => setState(() => _chosen = value),
      ),
    );
  }

  /// Los tres pasos de la plataforma elegida, numerados.
  Widget _steps() {
    final guide = t.lobby.newRoom.guide;
    final steps = _platform == HotspotPlatform.iphone
        ? guide.iphoneSteps
        : guide.androidSteps;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
      child: Column(
        children: [
          for (var i = 0; i < steps.length; i++)
            HotspotGuideStepRow(number: i + 1, step: steps[i]),
        ],
      ),
    );
  }
}

/// Un paso de la guía (`.stepsl li`): el número en Martian Mono y el texto
/// con su inicio en negrita.
class HotspotGuideStepRow extends StatelessWidget {
  /// Crea el paso [number] (desde 1) con su texto [step].
  const HotspotGuideStepRow({
    required this.number,
    required this.step,
    super.key,
  });

  /// Número del paso, desde 1.
  final int number;

  /// Texto del paso.
  final HotspotStep step;

  /// Inicio del paso: en 600 y en [ink].
  static TextStyle _lead(TextStyle text, Color ink) => text.copyWith(
    color: ink,
    fontWeight: FontWeight.w600,
    fontVariations: const [FontVariation.weight(600), FontVariation.width(100)],
  );

  @override
  Widget build(BuildContext context) {
    final fr = context.fr;
    final c = fr.colors;
    final text = fr.type.body.copyWith(
      fontSize: 14.5,
      height: 1.45,
      color: c.tx2,
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.line1)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 13),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 34,
              child: Padding(
                padding: const EdgeInsets.only(top: 5),
                child: _StepNumber(number),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: step.lead, style: _lead(text, c.tx1)),
                    TextSpan(text: step.rest),
                  ],
                ),
                style: text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// «01», «02»… en `signalFg`; de día, sobre el marcatexto de señal.
class _StepNumber extends StatelessWidget {
  const _StepNumber(this.number);

  final int number;

  @override
  Widget build(BuildContext context) {
    final c = context.fr.colors;
    final mark = c.signalMark;
    final label = Text(
      number.toString().padLeft(2, '0'),
      style: TextStyle(
        fontFamily: FrFonts.mono,
        fontSize: 11,
        height: 1,
        fontWeight: FontWeight.w500,
        fontVariations: const [FontVariation.weight(500)],
        letterSpacing: 0.66,
        color: c.signalFg,
      ),
    );
    if (mark == null) return Align(alignment: Alignment.topLeft, child: label);
    return Align(
      alignment: Alignment.topLeft,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: -1,
            height: 5.5,
            child: ColoredBox(color: mark),
          ),
          label,
        ],
      ),
    );
  }
}

/// Dock de la guía: «Ya está activo» y «Ya estamos en la misma Wi-Fi».
class _GuideDock extends StatelessWidget {
  const _GuideDock({required this.onContinue});

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final guide = t.lobby.newRoom.guide;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CreateRoomFitWidth(
          child: FrButton.drawn(
            label: guide.ready,
            trailingIcon: FrIcons.arrow,
            expand: true,
            onPressed: onContinue,
          ),
        ),
        const SizedBox(height: 10),
        CreateRoomFitWidth(
          child: FrButton(
            label: guide.sameWifi,
            variant: FrButtonVariant.ghost,
            expand: true,
            onPressed: onContinue,
          ),
        ),
      ],
    );
  }
}
