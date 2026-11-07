import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/features/network/data/datasources/network_interface_datasource.dart';
import 'package:mocktail/mocktail.dart';

class MockNetworkInterface extends Mock implements NetworkInterface {}

class MockInterfaceAddress extends Mock implements InterfaceAddress {}

void main() {
  late MockNetworkInterface mockInterface;
  late MockInterfaceAddress mockAddress;

  setUp(() {
    mockInterface = MockNetworkInterface();
    mockAddress = MockInterfaceAddress();
  });

  group('NetworkInterfaceDataSource', () {
    test('AC1: getInterfaces returns empty list when no non-loopback interfaces available', () async {
      final dataSource = NetworkInterfaceDataSource(
        listInterfaces: () async => <NetworkInterface>[],
      );

      final result = await dataSource.getInterfaces();

      expect(result, isEmpty);
    });

    test('AC2: getInterfaces returns active non-loopback interfaces from injected lister', () async {
      when(() => mockAddress.address).thenReturn('192.168.1.45');
      when(() => mockAddress.isLoopback).thenReturn(false);
      when(() => mockAddress.type).thenReturn(InternetAddressType.IPv4);
      when(() => mockInterface.name).thenReturn('wlan0');
      when(() => mockInterface.addresses).thenReturn([mockAddress]);

      final dataSource = NetworkInterfaceDataSource(
        listInterfaces: () async => [mockInterface],
      );

      final result = await dataSource.getInterfaces();

      expect(result.length, equals(1));
      expect(result.first.name, equals('wlan0'));
      expect(result.first.addresses.first.address, equals('192.168.1.45'));
    });

    test(
      'AC4: getInterfaces rethrows exception when interface listing fails',
      () async {
        final dataSource = NetworkInterfaceDataSource(
          listInterfaces: () =>
              throw const SocketException('Platform network failure'),
        );

        expect(dataSource.getInterfaces, throwsA(isA<SocketException>()));
      },
    );
  });
}
