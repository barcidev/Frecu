import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frecu/app/router/app_router.gr.dart';
import 'package:frecu/core/design/motion/fr_transitions.dart';
import 'package:frecu/features/permissions/presentation/providers/onboarding_provider.dart';
import 'package:frecu/features/permissions/presentation/widgets/name_step.dart';
import 'package:frecu/features/permissions/presentation/widgets/permissions_step.dart';
import 'package:frecu/features/permissions/presentation/widgets/welcome_step.dart';

/// Recorrido de la primera vez: bienvenida, nombre y permisos.
///
/// Los pasos viven en un [Navigator] propio: avanzar entra con la onda desde
/// el dedo, y Atrás o el gesto de volver regresan un paso sin perder el
/// nombre escrito (en la bienvenida, el gesto sale de la ruta). Al terminar
/// se guarda que el recorrido se completó, aunque falte algún permiso, y el
/// inicio queda como única pantalla.
@RoutePage()
class PermissionsPage extends ConsumerStatefulWidget {
  /// Constructor constante.
  const PermissionsPage({super.key});

  @override
  ConsumerState<PermissionsPage> createState() => _PermissionsPageState();
}

class _PermissionsPageState extends ConsumerState<PermissionsPage> {
  final GlobalKey<NavigatorState> _steps = GlobalKey<NavigatorState>();
  final TextEditingController _name = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Route<void> _route(WidgetBuilder builder) =>
      FrPageRoute<void>(builder: builder, transition: FrTransition.wave);

  void _push(WidgetBuilder builder) =>
      unawaited(_steps.currentState?.push(_route(builder)));

  void _back() => unawaited(_steps.currentState?.maybePop());

  Widget _welcome(BuildContext _) =>
      WelcomeStep(onStart: () => _push(_nameStep));

  Widget _nameStep(BuildContext _) => NameStep(
    controller: _name,
    onBack: _back,
    onSaved: () => _push(_permissions),
  );

  Widget _permissions(BuildContext _) =>
      PermissionsStep(onBack: _back, onFinish: _finish);

  void _finish() => unawaited(_complete());

  Future<void> _complete() async {
    await ref.read(onboardingCompletedProvider.notifier).markCompleted();
    if (!mounted) return;
    await context.router.replaceAll([const LobbyRoute()]);
  }

  @override
  Widget build(BuildContext context) {
    return NavigatorPopHandler<Object?>(
      onPopWithResult: (_) => _back(),
      child: Navigator(
        key: _steps,
        onGenerateInitialRoutes: (_, _) => [_route(_welcome)],
      ),
    );
  }
}
