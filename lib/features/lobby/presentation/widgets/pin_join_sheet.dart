import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frecu/core/constants/network_constants.dart';
import 'package:frecu/core/design/fr_theme.dart';
import 'package:frecu/core/design/icons/fr_icon.dart';
import 'package:frecu/core/design/icons/fr_icons.dart';
import 'package:frecu/core/design/motion/fr_transitions.dart';
import 'package:frecu/core/design/widgets/fr_banner.dart';
import 'package:frecu/core/design/widgets/fr_icon_button.dart';
import 'package:frecu/core/design/widgets/fr_keypad.dart';
import 'package:frecu/core/design/widgets/fr_mark_text.dart';
import 'package:frecu/core/design/widgets/fr_pin_field.dart';
import 'package:frecu/core/design/widgets/fr_sheet.dart';
import 'package:frecu/core/error/failure.dart';
import 'package:frecu/core/result/result.dart';
import 'package:frecu/features/bluetooth_invite/presentation/providers/bluetooth_invite_provider.dart';
import 'package:frecu/features/lobby/domain/entities/nearby_room.dart';
import 'package:frecu/features/lobby/presentation/extensions/display_name_extension.dart';
import 'package:frecu/features/lobby/presentation/extensions/nearby_room_extension.dart';
import 'package:frecu/features/lobby/presentation/widgets/join_cancel.dart';
import 'package:frecu/features/lobby/presentation/widgets/room_note_label.dart';
import 'package:frecu/features/lobby/presentation/widgets/wifi_join_sheet.dart';
import 'package:frecu/features/network/domain/repositories/wifi_join_repository.dart';
import 'package:frecu/features/network/presentation/providers/network_provider.dart';
import 'package:frecu/features/room/domain/entities/room.dart';
import 'package:frecu/features/room/domain/entities/room_invite.dart';
import 'package:frecu/features/room/presentation/providers/room_provider.dart';
import 'package:frecu/i18n/strings.g.dart';

/// Hoja de código de acceso (`SH.pin` del prototipo) para unirse a una frecu
/// cercana: celdas en matriz de puntos, teclado propio y envío automático al
/// cuarto dígito.
///
/// Si el anfitrión acepta, las celdas se rellenan con la ola de acierto y
/// «Código correcto · entrando» durante [enterDelay] (lo acorta el
/// movimiento reducido) y la hoja se cierra con la frecu activa. Si rechaza
/// el código, las celdas pasan a error con una vibración y la siguiente
/// tecla empieza otro; si la frecu está llena, el aviso ámbar con los
/// dígitos aún escritos; si falla por otro motivo, el aviso y las celdas
/// vacías. Mientras verifica se puede cerrar: cerrar cancela la unión.
class PinJoinSheet extends ConsumerStatefulWidget {
  /// Crea la hoja para unirse a [room].
  const PinJoinSheet({required this.room, super.key});

  /// Frecu cercana a la que se une.
  final NearbyRoom room;

  /// Dígitos del código de acceso.
  static const int codeLength = 4;

  /// Lo que se ve el acierto antes de entrar a la frecu.
  static const Duration enterDelay = Duration(milliseconds: 700);

  /// Abre la hoja sobre [context]; devuelve la frecu si se unió.
  static Future<Room?> show(BuildContext context, NearbyRoom room) =>
      showFrSheet<Room>(context, builder: (_) => PinJoinSheet(room: room));

  @override
  ConsumerState<PinJoinSheet> createState() => _PinJoinSheetState();
}

class _PinJoinSheetState extends ConsumerState<PinJoinSheet>
    with SingleTickerProviderStateMixin {
  String _digits = '';
  FrPinState _state = FrPinState.idle;

  /// Espera de [PinJoinSheet.enterDelay] con el acierto a la vista.
  late final AnimationController _enter = AnimationController(
    vsync: this,
    duration: PinJoinSheet.enterDelay,
  );

  /// Falla que se muestra en un aviso (sala llena, sin respuesta…).
  Failure? _failure;

  /// Por Bluetooth: se conectó el teléfono a la red de la frecu, y si al
  /// final entró (si no, al cerrar la hoja la suelta).
  bool _networkTouched = false;
  bool _entered = false;
  WifiJoinRepository? _network;

  bool get _locked => _state == FrPinState.busy || _state == FrPinState.ok;

  @override
  void initState() {
    super.initState();
    if (widget.room.viaBluetooth) {
      _network = ref.read(wifiJoinRepositoryProvider);
    }
  }

  @override
  void dispose() {
    _enter.dispose();
    if (_networkTouched && !_entered) unawaited(_network?.release());
    super.dispose();
  }

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
    final container = ProviderScope.containerOf(context, listen: false);
    var invite = RoomInvite(
      host: room.hostAddress,
      port: room.port,
      roomId: room.roomId,
      accessCode: _digits,
      note: room.note,
    );
    if (room.viaBluetooth) {
      // Fuera de su red: el anfitrión entrega la invitación (con su red)
      // solo con el código correcto, y el teléfono entra a la red.
      final asked = await ref
          .read(bluetoothInviteRepositoryProvider)
          .requestInvite(room, _digits);
      if (!mounted) return;
      switch (asked) {
        case FailureResult(:final failure):
          return _fail(failure);
        case Success(:final data):
          invite = data.copyWith(note: data.note ?? room.note);
      }
      if (!await _onRoomNetwork(invite)) {
        if (mounted) setState(_clear);
        return;
      }
      if (!mounted) return;
    }
    final result = await ref
        .read(roomNotifierProvider.notifier)
        .joinRoom(
          hostAddress: invite.host,
          port: invite.port,
          accessCode: _digits,
          displayName: ref.joinDisplayName,
          note: invite.note,
          wifi: invite.wifi,
        );
    if (!mounted) return leaveCancelledJoin(container, result);
    switch (result) {
      case Success(:final data):
        setState(() => _state = FrPinState.ok);
        await _enterRoom(data, container);
      case FailureResult(:final failure):
        _fail(failure);
    }
  }

  /// Deja ver el acierto y cierra la hoja con [room].
  Future<void> _enterRoom(Room room, ProviderContainer container) async {
    try {
      await _enter.forward(from: 0).orCancel;
    } on TickerCanceled {
      // La hoja se fue antes de entrar.
      return leaveCancelledJoin(container, Result.success(room));
    }
    if (!mounted) return leaveCancelledJoin(container, Result.success(room));
    _entered = true;
    FrExpandOrigin.recordFrom(context);
    Navigator.of(context).pop(room);
  }

  /// Verdadero si el teléfono está en la red de [invite]: ya lo estaba (el
  /// anfitrión responde) o entró con la [WifiJoinSheet]. Sin red en la
  /// invitación, se intenta tal cual.
  Future<bool> _onRoomNetwork(RoomInvite invite) async {
    final network = _network;
    if (invite.wifi == null || network == null) return true;
    _networkTouched = true;
    if (await network.reaches(invite.host, invite.port)) return true;
    if (!mounted) return false;
    return WifiJoinSheet.show(context, invite);
  }

  void _fail(Failure failure) {
    if (failure == const Failure.invalidAccessCode()) {
      unawaited(HapticFeedback.heavyImpact());
      setState(() => _state = FrPinState.error);
      return;
    }
    // Con la frecu llena los dígitos siguen a la vista; con otro fallo se
    // vacían para reintentar.
    final digits = failure == const Failure.roomFull() ? _digits : '';
    setState(() {
      _clear();
      _digits = digits;
      _failure = failure;
    });
  }

  @override
  Widget build(BuildContext context) {
    final room = widget.room;
    final note = room.note;
    final entering = _state == FrPinState.ok;
    return PopScope(
      canPop: !entering,
      child: SingleChildScrollView(
        child: FrSheet(
          children: [
            JoinSheetHeader(
              kicker: [
                if (note != null) ...[note.label, note.hzText],
                if (room.viaBluetooth)
                  t.lobby.join.bluetooth.via
                else
                  room.hostAddress,
              ].join(' · '),
              title: room.title,
              message: t.lobby.join.pin.message,
              onClose: entering ? null : () => Navigator.of(context).maybePop(),
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
    if (failure != null) {
      return JoinFailureBanner(
        failure: failure,
        viaBluetooth: widget.room.viaBluetooth,
      );
    }
    final fr = context.fr;
    final c = fr.colors;
    final pin = t.lobby.join.pin;
    final (text, color) = switch (_state) {
      FrPinState.idle => (pin.autoSend, c.tx3),
      FrPinState.busy => (pin.checking, c.tx3),
      FrPinState.error => (t.lobby.join.wrongCode, c.alert),
      FrPinState.ok => (pin.correct, c.signalFg),
    };
    final style = fr.type.bodyS.copyWith(
      height: 1.45,
      fontWeight: FontWeight.w500,
      fontVariations: const [FontVariation.weight(500)],
      color: color,
    );
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 20),
      // El acierto se destaca con la señal: de día, tinta con marcatexto.
      child: _state == FrPinState.ok
          ? FrMarkText(text, textAlign: TextAlign.center, style: style)
          : Text(text, textAlign: TextAlign.center, style: style),
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

  /// Cierra la hoja; nulo mientras no se puede cerrar.
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
              Text(title, style: FrSheet.titleStyle(fr)),
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

/// Aviso de una unión que falló, con un título y una pista para cada
/// [failure]: la frecu llena («Esta frecu está llena (6/6).») en ámbar; el
/// anfitrión que no responde y cualquier otro fallo, en alerta y sin el
/// mensaje técnico.
class JoinFailureBanner extends StatelessWidget {
  /// Crea el aviso de [failure]; [viaBluetooth] si se pidió por Bluetooth.
  const JoinFailureBanner({
    required this.failure,
    this.viaBluetooth = false,
    super.key,
  });

  /// Falla de la unión.
  final Failure failure;

  /// Si se habló con el anfitrión por Bluetooth (otra pista si no responde).
  final bool viaBluetooth;

  @override
  Widget build(BuildContext context) {
    final join = t.lobby.join;
    final full = failure == const Failure.roomFull();
    final (title, message) = failure.maybeWhen<(String, String?)>(
      roomFull: () =>
          (join.full(max: NetworkConstants.maxParticipants), join.roomFullHint),
      hostUnreachable: () => viaBluetooth
          ? (join.bluetooth.unreachable, join.bluetooth.unreachableHint)
          : (join.unreachable, join.unreachableHint),
      invalidAccessCode: () => (join.wrongCode, null),
      versionMismatch: () => (join.versionMismatch, join.versionMismatchHint),
      orElse: () => (join.failed, join.failedHint),
    );
    return FrBanner.drawn(
      tone: full ? FrBannerTone.warn : FrBannerTone.alert,
      icon: full ? FrIcons.users : FrIcons.alert,
      title: title,
      message: message,
    );
  }
}
