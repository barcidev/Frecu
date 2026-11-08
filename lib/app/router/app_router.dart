import 'package:auto_route/auto_route.dart';
import 'package:frecu/app/router/app_router.gr.dart';
import 'package:frecu/app/router/guards/permissions_guard.dart';

/// Router principal declarativo de la aplicación.
@AutoRouterConfig()
class AppRouter extends RootStackRouter {
  /// Constructor con inyección de guards.
  AppRouter({PermissionsGuard? permissionsGuard})
    : permissionsGuard = permissionsGuard ?? PermissionsGuard();

  /// Guard para verificar permisos del sistema.
  final PermissionsGuard permissionsGuard;

  @override
  List<AutoRoute> get routes => [
    AutoRoute(page: PermissionsRoute.page, path: '/permissions'),
    AutoRoute(
      page: LobbyRoute.page,
      path: '/',
      guards: [permissionsGuard],
      initial: true,
    ),
    AutoRoute(page: CreateRoomRoute.page, path: '/create-room'),
    AutoRoute(page: ScanQrRoute.page, path: '/scan-qr'),
    AutoRoute(page: RoomRoute.page, path: '/room/:roomId'),
    AutoRoute(page: SettingsRoute.page, path: '/settings'),
    AutoRoute(page: HotspotGuideRoute.page, path: '/settings/hotspot-guide'),
  ];
}
