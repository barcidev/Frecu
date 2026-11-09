// Selector de la red local (F10): solo cuentan las interfaces Wi-Fi o de punto de acceso, con preferencia por los rangos privados; los datos móviles, las VPN y los túneles no son la red del grupo. Y la IPv4 que se escribe a mano se valida y se normaliza.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/core/network/lan_address.dart';
import 'package:mocktail/mocktail.dart';

class _MockInterface extends Mock implements NetworkInterface {}

class _MockAddress extends Mock implements InterfaceAddress {}

LanInterface _lan(String name, List<String> addresses) =>
    LanInterface(name: name, addresses: addresses);

void main() {
  group('lanKindOf', () {
    test('Wi-Fi y Ethernet de Android e iPhone cuentan como Wi-Fi', () {
      for (final name in ['wlan0', 'wlan1', 'en0', 'en1', 'eth0', 'mlan0']) {
        expect(lanKindOf(name), LanKind.wifi, reason: name);
      }
    });

    test('el punto de acceso de Android y el de iPhone cuentan como punto de '
        'acceso', () {
      for (final name in ['ap0', 'ap1', 'swlan0', 'softap0', 'bridge100']) {
        expect(lanKindOf(name), LanKind.hotspot, reason: name);
      }
    });

    test('datos móviles, VPN, túneles y enlaces del sistema no cuentan', () {
      for (final name in [
        'lo0',
        'lo',
        'pdp_ip0',
        'pdp_ip1',
        'rmnet0',
        'rmnet_data0',
        'rev_rmnet0',
        'ccmni0',
        'clat4',
        'v4-rmnet_data0',
        'utun0',
        'utun3',
        'ipsec0',
        'tun0',
        'ppp0',
        'awdl0',
        'llw0',
        'p2p-wlan0-0',
        'p2p0',
        'dummy0',
        'anpi0',
      ]) {
        expect(lanKindOf(name), isNull, reason: name);
      }
    });
  });

  group('selectLanAddress', () {
    test('solo con datos móviles no hay red local', () {
      expect(
        selectLanAddress([
          _lan('pdp_ip0', ['10.45.12.8']),
          _lan('rmnet_data0', ['100.80.2.1']),
        ]),
        isNull,
      );
    });

    test('sin interfaces ni direcciones no hay red local', () {
      expect(selectLanAddress(const []), isNull);
      expect(selectLanAddress([_lan('en0', const [])]), isNull);
    });

    test('con datos móviles, VPN y Wi-Fi elige la IP de la Wi-Fi', () {
      final lan = selectLanAddress([
        _lan('pdp_ip0', ['10.45.12.8']),
        _lan('utun2', ['10.8.0.2']),
        _lan('ipsec0', ['172.16.4.2']),
        _lan('en0', ['192.168.1.34']),
      ]);

      expect(
        lan,
        const LanAddress(
          address: '192.168.1.34',
          interfaceName: 'en0',
          kind: LanKind.wifi,
        ),
      );
    });

    test(
      'el punto de acceso del iPhone (bridge100) y el de Android cuentan',
      () {
        expect(
          selectLanAddress([
            _lan('pdp_ip0', ['10.45.12.8']),
            _lan('bridge100', ['172.20.10.1']),
          ]),
          const LanAddress(
            address: '172.20.10.1',
            interfaceName: 'bridge100',
            kind: LanKind.hotspot,
          ),
        );
        expect(
          selectLanAddress([
            _lan('rmnet_data1', ['100.80.2.1']),
            _lan('swlan0', ['192.168.43.1']),
          ])?.address,
          '192.168.43.1',
        );
      },
    );

    test('prefiere un rango privado a uno público o autoasignado', () {
      expect(
        selectLanAddress([
          _lan('wlan0', ['169.254.3.9']),
          _lan('eth0', ['8.8.4.4']),
          _lan('wlan1', ['10.0.0.12']),
        ])?.address,
        '10.0.0.12',
      );
      expect(
        selectLanAddress([
          _lan('wlan0', ['169.254.3.9']),
          _lan('eth0', ['100.64.0.7']),
        ])?.address,
        '100.64.0.7',
      );
      expect(
        selectLanAddress([
          _lan('en0', ['169.254.3.9']),
        ])?.address,
        '169.254.3.9',
      );
    });

    test('a igual rango prefiere el punto de acceso y luego el orden del '
        'sistema', () {
      expect(
        selectLanAddress([
          _lan('wlan0', ['192.168.1.20']),
          _lan('ap0', ['192.168.43.1']),
        ])?.interfaceName,
        'ap0',
      );
      expect(
        selectLanAddress([
          _lan('wlan0', ['192.168.1.20']),
          _lan('wlan1', ['192.168.5.20']),
        ])?.interfaceName,
        'wlan0',
      );
    });

    test(
      'ignora loopback, 0.0.0.0, multidifusión y direcciones mal formadas',
      () {
        expect(
          selectLanAddress([
            _lan('en0', ['127.0.0.1', '0.0.0.0', '224.0.0.251', 'fe80::1']),
          ]),
          isNull,
        );
      },
    );

    test(
      'LanInterface.fromIo toma solo las IPv4 de una interfaz de dart:io',
      () {
        InterfaceAddress address(String text, InternetAddressType type) {
          final mock = _MockAddress();
          when(() => mock.address).thenReturn(text);
          when(() => mock.type).thenReturn(type);
          return mock;
        }

        final addresses = [
          address('fe80::1c2a', InternetAddressType.IPv6),
          address('192.168.43.27', InternetAddressType.IPv4),
        ];
        final interface = _MockInterface();
        when(() => interface.name).thenReturn('wlan0');
        when(() => interface.addresses).thenReturn(addresses);

        final lan = LanInterface.fromIo(interface);

        expect(lan.name, 'wlan0');
        expect(lan.addresses, ['192.168.43.27']);
      },
    );
  });

  group('normalizeIpv4', () {
    test('acepta IPv4 de anfitrión y las escribe en su forma corriente', () {
      expect(normalizeIpv4('192.168.43.1'), '192.168.43.1');
      expect(normalizeIpv4('  10.0.0.2 '), '10.0.0.2');
      expect(normalizeIpv4('192.168.043.001'), '192.168.43.1');
      expect(normalizeIpv4('172.20.10.1'), '172.20.10.1');
      expect(normalizeIpv4('223.255.255.254'), '223.255.255.254');
    });

    test('rechaza lo que no es una IPv4 de anfitrión', () {
      for (final text in [
        '',
        '192.168.43',
        '192.168.43.1.5',
        '192.168.43.256',
        '192.168..1',
        '192.168.43.a',
        '192,168,43,1',
        '-1.2.3.4',
        '1.2.3.+4',
        '1234.1.1.1',
        '0.0.0.0',
        '0.1.2.3',
        '127.0.0.1',
        '224.0.0.251',
        '255.255.255.255',
        'frecu.local',
        'fe80::1',
      ]) {
        expect(normalizeIpv4(text), isNull, reason: text);
      }
    });
  });
}
