import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/core/error/failure.dart';
import 'package:frecu/features/permissions/data/datasources/permission_datasource.dart';
import 'package:frecu/features/permissions/data/repositories/permission_repository_impl.dart';
import 'package:frecu/features/permissions/domain/entities/app_permission.dart';
import 'package:mocktail/mocktail.dart';
import 'package:permission_handler/permission_handler.dart';

class MockPermissionDataSource extends Mock implements PermissionDataSource {}

void main() {
  late MockPermissionDataSource mockDataSource;
  late PermissionRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(Permission.microphone);
  });

  setUp(() {
    mockDataSource = MockPermissionDataSource();
    repository = PermissionRepositoryImpl(dataSource: mockDataSource);
  });

  group('PermissionRepositoryImpl', () {
    test('AC1: checkStatus maps AppPermission to Permission and returns mapped AppPermissionStatus', () async {
      when(() => mockDataSource.getStatus(Permission.microphone))
          .thenAnswer((_) async => PermissionStatus.granted);

      final result = await repository.checkStatus(AppPermission.microphone);

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, AppPermissionStatus.granted);
      verify(() => mockDataSource.getStatus(Permission.microphone)).called(1);
    });

    test('AC1: request maps AppPermission to Permission and returns mapped AppPermissionStatus', () async {
      when(() => mockDataSource.request(Permission.camera))
          .thenAnswer((_) async => PermissionStatus.permanentlyDenied);

      final result = await repository.request(AppPermission.camera);

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, AppPermissionStatus.permanentlyDenied);
      verify(() => mockDataSource.request(Permission.camera)).called(1);
    });

    test('AC2: checkStatus returns Failure.unexpected when datasource throws', () async {
      when(() => mockDataSource.getStatus(any()))
          .thenThrow(Exception('platform error'));

      final result = await repository.checkStatus(AppPermission.microphone);

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<Failure>());
    });

    test('AC2: request returns Failure.unexpected when datasource throws', () async {
      when(() => mockDataSource.request(any()))
          .thenThrow(Exception('platform error'));

      final result = await repository.request(AppPermission.notification);

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<Failure>());
    });

    test('AC3: requestAll requests each permission and returns mapped status map', () async {
      when(() => mockDataSource.request(Permission.microphone))
          .thenAnswer((_) async => PermissionStatus.granted);
      when(() => mockDataSource.request(Permission.bluetoothConnect))
          .thenAnswer((_) async => PermissionStatus.denied);

      final result = await repository.requestAll([
        AppPermission.microphone,
        AppPermission.bluetoothConnect,
      ]);

      expect(result.isSuccess, isTrue);
      final map = result.dataOrNull!;
      expect(map[AppPermission.microphone], AppPermissionStatus.granted);
      expect(map[AppPermission.bluetoothConnect], AppPermissionStatus.denied);
    });

    test('AC3: requestAll returns failure when an exception occurs', () async {
      when(() => mockDataSource.request(any()))
          .thenThrow(Exception('platform error'));

      final result = await repository.requestAll([AppPermission.microphone]);

      expect(result.isFailure, isTrue);
    });

    test('AC4: openAppSettings delegates to datasource and returns bool result', () async {
      when(() => mockDataSource.openSettings()).thenAnswer((_) async => true);

      final result = await repository.openAppSettings();

      expect(result, isTrue);
      verify(() => mockDataSource.openSettings()).called(1);
    });
  });
}
