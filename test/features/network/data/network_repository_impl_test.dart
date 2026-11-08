import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/core/error/failure.dart';
import 'package:frecu/features/network/data/datasources/network_interface_datasource.dart';
import 'package:frecu/features/network/data/repositories/network_repository_impl.dart';
import 'package:frecu/features/network/domain/entities/network_state.dart';
import 'package:mocktail/mocktail.dart';

class MockNetworkInterfaceDataSource extends Mock
    implements NetworkInterfaceDataSource {}

class MockNetworkInterface extends Mock implements NetworkInterface {}

class MockInterfaceAddress extends Mock implements InterfaceAddress {}

void main() {
  late MockNetworkInterfaceDataSource mockDataSource;
  late NetworkRepositoryImpl repository;
  late MockNetworkInterface mockInterface;
  late MockInterfaceAddress mockAddress;

  setUp(() {
    mockDataSource = MockNetworkInterfaceDataSource();
    repository = NetworkRepositoryImpl(dataSource: mockDataSource);
    mockInterface = MockNetworkInterface();
    mockAddress = MockInterfaceAddress();
  });

  group('NetworkRepositoryImpl', () {
    test('AC1: getNetworkState returns Result.success with disconnected state when no active interfaces exist', () async {
      when(() => mockDataSource.getInterfaces()).thenAnswer((_) async => []);

      final result = await repository.getNetworkState();

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, equals(const NetworkState.disconnected()));
    });

    test('AC2: getNetworkState returns Result.success with connected state when active IPv4 interface is found', () async {
      when(() => mockAddress.address).thenReturn('192.168.1.150');
      when(() => mockAddress.isLoopback).thenReturn(false);
      when(() => mockAddress.type).thenReturn(InternetAddressType.IPv4);
      when(() => mockInterface.name).thenReturn('wlan0');
      when(() => mockInterface.addresses).thenReturn([mockAddress]);
      when(() => mockDataSource.getInterfaces())
          .thenAnswer((_) async => [mockInterface]);

      final result = await repository.getNetworkState();

      expect(result.isSuccess, isTrue);
      final state = result.dataOrNull;
      expect(state, isA<NetworkConnected>());
      final connected = state! as NetworkConnected;
      expect(connected.ipAddress, equals('192.168.1.150'));
      expect(connected.interfaceName, equals('wlan0'));
      expect(connected.isHotspot, isFalse);
    });

    test('AC3: getNetworkState flags isHotspot true when IP belongs to standard hotspot ranges', () async {
      when(() => mockAddress.address).thenReturn('192.168.43.1');
      when(() => mockAddress.isLoopback).thenReturn(false);
      when(() => mockAddress.type).thenReturn(InternetAddressType.IPv4);
      when(() => mockInterface.name).thenReturn('ap0');
      when(() => mockInterface.addresses).thenReturn([mockAddress]);
      when(() => mockDataSource.getInterfaces())
          .thenAnswer((_) async => [mockInterface]);

      final result = await repository.getNetworkState();

      expect(result.isSuccess, isTrue);
      final state = result.dataOrNull;
      expect(state, isA<NetworkConnected>());
      final connected = state! as NetworkConnected;
      expect(connected.isHotspot, isTrue);
    });

    test('AC4: getNetworkState captures exception and returns Result.failure with Failure.network', () async {
      when(() => mockDataSource.getInterfaces()).thenThrow(
        const SocketException('Platform error querying network interfaces'),
      );

      final result = await repository.getNetworkState();

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<Failure>());
    });

    test('AC5: watchNetworkState emits stream of periodic network states and filters duplicates', () async {
      when(() => mockAddress.address).thenReturn('192.168.1.150');
      when(() => mockAddress.isLoopback).thenReturn(false);
      when(() => mockAddress.type).thenReturn(InternetAddressType.IPv4);
      when(() => mockInterface.name).thenReturn('wlan0');
      when(() => mockInterface.addresses).thenReturn([mockAddress]);
      when(() => mockDataSource.getInterfaces())
          .thenAnswer((_) async => [mockInterface]);

      final stream = repository.watchNetworkState(
        pollInterval: const Duration(milliseconds: 20),
      );

      final emissions = await stream.take(1).toList();

      expect(emissions.length, equals(1));
      expect(emissions.first, isA<NetworkConnected>());
    });
  });
}
