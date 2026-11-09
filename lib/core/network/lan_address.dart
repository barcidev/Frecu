/// Red local de Frecu: qué interfaz y qué IPv4 cuentan como la red del
/// grupo (Wi-Fi o punto de acceso) y cómo se escribe una IPv4.
///
/// Las funciones son puras: reciben los nombres y las direcciones de las
/// interfaces ([LanInterface]) y no consultan el sistema. Las capas `data`
/// pasan sus `NetworkInterface` con [LanInterface.fromIo].
library;

import 'dart:io';

import 'package:flutter/foundation.dart';

/// Tipo de interfaz que cuenta como red local.
enum LanKind {
  /// Cliente Wi-Fi (o Ethernet): `wlan0`, `en0`, `eth0`…
  wifi,

  /// Punto de acceso de este teléfono: `ap0`, `swlan0`, `softap0` en
  /// Android; `bridge100` en iPhone.
  hotspot,
}

/// Una interfaz de red con sus direcciones IPv4 en texto.
@immutable
class LanInterface {
  /// Crea la interfaz [name] con sus [addresses] IPv4.
  const LanInterface({required this.name, required this.addresses});

  /// Las direcciones IPv4 de [interface] (`dart:io`).
  factory LanInterface.fromIo(NetworkInterface interface) => LanInterface(
    name: interface.name,
    addresses: [
      for (final address in interface.addresses)
        if (address.type == InternetAddressType.IPv4) address.address,
    ],
  );

  /// Nombre del sistema (`wlan0`, `en0`, `pdp_ip0`…).
  final String name;

  /// Direcciones IPv4, como `192.168.43.27`.
  final List<String> addresses;
}

/// IPv4 de la red local elegida y la interfaz en la que está.
@immutable
class LanAddress {
  /// Crea la dirección [address] de [interfaceName].
  const LanAddress({
    required this.address,
    required this.interfaceName,
    required this.kind,
  });

  /// IPv4, como `192.168.43.27`.
  final String address;

  /// Interfaz en la que está.
  final String interfaceName;

  /// Wi-Fi o punto de acceso.
  final LanKind kind;

  @override
  bool operator ==(Object other) =>
      other is LanAddress &&
      other.address == address &&
      other.interfaceName == interfaceName &&
      other.kind == kind;

  @override
  int get hashCode => Object.hash(address, interfaceName, kind);

  @override
  String toString() => 'LanAddress($address, $interfaceName, ${kind.name})';
}

/// Datos móviles, VPN, túneles y enlaces del sistema: nunca son la red del
/// grupo aunque tengan IPv4.
final RegExp _excluded = RegExp(
  '^(lo|pdp_ip|rmnet|rev_rmnet|ccmni|clat|v4-|seth|wwan|radio|utun|ipsec|'
  'tun|tap|ppp|awdl|llw|p2p|dummy|ifb|sit|ip6)',
  caseSensitive: false,
);

/// Punto de acceso de este teléfono.
final RegExp _hotspot = RegExp(
  r'^(ap|softap|swlan|bridge)\d+$',
  caseSensitive: false,
);

/// Cliente Wi-Fi (y Ethernet, que también es red local).
final RegExp _wifi = RegExp(
  r'^(wlan|en|eth|mlan|wifi)\d+$',
  caseSensitive: false,
);

/// Tipo de la interfaz [name], o nulo si no cuenta como red local.
LanKind? lanKindOf(String name) {
  if (_excluded.hasMatch(name)) return null;
  if (_hotspot.hasMatch(name)) return LanKind.hotspot;
  if (_wifi.hasMatch(name)) return LanKind.wifi;
  return null;
}

/// Elige la IPv4 de la red local entre las [interfaces] del teléfono, o nulo
/// si solo hay datos móviles, VPN o ninguna red.
///
/// Solo cuentan las interfaces Wi-Fi y de punto de acceso ([lanKindOf]).
/// Prefiere los rangos privados (10/8, 172.16/12, 192.168/16) sobre los
/// demás y deja las autoasignadas (169.254/16) para el final; a igual rango,
/// el punto de acceso (es la red a la que se unen los demás) y luego el
/// orden del sistema.
LanAddress? selectLanAddress(Iterable<LanInterface> interfaces) {
  LanAddress? best;
  var bestScore = -1;
  for (final interface in interfaces) {
    final kind = lanKindOf(interface.name);
    if (kind == null) continue;
    for (final text in interface.addresses) {
      final octets = _unicastOctets(text);
      if (octets == null) continue;
      final score = _rangeScore(octets) * 2 + (kind == LanKind.hotspot ? 1 : 0);
      if (score > bestScore) {
        bestScore = score;
        best = LanAddress(
          address: octets.join('.'),
          interfaceName: interface.name,
          kind: kind,
        );
      }
    }
  }
  return best;
}

/// La IPv4 escrita en [text] en su forma corriente (sin espacios ni ceros a
/// la izquierda), o nulo si no es una dirección de anfitrión válida: cuatro
/// números de 0 a 255 separados por puntos, el primero de 1 a 223 y sin ser
/// loopback (127/8).
String? normalizeIpv4(String text) => _unicastOctets(text.trim())?.join('.');

/// Los cuatro números de una IPv4 de otro anfitrión (no `0.x`, ni loopback,
/// ni multidifusión), o nulo.
List<int>? _unicastOctets(String text) {
  final parts = text.split('.');
  if (parts.length != 4) return null;
  final octets = <int>[];
  for (final part in parts) {
    if (part.isEmpty || part.length > 3) return null;
    if (part.codeUnits.any((unit) => unit < 0x30 || unit > 0x39)) return null;
    final value = int.parse(part);
    if (value > 255) return null;
    octets.add(value);
  }
  final first = octets.first;
  if (first == 0 || first == 127 || first >= 224) return null;
  return octets;
}

/// 2 si es privada, 0 si es autoasignada (169.254/16) y 1 en lo demás.
int _rangeScore(List<int> octets) {
  final a = octets[0];
  final b = octets[1];
  if (a == 169 && b == 254) return 0;
  final private =
      a == 10 || (a == 172 && b >= 16 && b <= 31) || (a == 192 && b == 168);
  return private ? 2 : 1;
}
