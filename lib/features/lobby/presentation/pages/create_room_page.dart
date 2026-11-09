import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frecu/core/design/motion/fr_transitions.dart';
import 'package:frecu/core/logging/app_logger.dart';
import 'package:frecu/features/lobby/presentation/extensions/display_name_extension.dart';
import 'package:frecu/features/lobby/presentation/providers/discovery_provider.dart';
import 'package:frecu/features/lobby/presentation/providers/new_room_provider.dart';
import 'package:frecu/features/lobby/presentation/widgets/hotspot_credentials_sheet.dart';
import 'package:frecu/features/lobby/presentation/widgets/hotspot_guide_step.dart';
import 'package:frecu/features/lobby/presentation/widgets/local_network_step.dart';
import 'package:frecu/features/lobby/presentation/widgets/new_room_step.dart';
import 'package:frecu/features/network/presentation/providers/local_hotspot_provider.dart';
import 'package:frecu/features/network/presentation/providers/network_provider.dart';
import 'package:frecu/features/room/presentation/providers/room_provider.dart';
import 'package:frecu/features/settings/presentation/providers/preferences_provider.dart';
import 'package:frecu/i18n/strings.g.dart';

/// Crear una frecu como anfitrión, en dos pasos: la red y la nueva frecu con
/// su nota en el reloj de quintas.
///
/// En Android, la red la crea Frecu ([LocalNetworkStep]) y la guía del punto
/// de acceso queda detrás de «Prefiero mi zona Wi-Fi»; en iPhone, el primer
/// paso es la guía. Si se sale de la creación sin abrir la frecu, la red de
/// Frecu se apaga.
///
/// Los pasos viven en un [Navigator] propio: seguir entra deslizando, y Atrás
/// o el gesto de volver regresan al paso anterior sin perder el nombre ni el
/// código (en el primero, salen al inicio).
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

  /// Este teléfono crea la red de la frecu (Android).
  late final bool _createsNetwork;

  /// Apaga la red de Frecu si se sale sin abrir la frecu; al abrirla, la
  /// red sigue con ella.
  void Function()? _releaseNetwork;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: _defaultName());
    _code = ref.read(accessCodeGeneratorProvider)();
    _createsNetwork = ref.read(localHotspotAvailableProvider);
    if (_createsNetwork) {
      final hotspot = ref.read(localHotspotProvider.notifier);
      final container = ProviderScope.containerOf(context, listen: false);
      // Al soltar la pantalla no se puede cambiar un provider: va después.
      _releaseNetwork = () => scheduleMicrotask(() {
        try {
          if (container.read(roomNotifierProvider) == null) {
            unawaited(hotspot.stop());
          }
        } on Object catch (error) {
          // La app se cierra: Android apaga la red con el proceso.
          AppLogger.d('Room network left as is: $error');
        }
      });
    }
  }

  @override
  void dispose() {
    _releaseNetwork?.call();
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

  void _exit() => unawaited(context.router.maybePop());

  void _toNewRoom() => unawaited(_steps.currentState?.push(_route(_newRoom)));

  /// La red de la frecu que crea Frecu (Android).
  Widget _network(BuildContext _) => LocalNetworkStep(
    onBack: _exit,
    onContinue: _toNewRoom,
    onUseHotspot: () => unawaited(_steps.currentState?.push(_route(_guide))),
  );

  /// La guía del punto de acceso: el primer paso en iPhone; en Android,
  /// detrás de «Prefiero mi zona Wi-Fi».
  Widget _guide(BuildContext _) => Consumer(
    builder: (context, ref, _) => HotspotGuideStep(
      onBack: _createsNetwork ? _back : _exit,
      onContinue: _toNewRoom,
      onOpenHotspotSettings: () => unawaited(
        ref.read(systemSettingsRepositoryProvider).openHotspotSettings(),
      ),
      // Solo donde Frecu crea la red (Android): la zona Wi-Fi propia se
      // guarda para entregarla por Bluetooth.
      onSaveHotspot: _createsNetwork
          ? () => unawaited(HotspotCredentialsSheet.show(context))
          : null,
      hotspotSaved: ref.watch(
        preferencesProvider.select((p) => p.value?.hotspot != null),
      ),
    ),
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
        onGenerateInitialRoutes: (_, _) => [
          _route(_createsNetwork ? _network : _guide),
        ],
      ),
    );
  }
}
