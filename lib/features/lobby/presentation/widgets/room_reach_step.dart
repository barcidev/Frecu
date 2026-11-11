import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frecu/core/design/fr_theme.dart';
import 'package:frecu/core/design/icons/fr_icon.dart';
import 'package:frecu/core/design/icons/fr_icon_data.dart';
import 'package:frecu/core/design/icons/fr_icons.dart';
import 'package:frecu/core/design/widgets/fr_button.dart';
import 'package:frecu/core/design/widgets/fr_pressable.dart';
import 'package:frecu/core/design/widgets/fr_scaffold.dart';
import 'package:frecu/features/lobby/presentation/widgets/create_room_layout.dart';
import 'package:frecu/features/room/domain/entities/room_reach.dart';
import 'package:frecu/features/room/presentation/providers/room_provider.dart';
import 'package:frecu/i18n/strings.g.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'room_reach_step.g.dart';

/// Dice si hay internet para crear una frecu por internet: si el nombre del
/// punto de encuentro se resuelve en 3 s. Sin punto de encuentro, no.
///
/// Se inyecta para que las pruebas decidan si hay internet.
@riverpod
Future<bool> Function() internetCheck(Ref ref) {
  final cloud = ref.watch(cloudConfigProvider);
  return () async {
    if (!cloud.isEnabled) return false;
    try {
      final found = await InternetAddress.lookup(Uri.parse(cloud.baseUrl).host)
          .timeout(const Duration(seconds: 3));
      return found.isNotEmpty;
    } on Object {
      return false;
    }
  };
}

/// «¿Cómo se une tu grupo?» (pantalla `kind` del prototipo del anfitrión),
/// el primer paso de la creación: Local (marcada) o Por internet, y Seguir.
///
/// Sin punto de encuentro o sin internet, Por internet se ve atenuada y
/// dice qué falta; sin internet se vuelve a comprobar cada 5 s.
class RoomReachStep extends ConsumerStatefulWidget {
  /// Crea el paso.
  const RoomReachStep({
    required this.onBack,
    required this.onContinue,
    super.key,
  });

  /// Sale de la creación.
  final VoidCallback onBack;

  /// Sigue con el tipo elegido.
  final ValueChanged<RoomReach> onContinue;

  /// Espera entre comprobaciones mientras no hay internet.
  static const Duration recheck = Duration(seconds: 5);

  @override
  ConsumerState<RoomReachStep> createState() => _RoomReachStepState();
}

class _RoomReachStepState extends ConsumerState<RoomReachStep> {
  RoomReach _reach = RoomReach.local;

  /// Si hay internet; nulo mientras se comprueba la primera vez.
  bool? _online;
  Timer? _retry;

  @override
  void initState() {
    super.initState();
    unawaited(_check());
  }

  @override
  void dispose() {
    _retry?.cancel();
    super.dispose();
  }

  Future<void> _check() async {
    _retry?.cancel();
    if (!ref.read(cloudConfigProvider).isEnabled) return;
    final online = await ref.read(internetCheckProvider)();
    if (!mounted) return;
    setState(() {
      _online = online;
      if (!online) _reach = RoomReach.local;
    });
    if (!online) _retry = Timer(RoomReachStep.recheck, _check);
  }

  @override
  Widget build(BuildContext context) {
    return FrScaffold(
      dock: CreateRoomFitWidth(
        child: FrButton.drawn(
          label: t.lobby.newRoom.reach.kContinue,
          trailingIcon: FrIcons.arrow,
          expand: true,
          onPressed: () => widget.onContinue(_reach),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CreateRoomAppBar(
            step: 1,
            steps: CreateRoomAppBar.stepsFor(_reach),
            title: t.lobby.newRoom.title,
            onBack: widget.onBack,
          ),
          Expanded(
            child: CreateRoomScroll(
              dockHeight: CreateRoomScroll.oneButtonDock,
              children: [_heading(context), _options()],
            ),
          ),
        ],
      ),
    );
  }

  /// Local y Por internet; Por internet, atenuada y con lo que falta si no
  /// hay punto de encuentro o internet.
  Widget _options() {
    final copy = t.lobby.newRoom.reach;
    final cloud = ref.watch(cloudConfigProvider).isEnabled;
    final internetDetail = !cloud
        ? copy.internetUnavailable
        : _online == false
        ? copy.internetOffline
        : copy.internetDetail;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
      child: Column(
        spacing: 8,
        children: [
          RoomReachOption(
            key: const Key('room_reach_option_local'),
            icon: FrIcons.hotspot,
            title: copy.local,
            detail: copy.localDetail,
            selected: _reach == RoomReach.local,
            enabled: true,
            onPressed: () => _choose(RoomReach.local),
          ),
          RoomReachOption(
            key: const Key('room_reach_option_internet'),
            icon: FrIcons.globe,
            title: copy.internet,
            detail: internetDetail,
            selected: _reach == RoomReach.internet,
            enabled: cloud && (_online ?? false),
            onPressed: () => _choose(RoomReach.internet),
          ),
        ],
      ),
    );
  }

  void _choose(RoomReach reach) => setState(() => _reach = reach);

  /// «¿Cómo se une tu grupo?» y «Se elige una vez…».
  Widget _heading(BuildContext context) {
    final fr = context.fr;
    final copy = t.lobby.newRoom.reach;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(copy.title, style: createRoomTitleStyle(fr)),
          const SizedBox(height: 8),
          Text(copy.message, style: createRoomMessageStyle(fr)),
        ],
      ),
    );
  }
}

/// Opción de un tipo de frecu (`.opt`): ícono, nombre, detalle y marca.
class RoomReachOption extends StatelessWidget {
  /// Crea la opción.
  const RoomReachOption({
    required this.icon,
    required this.title,
    required this.detail,
    required this.selected,
    required this.enabled,
    required this.onPressed,
    super.key,
  });

  /// Ícono del tipo.
  final FrIconData icon;

  /// Nombre del tipo.
  final String title;

  /// Qué significa o, si no está disponible, qué falta.
  final String detail;

  /// Es el tipo marcado.
  final bool selected;

  /// Se puede elegir; si no, se ve apagada y no responde.
  final bool enabled;

  /// Marca el tipo.
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      child: Opacity(
        opacity: enabled ? 1 : 0.45,
        child: FrPressable(
          onPressed: enabled ? onPressed : null,
          pressedScale: 0.98,
          builder: (context, _, _) => _surface(context),
        ),
      ),
    );
  }

  Widget _surface(BuildContext context) {
    final fr = context.fr;
    final c = fr.colors;
    return AnimatedContainer(
      duration: fr.motion.smooth,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.bg1,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: selected ? c.signal.withValues(alpha: 0.55) : c.line1,
        ),
        boxShadow: [
          if (selected)
            BoxShadow(
              color: c.signal.withValues(alpha: 0.8),
              blurRadius: 30,
              spreadRadius: -16,
            ),
        ],
      ),
      child: Row(
        children: [
          _iconBox(fr),
          const SizedBox(width: 14),
          Expanded(child: _texts(fr)),
          const SizedBox(width: 14),
          _check(fr),
        ],
      ),
    );
  }

  Widget _iconBox(FrTheme fr) {
    final c = fr.colors;
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? c.signal.withValues(alpha: 0.1) : c.bg2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.line1),
      ),
      child: FrIcon(icon, color: selected ? c.signalFg : c.tx1),
    );
  }

  Widget _texts(FrTheme fr) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: 4,
    children: [
      Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: fr.type.body.copyWith(
          fontSize: 15,
          height: 1.2,
          fontWeight: FontWeight.w600,
          fontVariations: const [FontVariation.weight(600)],
          color: fr.colors.tx1,
        ),
      ),
      Text(
        detail.toUpperCase(),
        style: fr.type.labelS.copyWith(color: fr.colors.tx3),
      ),
    ],
  );

  Widget _check(FrTheme fr) {
    final c = fr.colors;
    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? c.signal : null,
        border: selected ? null : Border.all(color: c.line3, width: 1.5),
      ),
      child: selected
          ? FrIcon(FrIcons.check, size: 16, color: c.signalInk)
          : null,
    );
  }
}
