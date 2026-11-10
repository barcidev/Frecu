import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/features/room/data/datasources/foreground_service_datasource.dart';

const _texts = ForegroundNotificationTexts(
  channelName: 'Frecu en segundo plano',
  channelDescription: 'Mantiene la conexión',
  title: 'Frecu activa',
  connected: 'Conectado',
  reconnecting: 'Reconectando…',
  leave: 'Salir de la frecu',
);

RoomNotificationContent _card(String subtitle) => RoomNotificationContent(
  title: 'Ruta 40',
  subtitle: subtitle,
  note: 'Sol4',
  accent: 0xFFC4E05C,
  art: Uint8List.fromList([1, 2]),
  buttons: const [
    RoomNotificationButton(
      RoomNotificationAction.mic,
      RoomNotificationIcon.mic,
      'Hablar',
    ),
  ],
);

void main() {
  group('ForegroundServiceDataSource', () {
    late List<(String, Object?)> calls;
    late ForegroundServiceDataSource service;

    setUp(() {
      calls = [];
      service = ForegroundServiceDataSource(
        texts: () => _texts,
        invoke: (method, args) async {
          calls.add((method, args));
          return null;
        },
      );
    });

    Map<String, Object?> args(int i) => calls[i].$2! as Map<String, Object?>;

    test('arranca con el canal y el contenido de arranque, y para', () async {
      await service.startService(
        roomName: 'Ruta 40',
        status: ForegroundStatus.connected,
      );
      expect(service.isRunning, isTrue);
      expect(calls.single.$1, 'start');
      expect(args(0)['channelName'], 'Frecu en segundo plano');
      expect(args(0)['location'], isFalse);
      final content = args(0)['content']! as Map<String, Object?>;
      expect(content['title'], 'Ruta 40');
      expect(content['subtitle'], 'Conectado');

      await service.updateNotification(
        roomName: 'Ruta 40',
        status: ForegroundStatus.reconnecting,
      );
      expect(calls.last.$1, 'update');
      expect(args(1)['subtitle'], 'Reconectando…');
      expect(args(1)['accent'], 0xFFFFB547);

      await service.stopService();
      expect(service.isRunning, isFalse);
      expect(calls.last.$1, 'stop');
    });

    test('el contenido de la app manda sobre el de arranque, y no pasa a la '
        'frecu siguiente', () async {
      // Fuera de la frecu no se guarda.
      await service.show(_card('Fuera'));
      expect(calls, isEmpty);

      await service.startService(
        roomName: 'Ruta 40',
        status: ForegroundStatus.connected,
      );
      await service.show(_card('Ana · hablando'));
      expect(calls.last.$1, 'update');
      expect(args(1)['subtitle'], 'Ana · hablando');
      expect(args(1)['note'], 'Sol4');
      expect(args(1)['art'], [1, 2]);
      expect(args(1)['buttons'], [
        {'id': 'mic', 'icon': 'mic', 'label': 'Hablar'},
      ]);

      // Reconectar o volver a unirse no pisa lo que mandó la app.
      await service.updateNotification(
        roomName: 'Ruta 40',
        status: ForegroundStatus.reconnecting,
      );
      await service.startService(
        roomName: 'Ruta 40',
        status: ForegroundStatus.connected,
      );
      expect(calls.length, 2);

      await service.stopService();
      await service.startService(
        roomName: 'Ruta 41',
        status: ForegroundStatus.connected,
      );
      final next = args(3)['content']! as Map<String, Object?>;
      expect(next['title'], 'Ruta 41');
      expect(next['subtitle'], 'Conectado');
    });

    test('la ubicación suma su tipo al servicio solo cuando cambia', () async {
      await service.setLocationActive(active: true);
      expect(calls, isEmpty);
      await service.startService(
        roomName: 'Ruta 40',
        status: ForegroundStatus.connected,
      );
      expect(args(0)['location'], isTrue);
      await service.setLocationActive(active: true);
      await service.setLocationActive(active: false);
      expect(calls.last, ('setLocation', false));
      expect(calls.length, 2);
    });

    test('sin servicio nativo (pruebas, iOS) no llama a nadie', () async {
      final quiet = ForegroundServiceDataSource();
      expect(quiet.isAvailable, isFalse);
      await quiet.init();
      await quiet.startService(
        roomName: 'Ruta 40',
        status: ForegroundStatus.connected,
      );
      expect(quiet.isRunning, isTrue);
      await quiet.stopService();
      expect(quiet.isRunning, isFalse);
      await quiet.dispose();
    });
  });
}
