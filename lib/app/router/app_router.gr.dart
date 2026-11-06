// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'package:auto_route/auto_route.dart' as _i7;
import 'package:flutter/material.dart' as _i8;
import 'package:frecu/features/lobby/presentation/pages/create_room_page.dart'
    as _i1;
import 'package:frecu/features/lobby/presentation/pages/lobby_page.dart' as _i2;
import 'package:frecu/features/lobby/presentation/pages/scan_qr_page.dart'
    as _i5;
import 'package:frecu/features/permissions/presentation/pages/permissions_page.dart'
    as _i3;
import 'package:frecu/features/room/presentation/pages/room_page.dart' as _i4;
import 'package:frecu/features/settings/presentation/pages/settings_page.dart'
    as _i6;

/// generated route for
/// [_i1.CreateRoomPage]
class CreateRoomRoute extends _i7.PageRouteInfo<void> {
  const CreateRoomRoute({List<_i7.PageRouteInfo>? children})
    : super(CreateRoomRoute.name, initialChildren: children);

  static const String name = 'CreateRoomRoute';

  static _i7.PageInfo page = _i7.PageInfo(
    name,
    builder: (data) {
      return const _i1.CreateRoomPage();
    },
  );
}

/// generated route for
/// [_i2.LobbyPage]
class LobbyRoute extends _i7.PageRouteInfo<void> {
  const LobbyRoute({List<_i7.PageRouteInfo>? children})
    : super(LobbyRoute.name, initialChildren: children);

  static const String name = 'LobbyRoute';

  static _i7.PageInfo page = _i7.PageInfo(
    name,
    builder: (data) {
      return const _i2.LobbyPage();
    },
  );
}

/// generated route for
/// [_i3.PermissionsPage]
class PermissionsRoute extends _i7.PageRouteInfo<void> {
  const PermissionsRoute({List<_i7.PageRouteInfo>? children})
    : super(PermissionsRoute.name, initialChildren: children);

  static const String name = 'PermissionsRoute';

  static _i7.PageInfo page = _i7.PageInfo(
    name,
    builder: (data) {
      return const _i3.PermissionsPage();
    },
  );
}

/// generated route for
/// [_i4.RoomPage]
class RoomRoute extends _i7.PageRouteInfo<RoomRouteArgs> {
  RoomRoute({
    required String roomId,
    _i8.Key? key,
    List<_i7.PageRouteInfo>? children,
  }) : super(
         RoomRoute.name,
         args: RoomRouteArgs(roomId: roomId, key: key),
         rawPathParams: {'roomId': roomId},
         initialChildren: children,
       );

  static const String name = 'RoomRoute';

  static _i7.PageInfo page = _i7.PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<RoomRouteArgs>(
        orElse: () => RoomRouteArgs(roomId: pathParams.getString('roomId')),
      );
      return _i4.RoomPage(roomId: args.roomId, key: args.key);
    },
  );
}

class RoomRouteArgs {
  const RoomRouteArgs({required this.roomId, this.key});

  final String roomId;

  final _i8.Key? key;

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
/// [_i5.ScanQrPage]
class ScanQrRoute extends _i7.PageRouteInfo<void> {
  const ScanQrRoute({List<_i7.PageRouteInfo>? children})
    : super(ScanQrRoute.name, initialChildren: children);

  static const String name = 'ScanQrRoute';

  static _i7.PageInfo page = _i7.PageInfo(
    name,
    builder: (data) {
      return const _i5.ScanQrPage();
    },
  );
}

/// generated route for
/// [_i6.SettingsPage]
class SettingsRoute extends _i7.PageRouteInfo<void> {
  const SettingsRoute({List<_i7.PageRouteInfo>? children})
    : super(SettingsRoute.name, initialChildren: children);

  static const String name = 'SettingsRoute';

  static _i7.PageInfo page = _i7.PageInfo(
    name,
    builder: (data) {
      return const _i6.SettingsPage();
    },
  );
}
