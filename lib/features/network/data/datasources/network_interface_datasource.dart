import 'dart:io';

/// Datasource responsable de consultar las interfaces de red locales físicas o virtuales.
class NetworkInterfaceDataSource {
  /// Crea una instancia inyectando opcionalmente la función lister de interfaces.
  NetworkInterfaceDataSource({
    Future<List<NetworkInterface>> Function()? listInterfaces,
  }) : _listInterfaces = listInterfaces ?? _defaultListInterfaces;

  final Future<List<NetworkInterface>> Function() _listInterfaces;

  static Future<List<NetworkInterface>> _defaultListInterfaces() {
    return NetworkInterface.list(type: InternetAddressType.IPv4);
  }

  /// Retorna la lista de interfaces de red activas no loopback de tipo IPv4.
  Future<List<NetworkInterface>> getInterfaces() async {
    return _listInterfaces();
  }
}
