// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'package:auto_route/auto_route.dart' as _i8;
import 'package:flutter/material.dart' as _i9;
import 'package:frecu/features/lobby/presentation/pages/create_room_page.dart'
    as _i1;
import 'package:frecu/features/lobby/presentation/pages/lobby_page.dart' as _i3;
import 'package:frecu/features/lobby/presentation/pages/scan_qr_page.dart'
    as _i6;
import 'package:frecu/features/permissions/presentation/pages/permissions_page.dart'
    as _i4;
import 'package:frecu/features/room/presentation/pages/room_page.dart' as _i5;
import 'package:frecu/features/settings/presentation/pages/hotspot_guide_page.dart'
    as _i2;
import 'package:frecu/features/settings/presentation/pages/settings_page.dart'
    as _i7;

/// generated route for
/// [_i1.CreateRoomPage]
class CreateRoomRoute extends _i8.PageRouteInfo<void> {
  const CreateRoomRoute({List<_i8.PageRouteInfo>? children})
    : super(CreateRoomRoute.name, initialChildren: children);

  static const String name = 'CreateRoomRoute';

  static _i8.PageInfo page = _i8.PageInfo(
    name,
    builder: (data) {
      return const _i1.CreateRoomPage();
    },
  );
}

/// generated route for
/// [_i2.HotspotGuidePage]
class HotspotGuideRoute extends _i8.PageRouteInfo<void> {
  const HotspotGuideRoute({List<_i8.PageRouteInfo>? children})
    : super(HotspotGuideRoute.name, initialChildren: children);

  static const String name = 'HotspotGuideRoute';

  static _i8.PageInfo page = _i8.PageInfo(
    name,
    builder: (data) {
      return const _i2.HotspotGuidePage();
    },
  );
}

/// generated route for
/// [_i3.LobbyPage]
class LobbyRoute extends _i8.PageRouteInfo<void> {
  const LobbyRoute({List<_i8.PageRouteInfo>? children})
    : super(LobbyRoute.name, initialChildren: children);

  static const String name = 'LobbyRoute';

  static _i8.PageInfo page = _i8.PageInfo(
    name,
    builder: (data) {
      return const _i3.LobbyPage();
    },
  );
}

/// generated route for
/// [_i4.PermissionsPage]
class PermissionsRoute extends _i8.PageRouteInfo<void> {
  const PermissionsRoute({List<_i8.PageRouteInfo>? children})
    : super(PermissionsRoute.name, initialChildren: children);

  static const String name = 'PermissionsRoute';

  static _i8.PageInfo page = _i8.PageInfo(
    name,
    builder: (data) {
      return const _i4.PermissionsPage();
    },
  );
}

/// generated route for
/// [_i5.RoomPage]
class RoomRoute extends _i8.PageRouteInfo<RoomRouteArgs> {
  RoomRoute({
    required String roomId,
    _i9.Key? key,
    List<_i8.PageRouteInfo>? children,
  }) : super(
         RoomRoute.name,
         args: RoomRouteArgs(roomId: roomId, key: key),
         rawPathParams: {'roomId': roomId},
         initialChildren: children,
       );

  static const String name = 'RoomRoute';

  static _i8.PageInfo page = _i8.PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<RoomRouteArgs>(
        orElse: () => RoomRouteArgs(roomId: pathParams.getString('roomId')),
      );
      return _i5.RoomPage(roomId: args.roomId, key: args.key);
    },
  );
}

class RoomRouteArgs {
  const RoomRouteArgs({required this.roomId, this.key});

  final String roomId;

  final _i9.Key? key;

  @override
  String toString() {
    return 'RoomRouteArgs{roomId: $roomId, key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! RoomRouteArgs) return false;
    return roomId == other.roomId && key == other.key;
  }

  @override
  int get hashCode => roomId.hashCode ^ key.hashCode;
}

/// generated route for
/// [_i6.ScanQrPage]
class ScanQrRoute extends _i8.PageRouteInfo<ScanQrRouteArgs> {
  ScanQrRoute({
    _i9.Key? key,
    _i6.ScannerWidgetBuilder? scannerBuilder,
    List<_i8.PageRouteInfo>? children,
  }) : super(
         ScanQrRoute.name,
         args: ScanQrRouteArgs(key: key, scannerBuilder: scannerBuilder),
         initialChildren: children,
       );

  static const String name = 'ScanQrRoute';

  static _i8.PageInfo page = _i8.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ScanQrRouteArgs>(
        orElse: () => const ScanQrRouteArgs(),
      );
      return _i6.ScanQrPage(key: args.key, scannerBuilder: args.scannerBuilder);
    },
  );
}

class ScanQrRouteArgs {
  const ScanQrRouteArgs({this.key, this.scannerBuilder});

  final _i9.Key? key;

  final _i6.ScannerWidgetBuilder? scannerBuilder;

  @override
  String toString() {
    return 'ScanQrRouteArgs{key: $key, scannerBuilder: $scannerBuilder}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ScanQrRouteArgs) return false;
    return key == other.key && scannerBuilder == other.scannerBuilder;
  }

  @override
  int get hashCode => key.hashCode ^ scannerBuilder.hashCode;
}

/// generated route for
/// [_i7.SettingsPage]
class SettingsRoute extends _i8.PageRouteInfo<void> {
  const SettingsRoute({List<_i8.PageRouteInfo>? children})
    : super(SettingsRoute.name, initialChildren: children);

  static const String name = 'SettingsRoute';

  static _i8.PageInfo page = _i8.PageInfo(
    name,
    builder: (data) {
      return const _i7.SettingsPage();
    },
  );
}
