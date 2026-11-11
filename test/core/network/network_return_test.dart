// AC1: CUANDO durante la espera aparece una dirección de red que no estaba en la consulta anterior ENTONCES la espera termina antes de su plazo e indica que vino por la red.
// AC2: CUANDO durante la espera solo desaparecen direcciones o nada cambia ENTONCES la espera dura su plazo completo; y si quien espera se cancela, termina sin seguir consultando.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/core/network/network_return.dart';

class _Interface implements NetworkInterface {
  _Interface(this.name, List<String> addresses)
    : addresses = [for (final a in addresses) _Address(a)];

  @override
  final String name;

  @override
  int get index => 0;

  @override
  final List<InterfaceAddress> addresses;
}

class _Address implements InterfaceAddress {
  _Address(String text) : _ip = InternetAddress(text);

  final InternetAddress _ip;

  @override
  String get address => _ip.address;

  @override
  bool get isLoopback => _ip.isLoopback;

  @override
  InternetAddressType get type => _ip.type;

  @override
  int get prefixLength => 24;

  @override
  InternetAddress? get broadcast => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  var current = <NetworkInterface>[];
  var polls = 0;

  NetworkReturnWatcher watcher() => NetworkReturnWatcher(
    interfaces: () async {
      polls++;
      return current;
    },
    pollInterval: const Duration(milliseconds: 10),
  );

  setUp(() {
    current = [];
    polls = 0;
  });

  test(
    'AC1: una dirección nueva despierta la espera antes de su plazo',
    () async {
      final clock = Stopwatch()..start();
      final waiting = watcher().wait(const Duration(seconds: 5));
      await Future<void>.delayed(const Duration(milliseconds: 40));
      current = [
        _Interface('wlan0', ['192.168.43.27']),
      ];

      expect(await waiting, isTrue);
      expect(clock.elapsed, lessThan(const Duration(seconds: 1)));
    },
  );

  test('AC1: la misma dirección que reaparece también despierta', () async {
    current = [
      _Interface('wlan0', ['192.168.43.27']),
    ];
    final w = watcher();
    final baseline = await w.addresses();
    final waiting = w.wait(const Duration(seconds: 5), baseline: baseline);
    await Future<void>.delayed(const Duration(milliseconds: 40));
    current = [];
    await Future<void>.delayed(const Duration(milliseconds: 40));
    current = [
      _Interface('wlan0', ['192.168.43.27']),
    ];

    expect(await waiting, isTrue);
  });

  test('AC1: loopback no cuenta como red', () async {
    final w = watcher();
    final waiting = w.wait(const Duration(milliseconds: 150));
    await Future<void>.delayed(const Duration(milliseconds: 30));
    current = [
      _Interface('lo0', ['127.0.0.1', '::1']),
    ];

    expect(await waiting, isFalse);
  });

  test(
    'AC2: si solo desaparecen direcciones espera el plazo completo',
    () async {
      current = [
        _Interface('wlan0', ['192.168.43.27']),
        _Interface('pdp_ip0', ['10.20.30.40']),
      ];
      final clock = Stopwatch()..start();
      final waiting = watcher().wait(const Duration(milliseconds: 150));
      await Future<void>.delayed(const Duration(milliseconds: 40));
      current = [
        _Interface('pdp_ip0', ['10.20.30.40']),
      ];

      expect(await waiting, isFalse);
      expect(
        clock.elapsed,
        greaterThanOrEqualTo(const Duration(milliseconds: 140)),
      );
    },
  );

  test('AC2: si se cancela termina y deja de consultar', () async {
    var cancelled = false;
    final waiting = watcher().wait(
      const Duration(seconds: 5),
      cancelled: () => cancelled,
    );
    await Future<void>.delayed(const Duration(milliseconds: 30));
    cancelled = true;

    expect(await waiting, isFalse);
    final after = polls;
    await Future<void>.delayed(const Duration(milliseconds: 60));
    expect(polls, after);
  });

  test('AC2: un fallo al consultar no despierta ni rompe la espera', () async {
    final w = NetworkReturnWatcher(
      interfaces: () async => throw const SocketException('no'),
      pollInterval: const Duration(milliseconds: 10),
    );

    expect(await w.wait(const Duration(milliseconds: 80)), isFalse);
  });
}
