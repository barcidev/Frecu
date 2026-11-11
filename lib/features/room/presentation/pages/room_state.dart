import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frecu/features/room/domain/entities/link_quality.dart';
import 'package:frecu/features/room/domain/entities/participant.dart';
import 'package:frecu/features/room/domain/entities/room_status.dart';
import 'package:frecu/features/room/domain/entities/talk_mode.dart';
import 'package:frecu/features/room/presentation/providers/voice_provider.dart';
import 'package:frecu/features/room/presentation/widgets/host_silence.dart';

/// Participantes y estado como se ven en la frecu: con lo que sabe la
/// [voice], conectando mientras se negocian los enlaces y, si el anfitrión
/// no responde ([silence]), con solo él reconectando.
(List<Participant>, RoomStatus?) shownRoom(
  List<Participant> participants,
  RoomStatus? status,
  String? localId,
  VoiceState voice,
  HostSilence? silence,
) {
  final shown = HostSilence.showParticipants(
    silence,
    participantsWithVoice(participants, localId, voice),
  );
  return (
    shown,
    negotiatingStatus(HostSilence.showStatus(silence, status), shown, localId),
  );
}

/// Nivel de voz de cada persona por id: el de los pares y, con [localId],
/// el propio.
Map<String, double> voiceLevelsOf(WidgetRef ref, String? localId) => {
  ...?ref.watch(peerVoiceLevelsProvider).value,
  if (localId != null) localId: ref.watch(localVoiceLevelProvider).value ?? 0,
};

/// Participantes con lo que sabe la voz: quién se silenció en micrófono
/// abierto (también la persona propia [localId]) y cómo va el enlace con
/// cada uno. Lo usan la pantalla de la frecu y su notificación.
List<Participant> participantsWithVoice(
  List<Participant> participants,
  String? localId,
  VoiceState voice,
) {
  final selfMuted = voice.talkMode == TalkMode.openMic && !voice.isTalking;
  return [
    for (final participant in participants)
      if (participant.id == localId)
        participant.copyWith(isMuted: participant.isMuted || selfMuted)
      else
        participant.copyWith(
          isMuted:
              participant.isMuted || voice.mutedPeers.contains(participant.id),
          connectionState:
              voice.peerLinks[participant.id] ?? participant.connectionState,
          linkQuality: voice.peerQuality[participant.id] ?? LinkQuality.good,
        ),
  ];
}

/// Mientras se negocian los enlaces de voz y ninguno está arriba, la frecu
/// está conectando (3.0 del prototipo).
RoomStatus? negotiatingStatus(
  RoomStatus? status,
  List<Participant> participants,
  String? localId,
) {
  final connected =
      status?.maybeWhen(connected: () => true, orElse: () => false) ?? false;
  if (!connected) return status;
  final others = participants.where((p) => p.id != localId).toList();
  final linking =
      others.isNotEmpty &&
      others.every((p) => p.connectionState == PeerConnectionState.connecting);
  return linking ? const RoomStatus.connecting() : status;
}
