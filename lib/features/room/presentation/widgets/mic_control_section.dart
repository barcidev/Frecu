import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frecu/core/design/fr_theme.dart';
import 'package:frecu/core/design/icons/fr_icon.dart';
import 'package:frecu/core/design/icons/fr_icons.dart';
import 'package:frecu/core/design/motion/reduced_motion.dart';
import 'package:frecu/core/design/widgets/fr_banner.dart';
import 'package:frecu/core/design/widgets/fr_pressable.dart';
import 'package:frecu/core/design/widgets/fr_segmented.dart';
import 'package:frecu/features/room/domain/entities/audio_route.dart';
import 'package:frecu/features/room/domain/entities/talk_mode.dart';
import 'package:frecu/features/room/presentation/providers/voice_provider.dart';
import 'package:frecu/features/room/presentation/widgets/ptt_core.dart';
import 'package:frecu/features/room/presentation/widgets/room_mesh_scene.dart';
import 'package:frecu/features/room/presentation/widgets/room_sheets.dart';
import 'package:frecu/features/room/presentation/widgets/room_talk.dart';
import 'package:frecu/i18n/strings.g.dart';

/// Controles de voz de la frecu activa (`.ctrls` y `pttZone` del
/// prototipo): la pastilla de ruta, el selector PTT | Abierto y el núcleo
/// PTT.
class MicControlSection extends ConsumerWidget {
  /// Crea los controles con el estado de voz y el de habla; [onRoute] abre
  /// la hoja de ruta de audio.
  const MicControlSection({
    required this.voiceState,
    required this.talk,
    required this.onRoute,
    super.key,
  });

  /// Estado reactivo de voz y audio.
  final VoiceState voiceState;

  /// Estado de habla de la frecu.
  final RoomTalk talk;

  /// Abre la hoja de ruta de audio.
  final VoidCallback onRoute;

  /// Ancho máximo del selector (`.ctrls .seg`).
  static const double _selectorWidth = 204;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final voice = ref.read(voiceNotifierProvider.notifier);
    final speaker = talk.speaker;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 52,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                AudioRoutePill(
                  key: const Key('audio_route_button'),
                  route: voiceState.audioRoute,
                  deviceName: voiceState.bluetoothName,
                  active: speaker != null,
                  onPressed: onRoute,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: _selectorWidth,
                      ),
                      child: _modeSelector(voice),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        PttCore(
          phase: talk.pttPhase(),
          onAirFor: ref.watch(onAirClockProvider) ?? Duration.zero,
          speakerName: speaker?.name,
          speakerColor: speaker == null
              ? null
              : meshNodeColor(context.fr.colors, speaker),
          speakerSeed: (speaker?.slot ?? 0) + 1,
          onStart: voice.startTalking,
          onStop: voice.stopTalking,
          onToggle: voice.toggleMicrophone,
        ),
      ],
    );
  }

  Widget _modeSelector(VoiceNotifier voice) => FrSegmented<TalkMode>(
    value: voiceState.talkMode,
    onChanged: talk.enabled ? voice.chooseTalkMode : null,
    segments: [
      FrSegment(
        value: TalkMode.pushToTalk,
        label: t.room.talk.modePtt,
        icon: const FrIcon(FrIcons.walkie, key: Key('mode_ptt')),
      ),
      FrSegment(
        value: TalkMode.openMic,
        label: t.room.talk.modeOpen,
        icon: const FrIcon(FrIcons.openMic, key: Key('mode_open_mic')),
      ),
    ],
  );
}

/// Aviso de eco (`.echo` del prototipo): micrófono abierto con la salida por
/// el altavoz. Si se cierra no vuelve hasta que deja de ser [visible].
class EchoNotice extends StatefulWidget {
  /// Crea el aviso; se muestra si [visible].
  const EchoNotice({required this.visible, super.key});

  /// Hay micrófono abierto y la salida es el altavoz.
  final bool visible;

  @override
  State<EchoNotice> createState() => _EchoNoticeState();
}

class _EchoNoticeState extends State<EchoNotice> {
  bool _dismissed = false;

  @override
  void didUpdateWidget(EchoNotice oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.visible) _dismissed = false;
  }

  @override
  Widget build(BuildContext context) {
    final fr = context.fr;
    final echo = t.room.talk.echo;
    return AnimatedSwitcher(
      duration: context.reduceMotion ? fr.motion.quick : fr.motion.smooth,
      child: widget.visible && !_dismissed
          ? FrBanner(
              key: const Key('echo_notice'),
              tone: FrBannerTone.warn,
              icon: Icons.headphones_rounded,
              title: echo.title,
              message: echo.message,
              floating: true,
              dismissLabel: echo.dismiss,
              onDismiss: () => setState(() => _dismissed = true),
            )
          : const SizedBox.shrink(),
    );
  }
}

/// Pastilla de la salida de audio (`.route` del prototipo): ícono y nombre
/// de la ruta (el del dispositivo Bluetooth si se conoce), barras de
/// actividad y flecha; abre la hoja de ruta.
class AudioRoutePill extends StatelessWidget {
  /// Crea la pastilla de [route]; las barras se mueven si [active].
  const AudioRoutePill({
    required this.route,
    required this.active,
    required this.onPressed,
    this.deviceName,
    super.key,
  });

  /// Ruta de audio activa.
  final AudioRoute route;

  /// Nombre del dispositivo Bluetooth conectado, si hay uno.
  final String? deviceName;

  /// Llega audio por la ruta (otra persona habla).
  final bool active;

  /// Abre la hoja de ruta.
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final fr = context.fr;
    final c = fr.colors;
    final name = audioRouteName(route, deviceName: deviceName);
    return FrPressable(
      onPressed: onPressed,
      pressedScale: 0.96,
      semanticLabel: t.room.sheets.route.label(route: name),
      builder: (context, _, _) => Container(
        height: 48,
        padding: const EdgeInsets.fromLTRB(10, 0, 12, 0),
        decoration: BoxDecoration(
          color: c.bg1,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.line1),
        ),
        foregroundDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [c.spec, c.spec.withValues(alpha: 0)],
            stops: const [0, 0.04],
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 9,
          children: [
            FrIcon(audioRouteIcon(route), size: 18, color: c.tx1),
            // Un nombre de Bluetooth largo se corta y no aprieta al selector.
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 112),
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: fr.type.body.copyWith(
                  fontSize: 13.5,
                  height: 1,
                  fontWeight: FontWeight.w600,
                  fontVariations: const [
                    FontVariation.weight(600),
                    FontVariation.width(105),
                  ],
                  color: c.tx1,
                ),
              ),
            ),
            _RouteBars(active: active),
            FrIcon(FrIcons.down, size: 16, color: c.tx3),
          ],
        ),
      ),
    );
  }
}

/// Tres barras de 3 × 14 (`.bars`): suben y bajan mientras llega audio y
/// quedan al 30 % en `tx4` en reposo o con movimiento reducido.
class _RouteBars extends StatelessWidget {
  const _RouteBars({required this.active});

  final bool active;

  /// Duración y desfase de cada barra (`.bars i`).
  static const List<(double, double)> _timing = [
    (0.9, 0),
    (0.7, -0.3),
    (1.1, -0.6),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.fr.colors;
    if (!active || context.reduceMotion) {
      return _bars([0.3, 0.3, 0.3], active ? c.signalFg : c.tx4);
    }
    return FrLoop(
      builder: (context, seconds) => ValueListenableBuilder<double>(
        valueListenable: seconds,
        builder: (context, time, _) => _bars([
          for (final (period, delay) in _timing) _height(time, period, delay),
        ], c.signalFg),
      ),
    );
  }

  /// Alto de 25 % a 100 % que va y vuelve en [period] segundos.
  static double _height(double time, double period, double delay) {
    final phase = ((time - delay) / period) % 2;
    final swing = phase < 1 ? phase : 2 - phase;
    final eased = (1 - math.cos(swing * math.pi)) / 2;
    return 0.25 + 0.75 * eased;
  }

  Widget _bars(List<double> heights, Color color) => SizedBox(
    height: 14,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      spacing: 2,
      children: [
        for (final height in heights)
          Container(
            width: 3,
            height: 14 * height,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
      ],
    ),
  );
}
