import 'package:auto_route/auto_route.dart';
import 'package:flutter/widgets.dart';
import 'package:frecu/core/design/motion/fr_transitions.dart';
import 'package:frecu/features/permissions/presentation/widgets/welcome_step.dart';

/// Recorrido de la primera vez: bienvenida, nombre y permisos.
///
/// Los pasos viven en un [Navigator] propio que empieza en la bienvenida.
@RoutePage()
class PermissionsPage extends StatefulWidget {
  /// Constructor constante.
  const PermissionsPage({super.key});

  @override
  State<PermissionsPage> createState() => _PermissionsPageState();
}

class _PermissionsPageState extends State<PermissionsPage> {
  final GlobalKey<NavigatorState> _steps = GlobalKey<NavigatorState>();

  Route<void> _route(WidgetBuilder builder) =>
      FrPageRoute<void>(builder: builder, transition: FrTransition.wave);

  Widget _welcome(BuildContext _) => WelcomeStep(onStart: () {});

  @override
  Widget build(BuildContext context) {
    return NavigatorPopHandler<Object?>(
      onPopWithResult: (_) => _steps.currentState?.maybePop(),
      child: Navigator(
        key: _steps,
        onGenerateInitialRoutes: (_, _) => [_route(_welcome)],
      ),
    );
  }
}
