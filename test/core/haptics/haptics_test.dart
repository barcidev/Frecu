// Vibración (corte 2 de la épica de hardware V1): CUANDO la frecu pide un
// patrón ENTONCES se envía por el canal nativo `frecu/haptics`; si la
// vibración está apagada en Ajustes no se envía nada, y un fallo del canal
// nunca rompe la frecu.
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/core/haptics/haptics.dart';
import 'package:frecu/features/settings/presentation/providers/vibration_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('envía el nombre del patrón por el canal frecu/haptics', () async {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(Haptics.channel, (call) async {
          calls.add(call);
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(Haptics.channel, null),
    );

    await Haptics().play(HapticPattern.sos);

    expect(calls.single.method, 'play');
    expect(calls.single.arguments, 'sos');
  });

  test('sin la parte nativa no falla', () async {
    await expectLater(Haptics().play(HapticPattern.tick), completes);
  });

  test('un error del canal no sale de play', () async {
    final haptics = Haptics(invoke: (_, _) async => throw StateError('x'));
    await expectLater(haptics.play(HapticPattern.alert), completes);
  });

  group('Vibration', () {
    test('vibra solo si está encendida en Ajustes', () async {
      final played = <Object?>[];
      var enabled = true;
      final vibration = Vibration(
        Haptics(invoke: (_, pattern) async => played.add(pattern)),
        enabled: () => enabled,
      );

      await vibration(HapticPattern.talk);
      enabled = false;
      await vibration(HapticPattern.alert);

      expect(played, ['talk']);
    });
  });
}
