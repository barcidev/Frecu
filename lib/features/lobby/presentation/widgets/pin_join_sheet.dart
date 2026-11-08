import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frecu/core/design/fr_theme.dart';
import 'package:frecu/core/design/icons/fr_icon.dart';
import 'package:frecu/core/design/icons/fr_icons.dart';
import 'package:frecu/core/design/widgets/fr_banner.dart';
import 'package:frecu/core/design/widgets/fr_icon_button.dart';
import 'package:frecu/core/design/widgets/fr_keypad.dart';
import 'package:frecu/core/design/widgets/fr_pin_field.dart';
import 'package:frecu/core/design/widgets/fr_sheet.dart';
import 'package:frecu/core/error/failure.dart';
import 'package:frecu/core/result/result.dart';
import 'package:frecu/features/lobby/domain/entities/nearby_room.dart';
import 'package:frecu/features/lobby/presentation/extensions/display_name_extension.dart';
import 'package:frecu/features/lobby/presentation/widgets/room_note_label.dart';
import 'package:frecu/features/room/domain/entities/room.dart';
import 'package:frecu/features/room/presentation/extensions/failure_extension.dart';
import 'package:frecu/features/room/presentation/providers/room_provider.dart';
import 'package:frecu/i18n/strings.g.dart';

/// Hoja de código de acceso (`SH.pin` del prototipo) para unirse a una frecu
/// cercana: celdas en matriz de puntos, teclado propio y envío automático al
/// cuarto dígito.
///
/// Si el anfitrión acepta, se cierra con la frecu activa; si rechaza el
/// código, las celdas pasan a error y la siguiente tecla empieza otro; si
/// falla por otro motivo, muestra el aviso y deja las celdas vacías. Mientras
/// verifica no se cierra.
class PinJoinSheet extends ConsumerStatefulWidget {
  /// Crea la hoja para unirse a [room].
  const PinJoinSheet({required this.room, super.key});

  /// Frecu cercana a la que se une.
  final NearbyRoom room;

  /// Dígitos del código de acceso.
  static const int codeLength = 4;

  /// Abre la hoja sobre [context]; devuelve la frecu si se unió.
  static Future<Room?> show(BuildContext context, NearbyRoom room) =>
      showFrSheet<Room>(context, builder: (_) => PinJoinSheet(room: room));

  @override
  ConsumerState<PinJoinSheet> createState() => _PinJoinSheetState();
}

class _PinJoinSheetState extends ConsumerState<PinJoinSheet> {
  String _digits = '';
  FrPinState _state = FrPinState.idle;

  /// Falla que se muestra en un aviso (sala llena, sin respuesta…).
  Failure? _failure;

  bool get _locked => _state == FrPinState.busy || _state == FrPinState.ok;

  /// Tras un error o un aviso, la siguiente tecla empieza un código nuevo.
  bool get _restarts => _state == FrPinState.error || _failure != null;

  void _clear() {
    _digits = '';
    _state = FrPinState.idle;
    _failure = null;
  }

  void _onDigit(int digit) {
    if (_locked) return;
    setState(() {
      if (_restarts) _clear();
      if (_digits.length < PinJoinSheet.codeLength) _digits += '$digit';
    });
    if (_digits.length == PinJoinSheet.codeLength) unawaited(_submit());
  }

  void _onDelete() {
    if (_locked) return;
    setState(() {
      if (_restarts) {
        _clear();
      } else if (_digits.isNotEmpty) {
        _digits = _digits.substring(0, _digits.length - 1);
      }
    });
  }

  Future<void> _submit() async {
    setState(() => _state = FrPinState.busy);
    final room = widget.room;
    final result = await ref
        .read(roomNotifierProvider.notifier)
        .joinRoom(
          hostAddress: room.hostAddress,
          port: room.port,
          accessCode: _digits,
          displayName: ref.joinDisplayName,
          note: room.note,
        );
    if (!mounted) return;
    switch (result) {
      case Success(:final data):
        setState(() => _state = FrPinState.ok);
        Navigator.of(context).pop(data);
      case FailureResult(:final failure):
        setState(() {
          if (failure == const Failure.invalidAccessCode()) {
            _state = FrPinState.error;
          } else {
            _clear();
            _failure = failure;
          }
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final room = widget.room;
    final note = room.note;
    final busy = _state == FrPinState.busy;
    return PopScope(
      canPop: !busy,
      child: SingleChildScrollView(
        child: FrSheet(
          children: [
            JoinSheetHeader(
              kicker: [
                if (note != null) ...[note.label, note.hzText],
                room.hostAddress,
              ].join(' · '),
              title: room.name,
              message: t.lobby.join.pin.message,
              onClose: busy ? null : () => Navigator.of(context).maybePop(),
            ),
            Center(
              child: FrPinField(
                value: _digits,
                state: _state,
                semanticLabel: t.lobby.accessCode,
              ),
            ),
            _status(context),
            FrKeypad(
              onDigit: _onDigit,
              onDelete: _onDelete,
              deleteLabel: t.lobby.join.pin.delete,
              deleteIcon: const FrIcon(FrIcons.backspace),
            ),
            _JoiningAs(name: ref.joinDisplayName),
          ],
        ),
      ),
    );
  }

  /// Línea de estado bajo las celdas (`.pin-msg`), o el aviso de la falla.
  Widget _status(BuildContext context) {
    final failure = _failure;
    if (failure != null) return JoinFailureBanner(failure: failure);
    final fr = context.fr;
    final c = fr.colors;
    final pin = t.lobby.join.pin;
    final (text, color) = switch (_state) {
      FrPinState.idle => (pin.autoSend, c.tx3),
      FrPinState.busy => (pin.checking, c.tx3),
      FrPinState.error => (t.lobby.join.wrongCode, c.alert),
      FrPinState.ok => (pin.correct, c.signalFg),
    };
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 20),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: fr.type.bodyS.copyWith(
          height: 1.45,
          fontWeight: FontWeight.w500,
          fontVariations: const [FontVariation.weight(500)],
          color: color,
        ),
      ),
    );
  }
}

/// «Entrarás como» y el nombre guardado, en `labelS` y mayúsculas.
class _JoiningAs extends StatelessWidget {
  const _JoiningAs({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final fr = context.fr;
    return Text.rich(
      TextSpan(
        text: '${t.lobby.join.pin.joiningAs} '.toUpperCase(),
        children: [
          TextSpan(
            text: name.toUpperCase(),
            style: TextStyle(color: fr.colors.tx1),
          ),
        ],
      ),
      textAlign: TextAlign.center,
      style: fr.type.labelS.copyWith(color: fr.colors.tx3),
    );
  }
}

/// Encabezado de las hojas de unión (`.sh-h`): la línea superior, el título
/// y el mensaje, y el botón Cerrar.
class JoinSheetHeader extends StatelessWidget {
  /// Crea el encabezado; Cerrar llama a [onClose] o no responde si es nulo.
  const JoinSheetHeader({
    required this.kicker,
    required this.title,
    required this.message,
    required this.onClose,
    super.key,
  });

  /// Línea superior, en `labelS` y mayúsculas.
  final String kicker;

  /// Título.
  final String title;

  /// Mensaje bajo el título.
  final String message;

  /// Cierra la hoja; nulo mientras se une.
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final fr = context.fr;
    final c = fr.colors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                kicker.toUpperCase(),
                style: fr.type.labelS.copyWith(color: c.tx3),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: fr.type.titleL.copyWith(
                  fontSize: 22,
                  height: 1.15,
                  color: c.tx1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                message,
                style: fr.type.body.copyWith(
                  fontSize: 14,
                  height: 1.45,
                  color: c.tx2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        FrIconButton.drawn(
          icon: FrIcons.close,
          semanticLabel: t.lobby.join.close,
          compact: true,
          onPressed: onClose,
        ),
      ],
    );
  }
}

/// Aviso de una unión que falló: el mensaje de la [failure] de título y una
/// pista; la sala llena en ámbar y lo demás en alerta.
class JoinFailureBanner extends StatelessWidget {
  /// Crea el aviso de [failure].
  const JoinFailureBanner({required this.failure, super.key});

  /// Falla de la unión.
  final Failure failure;

  @override
  Widget build(BuildContext context) {
    final join = t.lobby.join;
    final full = failure == const Failure.roomFull();
    final unreachable = failure == const Failure.hostUnreachable();
    return FrBanner(
      tone: full ? FrBannerTone.warn : FrBannerTone.alert,
      icon: full ? Icons.group_outlined : Icons.error_outline_rounded,
      title: failure.toLocalizedMessage(),
      message: full
          ? join.roomFullHint
          : unreachable
          ? join.unreachableHint
          : null,
    );
  }
}
