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

    test(
      'F10: con solo datos móviles (pdp_ip0, rmnet) no hay red local',
      () async {
        when(() => mockAddress.address).thenReturn('10.45.12.8');
        when(() => mockAddress.type).thenReturn(InternetAddressType.IPv4);
        when(() => mockInterface.name).thenReturn('pdp_ip0');
        when(() => mockInterface.addresses).thenReturn([mockAddress]);
        final cellular = MockNetworkInterface();
        final cellularAddress = MockInterfaceAddress();
        when(() => cellularAddress.address).thenReturn('100.80.2.1');
        when(() => cellularAddress.type).thenReturn(InternetAddressType.IPv4);
        when(() => cellular.name).thenReturn('rmnet_data0');
        when(() => cellular.addresses).thenReturn([cellularAddress]);
        when(() => mockDataSource.getInterfaces())
            .thenAnswer((_) async => [mockInterface, cellular]);

        final result = await repository.getNetworkState();

        expect(result.dataOrNull, const NetworkState.disconnected());
      },
    );

    test(
      'F10: con datos móviles, VPN y Wi-Fi toma la IP de la Wi-Fi',
      () async {
        MockNetworkInterface interface(String name, String ip) {
          final address = MockInterfaceAddress();
          when(() => address.address).thenReturn(ip);
          when(() => address.type).thenReturn(InternetAddressType.IPv4);
          final mock = MockNetworkInterface();
          when(() => mock.name).thenReturn(name);
          when(() => mock.addresses).thenReturn([address]);
          return mock;
        }

        final interfaces = [
          interface('pdp_ip0', '10.45.12.8'),
          interface('utun2', '10.8.0.2'),
          interface('en0', '192.168.1.34'),
        ];
        when(() => mockDataSource.getInterfaces())
            .thenAnswer((_) async => interfaces);

        final result = await repository.getNetworkState();

        expect(
          result.dataOrNull,
          const NetworkState.connected(
            ipAddress: '192.168.1.34',
            interfaceName: 'en0',
            isHotspot: false,
          ),
        );
      },
    );

    test(
      'F10: el punto de acceso del iPhone (bridge100) cuenta como red y como '
      'punto de acceso',
      () async {
        when(() => mockAddress.address).thenReturn('172.20.10.1');
        when(() => mockAddress.type).thenReturn(InternetAddressType.IPv4);
        when(() => mockInterface.name).thenReturn('bridge100');
        when(() => mockInterface.addresses).thenReturn([mockAddress]);
        when(() => mockDataSource.getInterfaces())
            .thenAnswer((_) async => [mockInterface]);

        final result = await repository.getNetworkState();

        expect(
          result.dataOrNull,
          const NetworkState.connected(
            ipAddress: '172.20.10.1',
            interfaceName: 'bridge100',
            isHotspot: true,
          ),
        );
      },
    );

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
