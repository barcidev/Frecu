import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/features/room/data/datasources/foreground_service_datasource.dart';

void main() {
  group('ForegroundServiceDataSource', () {
    test('AC1: init, startService, updateNotification, and stopService manage service state', () async {
      final dataSource = ForegroundServiceDataSource();
      await dataSource.init();
      expect(dataSource.isRunning, isFalse);

      await dataSource.startService(
        roomName: 'Frecu Alpha',
        status: 'Conectado',
      );
      expect(dataSource.isRunning, isTrue);

      await dataSource.updateNotification(
        roomName: 'Frecu Alpha',
        status: 'Reconectando...',
      );
      expect(dataSource.isRunning, isTrue);

      await dataSource.stopService();
      expect(dataSource.isRunning, isFalse);
    });
  });
}
