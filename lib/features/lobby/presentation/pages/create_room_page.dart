import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frecu/core/design/motion/fr_transitions.dart';
import 'package:frecu/features/lobby/presentation/extensions/display_name_extension.dart';
import 'package:frecu/features/lobby/presentation/providers/discovery_provider.dart';
import 'package:frecu/features/lobby/presentation/providers/new_room_provider.dart';
import 'package:frecu/features/lobby/presentation/widgets/hotspot_guide_step.dart';
import 'package:frecu/features/lobby/presentation/widgets/new_room_step.dart';
import 'package:frecu/i18n/strings.g.dart';

/// Crear una frecu como anfitrión, en dos pasos: la guía del punto de acceso
/// y la nueva frecu con su nota en el reloj de quintas.
///
/// Los pasos viven en un [Navigator] propio: seguir entra deslizando, y Atrás
/// o el gesto de volver regresan a la guía sin perder el nombre ni el código
/// (en la guía, salen al inicio).
@RoutePage()
class CreateRoomPage extends ConsumerStatefulWidget {
  /// Constructor constante.
  const CreateRoomPage({super.key});

  @override
  ConsumerState<CreateRoomPage> createState() => _CreateRoomPageState();
}

class _CreateRoomPageState extends ConsumerState<CreateRoomPage> {
  final GlobalKey<NavigatorState> _steps = GlobalKey<NavigatorState>();
  late final TextEditingController _name;
  late String _code;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: _defaultName());
    _code = ref.read(accessCodeGeneratorProvider)();
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  /// «Frecu de» y el nombre guardado, o «Mi frecu», sin pasar del máximo.
  String _defaultName() {
    final saved = ref.savedDisplayName?.trim();
    final newRoom = t.lobby.newRoom;
    final name = saved == null || saved.isEmpty
        ? newRoom.untitled
        : newRoom.defaultName(name: saved);
    return name.characters
        .take(NewRoomStep.maxNameLength)
        .toString()
        .trimRight();
  }

  Route<void> _route(WidgetBuilder builder) =>
      FrPageRoute<void>(builder: builder, transition: FrTransition.slide);

  void _back() => unawaited(_steps.currentState?.maybePop());

  Widget _guide(BuildContext _) => HotspotGuideStep(
    onBack: () => unawaited(context.router.maybePop()),
    onContinue: () => unawaited(_steps.currentState?.push(_route(_newRoom))),
  );

  Widget _newRoom(BuildContext _) => NewRoomStep(
    name: _name,
    code: _code,
    onCodeChanged: (code) => _code = code,
    onBack: _back,
  );

  @override
  Widget build(BuildContext context) {
    // Mantiene vivas las frecus cercanas: sus notas no se repiten al crear.
    ref.watch(nearbyRoomsProvider);
    return NavigatorPopHandler<Object?>(
      onPopWithResult: (_) => _back(),
      child: Navigator(
        key: _steps,
        onGenerateInitialRoutes: (_, _) => [_route(_guide)],
      ),
    );
  }
}
