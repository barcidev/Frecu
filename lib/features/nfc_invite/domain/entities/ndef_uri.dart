import 'dart:convert';

/// Registro URI de NDEF (tipo bien conocido `U`): un byte con el prefijo
/// abreviado y el resto de la URI en UTF-8.
abstract final class NdefUri {
  /// Tipo del registro: `U`.
  static const List<int> type = [0x55];

  /// Prefijos abreviados del estándar (NFC Forum URI RTD), por código.
  static const List<String> _prefixes = [
    '',
    'http://www.',
    'https://www.',
    'http://',
    'https://',
    'tel:',
    'mailto:',
    'ftp://anonymous:anonymous@',
    'ftp://ftp.',
    'ftps://',
    'sftp://',
    'smb://',
    'nfs://',
    'ftp://',
    'dav://',
    'news:',
    'telnet://',
    'imap:',
    'rtsp://',
    'urn:',
    'pop:',
    'sip:',
    'sips:',
    'tftp:',
    'btspp://',
    'btl2cap://',
    'btgoep://',
    'tcpobex://',
    'irdaobex://',
    'file://',
    'urn:epc:id:',
    'urn:epc:tag:',
    'urn:epc:pat:',
    'urn:epc:raw:',
    'urn:epc:',
    'urn:nfc:',
  ];

  /// Contenido del registro de [uri], sin abreviar (las de Frecu no tienen
  /// prefijo abreviado).
  static List<int> payload(String uri) => [0x00, ...utf8.encode(uri)];

  /// La URI de un registro de tipo [recordType] con [recordPayload], o nula
  /// si no es un registro URI o no se entiende.
  static String? parse(List<int> recordType, List<int> recordPayload) {
    if (recordType.length != 1 || recordType.first != type.first) return null;
    if (recordPayload.isEmpty) return null;
    final code = recordPayload.first;
    if (code >= _prefixes.length) return null;
    try {
      return _prefixes[code] + utf8.decode(recordPayload.sublist(1));
    } on FormatException {
      return null;
    }
  }
}
