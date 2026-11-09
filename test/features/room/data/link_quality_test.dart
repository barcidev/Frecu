// Señal débil (corte 1 de la épica de hardware V1):
// CUANDO el `getStats()` de un enlace trae un `currentRoundTripTime` alto o
// pérdidas de paquetes de audio en el intervalo ENTONCES, tras dos medidas
// malas seguidas, el enlace pasa a débil; tras tres buenas seguidas vuelve a
// bueno. Sin paquetes nuevos la pérdida no cuenta, y los enlaces que
// desaparecen se olvidan. El monitor solo mide mientras alguien escucha.
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:frecu/features/room/data/datasources/peer_connection_datasource.dart';
import 'package:frecu/features/room/data/repositories/link_quality_monitor.dart';
import 'package:frecu/features/room/domain/entities/link_quality.dart';

/// Medida con [rttMs] y los contadores acumulados [received] y [lost].
LinkSample _sample({double? rttMs, int? received, int? lost}) =>
    (rttMs: rttMs, packetsReceived: received, packetsLost: lost);

StatsReport _report(String type, Map<String, Object> values) =>
    StatsReport('$type-${values.length}', type, 0, values);

void main() {
  group('LinkQualityClassifier', () {
    late LinkQualityClassifier classifier;

    setUp(() => classifier = LinkQualityClassifier());

    test('una medida mala sola no basta; dos seguidas lo vuelven débil', () {
      expect(classifier.add({'a': _sample(rttMs: 900)}), {
        'a': LinkQuality.good,
      });
      expect(classifier.add({'a': _sample(rttMs: 900)}), {
        'a': LinkQuality.weak,
      });
    });

    test('con un retraso normal sigue bueno', () {
      for (var i = 0; i < 5; i++) {
        expect(classifier.add({'a': _sample(rttMs: 12)}), {
          'a': LinkQuality.good,
        });
      }
    });

    test('la pérdida se mide en el intervalo, no en el acumulado', () {
      // Mucha pérdida vieja acumulada, pero ninguna nueva: bueno.
      classifier
        ..add({'a': _sample(received: 1000, lost: 400)})
        ..add({'a': _sample(received: 1100, lost: 400)});
      expect(classifier.add({'a': _sample(received: 1200, lost: 400)}), {
        'a': LinkQuality.good,
      });

      // 20 de 120 perdidos (17 %) dos veces seguidas: débil.
      classifier.add({'a': _sample(received: 1300, lost: 420)});
      expect(classifier.add({'a': _sample(received: 1400, lost: 440)}), {
        'a': LinkQuality.weak,
      });
    });

    test('sin paquetes nuevos la pérdida no cuenta', () {
      classifier
        ..add({'a': _sample(received: 100, lost: 0)})
        ..add({'a': _sample(received: 100, lost: 0)});
      expect(classifier.add({'a': _sample(received: 100, lost: 0)}), {
        'a': LinkQuality.good,
      });
    });

    test('vuelve a bueno solo tras tres medidas buenas seguidas', () {
      classifier
        ..add({'a': _sample(rttMs: 900)})
        ..add({'a': _sample(rttMs: 900)});
      expect(classifier.add({'a': _sample(rttMs: 10)}), {
        'a': LinkQuality.weak,
      });
      expect(classifier.add({'a': _sample(rttMs: 10)}), {
        'a': LinkQuality.weak,
      });
      // Una mala en medio reinicia la cuenta.
      expect(classifier.add({'a': _sample(rttMs: 900)}), {
        'a': LinkQuality.weak,
      });
      classifier
        ..add({'a': _sample(rttMs: 10)})
        ..add({'a': _sample(rttMs: 10)});
      expect(classifier.add({'a': _sample(rttMs: 10)}), {
        'a': LinkQuality.good,
      });
    });

    test('cada enlace va por su cuenta y los que desaparecen se olvidan', () {
      classifier
        ..add({'a': _sample(rttMs: 900), 'b': _sample(rttMs: 5)})
        ..add({'a': _sample(rttMs: 900), 'b': _sample(rttMs: 5)});
      expect(classifier.quality, {
        'a': LinkQuality.weak,
        'b': LinkQuality.good,
      });

      expect(classifier.add({'b': _sample(rttMs: 5)}), {'b': LinkQuality.good});
      // Si vuelve, empieza de cero.
      expect(classifier.add({'a': _sample(rttMs: 900)}), {
        'a': LinkQuality.good,
      });
    });

    test('contadores que vuelven atrás (enlace nuevo) no cuentan', () {
      classifier.add({'a': _sample(received: 5000, lost: 10)});
      expect(classifier.add({'a': _sample(received: 50, lost: 40)}), {
        'a': LinkQuality.good,
      });
    });
  });

  group('PeerConnectionDataSource.linkSampleOf', () {
    test('toma el RTT del par de candidatos elegido y los contadores del '
        'audio recibido', () {
      final sample = PeerConnectionDataSource.linkSampleOf([
        _report('candidate-pair', {
          'state': 'in-progress',
          'currentRoundTripTime': 9.0,
        }),
        _report('candidate-pair', {
          'state': 'succeeded',
          'nominated': true,
          'currentRoundTripTime': 0.25,
        }),
        _report('inbound-rtp', {
          'kind': 'audio',
          'packetsReceived': 480,
          'packetsLost': 12,
        }),
        _report('inbound-rtp', {
          'kind': 'video',
          'packetsReceived': 9999,
          'packetsLost': 9999,
        }),
      ]);

      expect(sample.rttMs, 250);
      expect(sample.packetsReceived, 480);
      expect(sample.packetsLost, 12);
    });

    test('sin esos informes cada dato queda nulo', () {
      final sample = PeerConnectionDataSource.linkSampleOf([
        _report('media-source', {'kind': 'audio', 'audioLevel': 0.4}),
      ]);

      expect(sample.rttMs, isNull);
      expect(sample.packetsReceived, isNull);
      expect(sample.packetsLost, isNull);
    });
  });

  group('LinkQualityMonitor', () {
    test(
      'mide solo mientras alguien escucha y emite solo los cambios',
      () async {
        var reads = 0;
        final monitor = LinkQualityMonitor(() async {
          reads++;
          return {'a': _sample(rttMs: 900)};
        }, interval: const Duration(milliseconds: 5));
        addTearDown(monitor.dispose);

        final seen = <Map<String, LinkQuality>>[];
        final sub = monitor.watch().listen(seen.add);
        await Future<void>.delayed(const Duration(milliseconds: 60));
        await sub.cancel();
        final readsWhileListening = reads;
        await Future<void>.delayed(const Duration(milliseconds: 40));

        // Empieza vacío, pasa a bueno con la primera medida y a débil con la
        // segunda mala; cada cambio una sola vez.
        expect(seen.map((q) => q['a']).toList(), [
          null,
          LinkQuality.good,
          LinkQuality.weak,
        ]);
        expect(readsWhileListening, greaterThan(2));
        expect(reads, readsWhileListening);
      },
    );
  });
}
