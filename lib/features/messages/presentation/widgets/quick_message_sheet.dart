import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frecu/core/design/fr_theme.dart';
import 'package:frecu/core/design/icons/fr_icon.dart';
import 'package:frecu/core/design/icons/fr_icon_data.dart';
import 'package:frecu/core/design/icons/fr_icons.dart';
import 'package:frecu/core/design/widgets/fr_pressable.dart';
import 'package:frecu/core/design/widgets/fr_sheet.dart';
import 'package:frecu/features/messages/domain/entities/quick_message.dart';
import 'package:frecu/features/room/presentation/widgets/room_sheets.dart';
import 'package:frecu/i18n/strings.g.dart';

/// Texto de cada mensaje rápido.
String quickMessageText(QuickMessageKind kind) {
  final kinds = t.messages.kinds;
  return switch (kind) {
    QuickMessageKind.behind => kinds.behind,
    QuickMessageKind.stop => kinds.stop,
    QuickMessageKind.fuel => kinds.fuel,
    QuickMessageKind.ok => kinds.ok,
    QuickMessageKind.onMyWay => kinds.onMyWay,
    QuickMessageKind.sos => kinds.sos,
  };
}

/// Ícono de cada mensaje rápido.
FrIconData quickMessageIcon(QuickMessageKind kind) => switch (kind) {
  QuickMessageKind.behind => FrIcons.back,
  QuickMessageKind.stop => FrIcons.flag,
  QuickMessageKind.fuel => FrIcons.fuel,
  QuickMessageKind.ok || QuickMessageKind.onMyWay => FrIcons.check,
  QuickMessageKind.sos => FrIcons.sos,
};

/// Hoja de mensajes rápidos (`SH.quick` del prototipo): cuatro mensajes de
/// un toque y el SOS, que se envía manteniendo pulsado [SosHoldButton.hold].
/// Elegir uno lo devuelve al cerrar la hoja; la frecu lo envía.
class QuickMessageSheet extends ConsumerWidget {
  /// Crea la hoja; [footer] va al final (p. ej. compartir la ubicación).
  const QuickMessageSheet({this.footer, super.key});

  /// Contenido bajo el SOS.
  final Widget? footer;

  /// Abre la hoja y devuelve el mensaje elegido, o nulo si se cerró sin
  /// elegir.
  static Future<QuickMessageKind?> show(
    BuildContext context, {
    Widget? footer,
  }) => showFrSheet<QuickMessageKind>(
    context,
    builder: (_) => QuickMessageSheet(footer: footer),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final copy = t.messages;
    final footer = this.footer;
    return SingleChildScrollView(
      child: FrSheet(
        children: [
          RoomSheetHeader(
            kicker: copy.kicker,
            title: copy.title,
            message: copy.message,
          ),
          _grid(context),
          SosHoldButton(
            onSend: () => Navigator.of(context).pop(QuickMessageKind.sos),
          ),
          ?footer,
        ],
      ),
    );
  }

  Widget _grid(BuildContext context) {
    const presets = QuickMessageKind.presets;
    Widget tile(QuickMessageKind kind) => Expanded(
      child: QuickMessageTile(
        key: Key('quick_message_${kind.name}'),
        kind: kind,
        onPressed: () => Navigator.of(context).pop(kind),
      ),
    );
    return Column(
      spacing: 8,
      children: [
        for (var i = 0; i < presets.length; i += 2)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 8,
              children: [tile(presets[i]), tile(presets[i + 1])],
            ),
          ),
      ],
    );
  }
}

/// Mensaje de la hoja (`.qbtn`): ícono en señal y el texto debajo.
class QuickMessageTile extends StatelessWidget {
  /// Crea el mensaje [kind].
  const QuickMessageTile({
    required this.kind,
    required this.onPressed,
    super.key,
  });

  /// Qué mensaje es.
  final QuickMessageKind kind;

  /// Lo elige.
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final fr = context.fr;
    final c = fr.colors;
    return FrPressable(
      onPressed: onPressed,
      pressedScale: 0.97,
      semanticLabel: quickMessageText(kind),
      builder: (context, _, _) => Container(
        constraints: const BoxConstraints(minHeight: 92),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: c.bg1,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: c.line1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          spacing: 12,
          children: [
            FrIcon(quickMessageIcon(kind), size: 20, color: c.signalFg),
            Text(
              quickMessageText(kind),
              style: fr.type.body.copyWith(
                color: c.tx1,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// SOS (`.sos-btn`): se envía solo tras mantenerlo pulsado [hold], con un
/// relleno que avanza mientras tanto; soltar antes lo cancela.
class SosHoldButton extends StatefulWidget {
  /// Crea el botón; [onSend] se llama al completar la pulsación.
  const SosHoldButton({required this.onSend, super.key});

  /// Lo que dura la pulsación.
  static const Duration hold = Duration(milliseconds: 1200);

  /// Envía el SOS.
  final VoidCallback onSend;

  @override
  State<SosHoldButton> createState() => _SosHoldButtonState();
}

class _SosHoldButtonState extends State<SosHoldButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fill = AnimationController(
    vsync: this,
    duration: SosHoldButton.hold,
  )..addStatusListener(_onStatus);

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) widget.onSend();
  }

  void _start() => unawaited(_fill.forward(from: 0));

  void _cancel() {
    if (_fill.isCompleted) return;
    _fill
      ..stop()
      ..value = 0;
  }

  @override
  void dispose() {
    _fill.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fr = context.fr;
    final c = fr.colors;
    final copy = t.messages;
    return Semantics(
      button: true,
      label: copy.sosHold,
      hint: copy.sosHoldHelp,
      onLongPress: widget.onSend,
      child: Listener(
        key: const Key('sos_hold_button'),
        onPointerDown: (_) => _start(),
        onPointerUp: (_) => _cancel(),
        onPointerCancel: (_) => _cancel(),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: c.alert.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: c.alert.withValues(alpha: 0.45)),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _fill,
                    builder: (context, _) => FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: _fill.value,
                      child: ColoredBox(color: c.alert.withValues(alpha: 0.24)),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Row(
                    spacing: 12,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: c.alert.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: FrIcon(FrIcons.sos, size: 20, color: c.alert),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: 3,
                          children: [
                            Text(
                              copy.sosHold,
                              style: fr.type.body.copyWith(
                                color: c.alertFg,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              copy.sosHoldHelp,
                              style: fr.type.bodyS.copyWith(color: c.tx2),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
