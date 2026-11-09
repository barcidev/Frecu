// Red de Frecu: con la red de la frecu al aire, la IPv4 de la invitación es la de su interfaz aunque el teléfono siga en otra Wi-Fi; sin esa interfaz (o sin IPv4 válida en ella) se elige como siempre. El punto de acceso de doble banda que Android arma como puente (`ap_br_wlan2`) cuenta como punto de acceso.
import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/core/network/lan_address.dart';

LanInterface _lan(String name, List<String> addresses) =>
    LanInterface(name: name, addresses: addresses);

void main() {
  final home = _lan('wlan0', ['192.168.1.34']);
  final frecu = _lan('wlan1', ['192.168.62.1']);

  test('sin preferencia se elige como siempre', () {
    expect(
      selectLanAddress([home, frecu]),
      const LanAddress(
        address: '192.168.1.34',
        interfaceName: 'wlan0',
        kind: LanKind.wifi,
      ),
    );
  });

  test('la interfaz de la red de la frecu gana aunque haya otra Wi-Fi', () {
    expect(
      selectLanAddress([home, frecu], prefer: 'wlan1'),
      const LanAddress(
        address: '192.168.62.1',
        interfaceName: 'wlan1',
        kind: LanKind.wifi,
      ),
    );
  });

  test('una interfaz preferida con nombre desconocido cuenta como punto de '
      'acceso', () {
    expect(
      selectLanAddress([
        home,
        _lan('hs7', ['10.20.30.1']),
      ], prefer: 'hs7'),
      const LanAddress(
        address: '10.20.30.1',
        interfaceName: 'hs7',
        kind: LanKind.hotspot,
      ),
    );
  });

  test(
    'sin esa interfaz, o sin IPv4 válida en ella, se elige como siempre',
    () {
      expect(
        selectLanAddress([home, frecu], prefer: 'ap0')?.address,
        '192.168.1.34',
      );
      expect(
        selectLanAddress([
          home,
          _lan('ap0', ['0.0.0.0', 'fe80::1']),
        ], prefer: 'ap0')?.address,
        '192.168.1.34',
      );
    },
  );

  test('datos móviles o VPN no ganan aunque se prefieran', () {
    expect(
      selectLanAddress([
        home,
        _lan('rmnet_data0', ['10.1.2.3']),
      ], prefer: 'rmnet_data0')?.address,
      '192.168.1.34',
    );
  });

  test('el punto de acceso de doble banda cuenta como punto de acceso', () {
    for (final name in ['ap_br_wlan2', 'ap_br_softap0', 'ap_br_swlan1']) {
      expect(lanKindOf(name), LanKind.hotspot, reason: name);
    }
  });
}
