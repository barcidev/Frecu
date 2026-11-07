import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/features/network/domain/entities/network_state.dart';

void main() {
  group('NetworkState', () {
    test('AC1: NetworkState.disconnected instantiates disconnected state', () {
      const state = NetworkState.disconnected();

      expect(state, isA<NetworkDisconnected>());
      expect(state.isConnected, isFalse);
    });

    test('AC2: NetworkState.connected holds valid IP, interface name and hotspot flag', () {
      const state = NetworkState.connected(
        ipAddress: '192.168.1.100',
        interfaceName: 'wlan0',
        isHotspot: false,
      );

      expect(state, isA<NetworkConnected>());
      expect(state.isConnected, isTrue);
      expect((state as NetworkConnected).ipAddress, equals('192.168.1.100'));
      expect(state.interfaceName, equals('wlan0'));
      expect(state.isHotspot, isFalse);
    });

    test('AC3: NetworkState.connected preserves isHotspot true for hotspot configurations', () {
      const state = NetworkState.connected(
        ipAddress: '192.168.43.1',
        interfaceName: 'ap0',
        isHotspot: true,
      );

      expect(state.isHotspot, isTrue);
      expect(state.isConnected, isTrue);
    });
  });
}
