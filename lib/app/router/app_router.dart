import 'package:auto_route/auto_route.dart';
import 'package:frecu/app/router/app_router.gr.dart';
import 'package:frecu/app/router/guards/permissions_guard.dart';
import 'package:frecu/core/design/motion/fr_transitions.dart';

/// Router principal declarativo de la aplicación.
///
/// Cada pantalla entra con su transición de Portadora (`FrPageRoute`): la
/// onda desde el dedo al entrar a un modo (inicio al terminar el recorrido,
/// crear, escanear y la frecu) y el deslizamiento con paralaje a Ajustes. Al
/// volver, la pantalla sale hacia la derecha y la de abajo regresa desde el
/// −28 %. Con movimiento reducido todas son un fundido.
@AutoRouterConfig()
class AppRouter extends RootStackRouter {
  /// Constructor con inyección de guards.
  AppRouter({PermissionsGuard? permissionsGuard})
    : permissionsGuard = permissionsGuard ?? PermissionsGuard();

  /// Guard para verificar permisos del sistema.
  final PermissionsGuard permissionsGuard;

  /// Transición con la que entra cada ruta, por su nombre; las que no están
  /// usan la del tema (`FrPageTransitionsBuilder`).
  static const Map<String, FrTransition> transitions = {
    LobbyRoute.name: FrTransition.wave,
    CreateRoomRoute.name: FrTransition.wave,
    ScanQrRoute.name: FrTransition.wave,
    RoomRoute.name: FrTransition.wave,
    SettingsRoute.name: FrTransition.slide,
  };

  /// Construye la ruta de página de Portadora con [transition] para una
  /// `CustomRoute`; la página de auto_route va como `settings`.
  static CustomRouteBuilder portadora(FrTransition transition) =>
      <T>(context, child, page) {
        // Con el código correcto la hoja crece hasta ser la pantalla nueva.
        final from = transition == FrTransition.wave
            ? FrExpandOrigin.take()
            : null;
        return FrPageRoute<T>(
          settings: page,
          transition: from == null ? transition : FrTransition.expand,
          from: from,
          builder: (_) => child,
          maintainState: page.maintainState,
          fullscreenDialog: page.fullscreenDialog,
          allowSnapshotting: page.allowSnapshotting,
        );
      };

  @override
  List<AutoRoute> get routes => [
    AutoRoute(page: PermissionsRoute.page, path: '/permissions'),
    _route(
      LobbyRoute.page,
      path: '/',
      guards: [permissionsGuard],
      initial: true,
    ),
    _route(CreateRoomRoute.page, path: '/create-room'),
    _route(ScanQrRoute.page, path: '/scan-qr'),
    _route(RoomRoute.page, path: '/room/:roomId'),
    _route(SettingsRoute.page, path: '/settings'),
  ];

  /// Ruta de [page] con su transición de [transitions].
  CustomRoute<void> _route(
    PageInfo page, {
    required String path,
    List<AutoRouteGuard> guards = const [],
    bool initial = false,
  }) => CustomRoute<void>(
    page: page,
    path: path,
    guards: guards,
    initial: initial,
    customRouteBuilder: portadora(transitions[page.name]!),
  );
}
