import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frecu/features/room/domain/entities/talk_mode.dart';
import 'package:frecu/features/room/presentation/providers/voice_provider.dart';
import 'package:frecu/features/room/presentation/widgets/ptt_button.dart';
import 'package:frecu/i18n/strings.g.dart';

/// Sección de control de voz que permite conmutar modo de habla y operar el micrófono.
class MicControlSection extends ConsumerStatefulWidget {
  /// Constructor constante.
  const MicControlSection({required this.voiceState, super.key});

  /// Estado reactivo de voz y audio.
  final VoiceState voiceState;

  @override
  ConsumerState<MicControlSection> createState() => _MicControlSectionState();
}

class _MicControlSectionState extends ConsumerState<MicControlSection> {
  bool _isPointerDown = false;

  void _handleStartTalking() {
    setState(() => _isPointerDown = true);
    ref.read(voiceNotifierProvider.notifier).startTalking();
  }

  void _handleStopTalking() {
    setState(() => _isPointerDown = false);
    ref.read(voiceNotifierProvider.notifier).stopTalking();
  }

  Widget _buildModeSelector(ThemeData theme) {
    return Center(
      child: SegmentedButton<TalkMode>(
        key: const Key('talk_mode_segmented_button'),
        segments: [
          const ButtonSegment<TalkMode>(
            value: TalkMode.pushToTalk,
            label: Text('PTT', key: Key('mode_ptt')),
            icon: Icon(Icons.touch_app),
          ),
          ButtonSegment<TalkMode>(
            value: TalkMode.openMic,
            label: Text(t.room.openMic, key: const Key('mode_open_mic')),
            icon: const Icon(Icons.mic),
          ),
        ],
        selected: {widget.voiceState.talkMode},
        onSelectionChanged: (selected) {
          ref.read(voiceNotifierProvider.notifier).setTalkMode(selected.first);
        },
      ),
    );
  }

  Widget _buildOpenMicControl(ThemeData theme, bool isTalking) {
    return Card(
      color: isTalking ? theme.colorScheme.primaryContainer : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isTalking ? t.room.speaking : t.room.muted,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isTalking ? theme.colorScheme.primary : null,
                  ),
                ),
                Text(t.room.openMic, style: theme.textTheme.bodySmall),
              ],
            ),
            FilledButton.icon(
              key: const Key('mic_toggle_button'),
              icon: Icon(isTalking ? Icons.mic : Icons.mic_off),
              label: Text(isTalking ? t.room.muted : t.room.speaking),
              style: FilledButton.styleFrom(
                backgroundColor: isTalking
                    ? theme.colorScheme.error
                    : theme.colorScheme.primary,
              ),
              onPressed: () {
                ref.read(voiceNotifierProvider.notifier).toggleMicrophone();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPtt = widget.voiceState.talkMode == TalkMode.pushToTalk;
    final isTalking = _isPointerDown || widget.voiceState.isTalking;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildModeSelector(theme),
        const SizedBox(height: 12),
        if (isPtt)
          Center(
            child: PttButton(
              isTalking: isTalking,
              onStartTalking: _handleStartTalking,
              onStopTalking: _handleStopTalking,
              label: t.room.pushToTalk,
              activeLabel: t.room.speaking,
            ),
          )
        else
          _buildOpenMicControl(theme, widget.voiceState.isTalking),
      ],
    );
  }
}
