import 'dart:async';
import 'dart:math' as math;

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frecu/app/router/app_router.gr.dart';
import 'package:frecu/core/design/fr_theme.dart';
import 'package:frecu/core/design/icons/fr_icons.dart';
import 'package:frecu/core/design/motion/reduced_motion.dart';
import 'package:frecu/core/design/widgets/fr_button.dart';
import 'package:frecu/core/design/widgets/fr_field.dart';
import 'package:frecu/core/design/widgets/fr_icon_button.dart';
import 'package:frecu/core/design/widgets/fr_pin_field.dart';
import 'package:frecu/core/design/widgets/fr_scaffold.dart';
import 'package:frecu/core/design/widgets/fr_toast.dart';
import 'package:frecu/core/result/result.dart';
import 'package:frecu/features/lobby/presentation/extensions/display_name_extension.dart';
import 'package:frecu/features/lobby/presentation/providers/discovery_provider.dart';
import 'package:frecu/features/lobby/presentation/providers/new_room_provider.dart';
import 'package:frecu/features/lobby/presentation/widgets/create_room_layout.dart';
import 'package:frecu/features/lobby/presentation/widgets/fifths_clock.dart';
import 'package:frecu/features/lobby/presentation/widgets/room_note_label.dart';
import 'package:frecu/features/room/domain/entities/room_note.dart';
import 'package:frecu/features/room/domain/usecases/assign_room_note.dart';
import 'package:frecu/features/room/presentation/extensions/failure_extension.dart';
import 'package:frecu/features/room/presentation/providers/room_provider.dart';
import 'package:frecu/i18n/strings.g.dart';

/// Nueva frecu (pantalla `create` del prototipo), paso 2 de 2 de la
/// creación: el reloj de quintas con la nota que tendrá la frecu a esta
/// hora, el nombre, el código de acceso generado y «Abrir frecu».
///
/// La nota se recalcula con la hora (se relee cada 15 s) y con las notas de
/// las frecus cercanas, para no repetir ninguna.
class NewRoomStep extends ConsumerStatefulWidget {
  /// Crea el paso con el nombre en [name] y el código [code].
  const NewRoomStep({
    required this.name,
    required this.code,
    required this.onCodeChanged,
    required this.onBack,
    super.key,
  });

  /// Máximo de caracteres del nombre.
  static const int maxNameLength = 24;

  /// Nombre de la frecu; lo guarda la página para volver a la guía.
  final TextEditingController name;

  /// Código de acceso al entrar.
  final String code;

  /// Avisa del código nuevo al generar otro.
  final ValueChanged<String> onCodeChanged;

  /// Vuelve a la guía.
  final VoidCallback onBack;

  @override
  ConsumerState<NewRoomStep> createState() => _NewRoomStepState();
}

class _NewRoomStepState extends ConsumerState<NewRoomStep> {
  static const Duration _refresh = Duration(seconds: 15);

  late String _code = widget.code;
  late DateTime _now = ref.read(newRoomClockProvider)();
  Timer? _clock;
  bool _opening = false;
  double _regenTurns = 0;

  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(_refresh, (_) {
      setState(() => _now = ref.read(newRoomClockProvider)());
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  void _regenerate() {
    final code = ref.read(accessCodeGeneratorProvider)();
    setState(() {
      _code = code;
      _regenTurns += 1;
    });
    widget.onCodeChanged(code);
  }

  Future<void> _open(List<RoomNote> nearbyNotes) async {
    final name = widget.name.text.trim();
    if (name.isEmpty || _opening) return;
    setState(() => _opening = true);
    final result = await ref
        .read(roomNotifierProvider.notifier)
        .createRoom(
          name: name,
          accessCode: _code,
          displayName: ref.savedDisplayName,
          nearbyNotes: nearbyNotes,
        );
    if (!mounted) return;
    switch (result) {
      case Success(:final data):
        unawaited(
          ref
              .read(discoveryRepositoryProvider)
              .publishRoom(
                roomId: data.id,
                name: data.name,
                port: data.port,
                note: data.note,
              ),
        );
        unawaited(context.router.replace(RoomRoute(roomId: data.id)));
      case FailureResult(:final failure):
        setState(() => _opening = false);
        showFrToast(
          context,
          FrToast.icon(
            icon: Icons.error_outline_rounded,
            message: failure.toLocalizedMessage(),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final newRoom = t.lobby.newRoom;
    final rooms = ref.watch(nearbyRoomsProvider).value ?? const [];
    final nearbyNotes = rooms.map((room) => room.note).nonNulls.toList();
    final note = const AssignRoomNote().assign(
      createdAt: _now,
      nearbyNotes: nearbyNotes,
    );
    return FrScaffold(
      dock: _dock(nearbyNotes),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CreateRoomAppBar(
            step: 2,
            title: newRoom.title,
            onBack: widget.onBack,
          ),
          Expanded(
            child: CreateRoomScroll(
              dockHeight: CreateRoomScroll.oneButtonDock,
              children: [
                NewRoomHero(note: note, openedAt: _now),
                _form(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// «Abrir frecu»: deshabilitado sin nombre y en carga mientras crea.
  Widget _dock(List<RoomNote> nearbyNotes) =>
      ValueListenableBuilder<TextEditingValue>(
        valueListenable: widget.name,
        builder: (context, value, _) => CreateRoomFitWidth(
          child: FrButton.drawn(
            label: t.lobby.newRoom.open,
            icon: FrIcons.antenna,
            expand: true,
            loading: _opening,
            onPressed: value.text.trim().isEmpty
                ? null
                : () => _open(nearbyNotes),
          ),
        ),
      );

  /// Nombre de la frecu y código de acceso.
  Widget _form() {
    final newRoom = t.lobby.newRoom;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FrField(
            label: newRoom.name,
            controller: widget.name,
            hint: newRoom.nameHint,
            maxLength: NewRoomStep.maxNameLength,
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: 22),
          _AccessCode(
            code: _code,
            turns: _regenTurns,
            onRegenerate: _regenerate,
          ),
        ],
      ),
    );
  }
}

/// Héroe de la nueva frecu (`.ch-hero.fifths`): el reloj de quintas y, a su
/// lado, la nota, sus Hz y la hora de apertura.
class NewRoomHero extends StatelessWidget {
  /// Crea el héroe con la [note] de la frecu abierta en [openedAt].
  const NewRoomHero({required this.note, required this.openedAt, super.key});

  /// Nota que tendrá la frecu.
  final RoomNote note;

  /// Hora de apertura.
  final DateTime openedAt;

  @override
  Widget build(BuildContext context) {
    return _HeroBox(
      children: [
        Positioned(
          left: 2,
          top: 6,
          child: FifthsClock(
            hour: openedAt.hour,
            minute: openedAt.minute,
            note: note,
          ),
        ),
        Positioned(
          left: 190,
          top: 24,
          right: 20,
          bottom: 12,
          child: Align(
            alignment: Alignment.topRight,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.topRight,
              child: _NoteReading(note: note, openedAt: openedAt),
            ),
          ),
        ),
      ],
    );
  }
}

/// Caja del héroe: 196 px con margen 4 20 0, radio 28, `bg1` con el lavado
/// radial de señal desde abajo, borde `line1` y filo `spec`.
class _HeroBox extends StatelessWidget {
  const _HeroBox({required this.children});

  final List<Widget> children;

  static const double _radius = 28;

  @override
  Widget build(BuildContext context) {
    final c = context.fr.colors;
    final shape = RoundedSuperellipseBorder(
      borderRadius: BorderRadius.circular(_radius),
    );
    final wash = math.min(1, 0.12 * c.washK).toDouble();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
      child: SizedBox(
        height: 196,
        child: DecoratedBox(
          decoration: ShapeDecoration(
            color: c.bg1,
            shape: shape.copyWith(side: BorderSide(color: c.line1)),
          ),
          child: ClipPath(
            clipper: ShapeBorderClipper(shape: shape),
            child: Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(0, 1.4),
                        radius: 1.2,
                        colors: [
                          c.signal.withValues(alpha: wash),
                          c.signal.withValues(alpha: 0),
                        ],
                        stops: const [0, 0.6],
                      ),
                    ),
                  ),
                ),
                // Filo especular arriba.
                Positioned(
                  top: 1,
                  left: _radius * 0.6,
                  right: _radius * 0.6,
                  height: 1,
                  child: ColoredBox(color: c.spec),
                ),
                ...children,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// «Tu frecu suena en», la nota grande, sus Hz y «Abierta a las HH:MM».
class _NoteReading extends StatelessWidget {
  const _NoteReading({required this.note, required this.openedAt});

  final RoomNote note;
  final DateTime openedAt;

  @override
  Widget build(BuildContext context) {
    final fr = context.fr;
    final c = fr.colors;
    final newRoom = t.lobby.newRoom;
    final time = fifthsClockTime(openedAt.hour, openedAt.minute);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          newRoom.soundsIn.toUpperCase(),
          style: fr.type.labelS.copyWith(color: c.tx3),
        ),
        const SizedBox(height: 8),
        RoomNoteText(note: note, size: 64, octaveSize: 15, glow: true),
        const SizedBox(height: 8),
        Text(
          note.hzText.toUpperCase(),
          style: fr.type.labelS.copyWith(color: c.tx2),
        ),
        const SizedBox(height: 8),
        Text(
          newRoom.openedAt(time: time).toUpperCase(),
          style: fr.type.labelS.copyWith(color: c.tx3),
        ),
      ],
    );
  }
}

/// Código de acceso generado (`.pinrow`): celdas de solo lectura, «Generar
/// otro» y su ayuda.
class _AccessCode extends StatelessWidget {
  const _AccessCode({
    required this.code,
    required this.turns,
    required this.onRegenerate,
  });

  final String code;
  final double turns;
  final VoidCallback onRegenerate;

  @override
  Widget build(BuildContext context) {
    final fr = context.fr;
    final c = fr.colors;
    final newRoom = t.lobby.newRoom;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                newRoom.code.toUpperCase(),
                style: fr.type.label.copyWith(color: c.tx3),
              ),
            ),
            Text(
              newRoom.codeDigits.toUpperCase(),
              style: fr.type.labelS.copyWith(color: c.tx3),
            ),
          ],
        ),
        const SizedBox(height: 9),
        _pinRow(context),
        const SizedBox(height: 9),
        Text(
          newRoom.codeHelp,
          style: fr.type.bodyS.copyWith(
            fontSize: 12.5,
            height: 1.45,
            color: c.tx3,
          ),
        ),
      ],
    );
  }

  /// Las celdas del código y «Generar otro», que gira una vuelta.
  Widget _pinRow(BuildContext context) {
    final newRoom = t.lobby.newRoom;
    return Row(
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: FrPinField(
                value: code,
                readOnly: true,
                semanticLabel: newRoom.code,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        AnimatedRotation(
          turns: turns,
          duration: context.reduceMotion
              ? Duration.zero
              : const Duration(milliseconds: 700),
          curve: context.fr.motion.easeOut,
          child: FrIconButton.drawn(
            icon: FrIcons.regen,
            semanticLabel: newRoom.regenerate,
            onPressed: onRegenerate,
          ),
        ),
      ],
    );
  }
}
