// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wifi_credentials.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_WifiCredentials _$WifiCredentialsFromJson(Map<String, dynamic> json) =>
    _WifiCredentials(
      ssid: json['ssid'] as String,
      passphrase: json['passphrase'] as String?,
    );

Map<String, dynamic> _$WifiCredentialsToJson(_WifiCredentials instance) =>
    <String, dynamic>{'ssid': instance.ssid, 'passphrase': instance.passphrase};
