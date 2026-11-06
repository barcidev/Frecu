import 'package:auto_route/auto_route.dart';
import 'package:frecu/app/router/app_router.gr.dart';

/// Guard que redirige a PermissionsRoute si faltan permisos requeridos.
class PermissionsGuard extends AutoRouteGuard {
  /// Constructor con estado de permisos inicializable (por defecto true en base).
  PermissionsGuard({this.hasPermissions = true});

  /// Indica si los permisos requeridos están otorgados.
  final bool hasPermissions;

  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) {
    if (hasPermissions) {
      resolver.next();
    } else {
      router.push(const PermissionsRoute());
    }
  }
}
