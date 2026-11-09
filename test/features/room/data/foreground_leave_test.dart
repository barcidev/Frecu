import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/features/room/data/datasources/foreground_service_datasource.dart';

void main() {
  test(
    '«Salir» de la notificación solo cuenta con el servicio activo',
    () async {
      final service = ForegroundServiceDataSource();
      final taps = <int>[];
      final sub = service.leaveRequests.listen(taps.add);

      service.handleTaskData(kLeaveNotificationButton);
      await service.startService(
        roomName: 'Ruta 40',
        status: ForegroundStatus.connected,
      );
      service
        ..handleTaskData('otro')
        ..handleTaskData(kLeaveNotificationButton)
        ..handleTaskData(kLeaveNotificationButton);
      await service.stopService();
      service.handleTaskData(kLeaveNotificationButton);
      await Future<void>.delayed(Duration.zero);

      expect(taps, [1, 2]);
      await sub.cancel();
      await service.dispose();
    },
  );

  test('el botón «Salir» lleva su texto y sin texto no hay botón', () {
    const texts = ForegroundNotificationTexts(
      channelName: 'c',
      channelDescription: 'd',
      title: 't',
      connected: _line,
      reconnecting: _line,
      leave: 'Salir de la frecu',
    );
    expect(texts.leave, 'Salir de la frecu');
    expect(ForegroundNotificationTexts.empty.leave, isEmpty);
  });
}

String _line(String room) => room;
