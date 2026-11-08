import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frecu/core/design/fr_theme.dart';
import 'package:frecu/core/design/icons/fr_icon.dart';
import 'package:frecu/core/design/icons/fr_icons.dart';
import 'package:frecu/core/design/motion/reduced_motion.dart';
import 'package:frecu/core/design/widgets/fr_banner.dart';
import 'package:frecu/core/design/widgets/fr_segmented.dart';
import 'package:frecu/features/room/domain/entities/talk_mode.dart';
import 'package:frecu/features/room/presentation/providers/voice_provider.dart';
import 'package:frecu/features/room/presentation/widgets/ptt_core.dart';
import 'package:frecu/features/room/presentation/widgets/room_mesh_scene.dart';
import 'package:frecu/features/room/presentation/widgets/room_talk.dart';
import 'package:frecu/i18n/strings.g.dart';

/// Controles de voz de la frecu activa (`.ctrls` y `pttZone` del
/// prototipo): el selector PTT | Abierto y el núcleo PTT.
class MicControlSection extends ConsumerWidget {
  /// Crea los controles con el estado de voz y el de habla.
  const MicControlSection({
    required this.voiceState,
    required this.talk,
    super.key,
  });

  /// Estado reactivo de voz y audio.
  final VoiceState voiceState;

  /// Estado de habla de la frecu.
  final RoomTalk talk;

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
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _selectorWidth),
              child: _modeSelector(voice),
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
    onChanged: talk.enabled ? voice.setTalkMode : null,
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
