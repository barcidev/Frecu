import 'package:frecu/features/room/domain/entities/participant.dart';
import 'package:frecu/features/room/presentation/widgets/room_mesh_scene.dart';

/// Participantes de las pruebas de la malla.
const jorge = Participant(id: 'p-1', displayName: 'Jorge', isHost: true);
const ana = Participant(id: 'p-2', displayName: 'Ana');
const leo = Participant(id: 'p-3', displayName: 'Leo');
const sofi = Participant(id: 'p-4', displayName: 'Sofi');

/// Escena con Ana hablando con nivel [level] en el lugar 1, Leo en el 2 y
/// Sofi enlazando en el 3.
List<MeshNode?> talkingScene({
  bool anaSpeaks = true,
  bool withLeo = true,
  MeshLink link = MeshLink.ok,
  double level = 0.8,
}) => [
  MeshNode(id: 'p-1', name: 'Jorge', slot: 0, isMe: true, link: link),
  MeshNode(
    id: 'p-2',
    name: 'Ana',
    slot: 1,
    speaking: anaSpeaks,
    link: link,
    level: level,
  ),
  if (withLeo) MeshNode(id: 'p-3', name: 'Leo', slot: 2, link: link) else null,
  const MeshNode(id: 'p-4', name: 'Sofi', slot: 3, link: MeshLink.link),
  null,
  null,
];
