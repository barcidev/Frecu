import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/features/room/data/datasources/foreground_service_datasource.dart';

void main() {
  test('«Salir» de la tarjeta solo cuenta con el servicio activo', () async {
    final service = ForegroundServiceDataSource(invoke: (_, _) async => null);
    final taps = <int>[];
    final sub = service.leaveRequests.listen(taps.add);

    service.handleAction('leave');
    await service.startService(
      roomName: 'Ruta 40',
      status: ForegroundStatus.connected,
    );
    service
      ..handleAction('otro')
      ..handleAction('leave')
      ..handleAction('leave');
    await service.stopService();
    service.handleAction('leave');
    await Future<void>.delayed(Duration.zero);

    expect(taps, [1, 2]);
    await sub.cancel();
    await service.dispose();
  });

  test('los demás botones llegan por actions, solo en la frecu', () async {
    final service = ForegroundServiceDataSource(invoke: (_, _) async => null);
    final actions = <RoomNotificationAction>[];
    final sub = service.actions.listen(actions.add);

    service.handleAction('mic');
    await service.startService(
      roomName: 'Ruta 40',
      status: ForegroundStatus.connected,
    );
    service
      ..handleAction('mic')
      ..handleAction('route')
      ..handleAction('sosGo')
      ..handleAction('sosAck')
      ..handleAction('invite')
      ..handleAction('leave');
    await Future<void>.delayed(Duration.zero);

    expect(actions, [
      RoomNotificationAction.mic,
      RoomNotificationAction.route,
      RoomNotificationAction.sosGo,
      RoomNotificationAction.sosAck,
      RoomNotificationAction.invite,
    ]);
    await sub.cancel();
    await service.dispose();
  });

  test('el botón «Salir» lleva su texto y sin texto no hay botón', () async {
    final calls = <(String, Object?)>[];
    Future<Object?> invoke(String method, Object? args) async {
      calls.add((method, args));
      return null;
    }

    const texts = ForegroundNotificationTexts(
      channelName: 'c',
      channelDescription: 'd',
      title: 'Frecu activa',
      connected: 'Conectado',
      reconnecting: 'Reconectando…',
      leave: 'Salir de la frecu',
    );
    await ForegroundServiceDataSource(
      texts: () => texts,
      invoke: invoke,
    ).startService(roomName: '', status: ForegroundStatus.connected);
    final content =
        (calls.single.$2! as Map<String, Object?>)['content']!
            as Map<String, Object?>;
    expect(content['title'], 'Frecu activa');
    expect(content['subtitle'], 'Conectado');
    expect(content['buttons'], [
      {'id': 'leave', 'icon': 'exit', 'label': 'Salir de la frecu'},
    ]);

    calls.clear();
    await ForegroundServiceDataSource(invoke: invoke)
        .startService(roomName: 'Ruta 40', status: ForegroundStatus.connected);
    final empty =
        (calls.single.$2! as Map<String, Object?>)['content']!
            as Map<String, Object?>;
    expect(empty['buttons'], isEmpty);
  });
}
