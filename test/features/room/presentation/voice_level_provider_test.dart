// AC1: CUANDO la pantalla de la frecu activa escucha los niveles ENTONCES `VoiceRepository` lee `getStats()` de cada conexión cada 100 ms y emite por `watchLocalLevel` el `audioLevel` del `media-source` de audio y por `watchPeerLevels` el `audioLevel` del `inbound-rtp` de audio de cada participante por su id, de 0 a 1, solo cuando cambian; CUANDO nadie los escucha ENTONCES deja de leer y los niveles vuelven a 0.
// AC2: CUANDO el usuario transmite (PTT o micrófono abierto) ENTONCES el bisel y el anillo del núcleo PTT siguen, con su resorte, el nivel real de su micrófono en la escala del VU; CUANDO recibe a alguien ENTONCES el anillo de recepción sigue el nivel real del audio de esa persona; CUANDO no suenan ENTONCES vuelven a reposo (al aire, al mínimo de al aire). El núcleo ya no usa `frVoice`.
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/features/room/domain/repositories/voice_repository.dart';
import 'package:frecu/features/room/presentation/providers/voice_provider.dart';
import 'package:mocktail/mocktail.dart';

class _MockVoiceRepository extends Mock implements VoiceRepository {}

/// Amplitud lineal de [decibels] dB.
double _amplitude(double decibels) => math.pow(10, decibels / 20).toDouble();

void main() {
  group('voiceMeterLevel', () {
    test('AC2: pasa el audioLevel lineal a la escala del VU, de −48 dB (0) '
        'a 0 dB (1)', () {
      expect(voiceMeterLevel(0), 0);
      expect(voiceMeterLevel(-0.2), 0);
      expect(voiceMeterLevel(1), 1);
      expect(voiceMeterLevel(1.5), 1);
      expect(voiceMeterLevel(_amplitude(-48)), closeTo(0, 1e-9));
      expect(voiceMeterLevel(_amplitude(-60)), 0);
      expect(voiceMeterLevel(_amplitude(-24)), closeTo(0.5, 1e-9));
      expect(voiceMeterLevel(_amplitude(-12)), closeTo(0.75, 1e-9));
      expect(voiceMeterLevel(0.1), closeTo(1 - 20 / 48, 1e-9));
    });
  });

  group('Proveedores de nivel', () {
    late _MockVoiceRepository voice;
    late StreamController<double> local;
    late StreamController<Map<String, double>> peers;

    setUp(() {
      voice = _MockVoiceRepository();
      local = StreamController<double>.broadcast();
      peers = StreamController<Map<String, double>>.broadcast();
      when(voice.watchLocalLevel).thenAnswer((_) => local.stream);
      when(voice.watchPeerLevels).thenAnswer((_) => peers.stream);
    });

    tearDown(() async {
      await local.close();
      await peers.close();
    });

    ProviderContainer container() => ProviderContainer.test(
      overrides: [voiceRepositoryProvider.overrideWithValue(voice)],
    );

    test('AC2: dan el nivel propio y el de cada par del repositorio en la '
        'escala del VU', () async {
      final scope = container()
        ..listen(localVoiceLevelProvider, (_, _) {})
        ..listen(peerVoiceLevelsProvider, (_, _) {});
      await pumpEventQueue();

      local.add(_amplitude(-24));
      peers.add({'p-2': 0.1, 'p-3': 0, 'p-4': 1});
      await pumpEventQueue();

      expect(scope.read(localVoiceLevelProvider).value, closeTo(0.5, 1e-9));
      final levels = scope.read(peerVoiceLevelsProvider).value!;
      expect(levels.keys, unorderedEquals(['p-2', 'p-3', 'p-4']));
      expect(levels['p-2'], closeTo(1 - 20 / 48, 1e-9));
      expect(levels['p-3'], 0);
      expect(levels['p-4'], 1);
    });

    test(
      'AC1: dejan de escuchar al repositorio cuando nadie los mira',
      () async {
        final scope = container();
        final localSub = scope.listen(localVoiceLevelProvider, (_, _) {});
        final peersSub = scope.listen(peerVoiceLevelsProvider, (_, _) {});
        await pumpEventQueue();
        expect(local.hasListener, isTrue);
        expect(peers.hasListener, isTrue);

        localSub.close();
        peersSub.close();
        await scope.pump();
        await pumpEventQueue();

        expect(local.hasListener, isFalse);
        expect(peers.hasListener, isFalse);
      },
    );
  });
}
