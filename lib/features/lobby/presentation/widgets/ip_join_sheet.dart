import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frecu/core/constants/network_constants.dart';
import 'package:frecu/core/design/fr_theme.dart';
import 'package:frecu/core/design/icons/fr_icons.dart';
import 'package:frecu/core/design/motion/fr_transitions.dart';
import 'package:frecu/core/design/widgets/fr_button.dart';
import 'package:frecu/core/design/widgets/fr_field.dart';
import 'package:frecu/core/design/widgets/fr_sheet.dart';
import 'package:frecu/core/error/failure.dart';
import 'package:frecu/core/network/lan_address.dart';
import 'package:frecu/core/result/result.dart';
import 'package:frecu/features/lobby/presentation/extensions/display_name_extension.dart';
import 'package:frecu/features/lobby/presentation/widgets/join_cancel.dart';
import 'package:frecu/features/lobby/presentation/widgets/pin_join_sheet.dart';
import 'package:frecu/features/room/domain/entities/room.dart';
import 'package:frecu/features/room/presentation/providers/room_provider.dart';
import 'package:frecu/i18n/strings.g.dart';

/// Hoja de conexión manual por IP (`SH.ip` del prototipo), para cuando la
/// frecu no aparece en la lista: la IP del anfitrión, con el puerto a la
/// derecha de su etiqueta, y el código de acceso.
///
/// Antes de conectar comprueba que la IP sea una IPv4; si no, su campo pasa
/// a error. Se une en el puerto de señalización y sin nota. Si el anfitrión
/// acepta, se cierra con la frecu activa; si no responde, el campo de IP pasa
/// a error con el aviso «El anfitrión no responde.»; si el código es
/// incorrecto, el campo del código, con una vibración; cualquier otro fallo,
/// un aviso sin el mensaje técnico. Mientras conecta se puede cerrar: cerrar
/// cancela la unión.
class IpJoinSheet extends ConsumerStatefulWidget {
  /// Crea la hoja.
  const IpJoinSheet({super.key});

  /// IP de ejemplo del campo vacío (punto de acceso de Android).
  static const String sampleIp = '192.168.43.1';

  /// Abre la hoja sobre [context]; devuelve la frecu si se unió.
  static Future<Room?> show(BuildContext context) =>
      showFrSheet<Room>(context, builder: (_) => const IpJoinSheet());

  @override
  ConsumerState<IpJoinSheet> createState() => _IpJoinSheetState();
}

class _IpJoinSheetState extends ConsumerState<IpJoinSheet> {
  static const int _port = NetworkConstants.signalingPort;
  static final RegExp _code = RegExp('^\\d{${PinJoinSheet.codeLength}}\$');

  final _ip = TextEditingController();
  final _accessCode = TextEditingController();
  bool _connecting = false;
  Failure? _failure;

  /// La IP escrita no es una IPv4.
  bool _invalidIp = false;

  @override
  void dispose() {
    _ip.dispose();
    _accessCode.dispose();
    super.dispose();
  }

  bool get _canConnect =>
      !_connecting &&
      _ip.text.trim().isNotEmpty &&
      _code.hasMatch(_accessCode.text.trim());

  void _onChanged(String _) => setState(() {
    _failure = null;
    _invalidIp = false;
  });

  Future<void> _connect() async {
    if (!_canConnect) return;
    final host = normalizeIpv4(_ip.text);
    if (host == null) {
      setState(() {
        _invalidIp = true;
        _failure = null;
      });
      return;
    }
    setState(() {
      _connecting = true;
      _failure = null;
    });
    final container = ProviderScope.containerOf(context, listen: false);
    final result = await ref
        .read(roomNotifierProvider.notifier)
        .joinRoom(
          hostAddress: host,
          port: _port,
          accessCode: _accessCode.text.trim(),
          displayName: ref.joinDisplayName,
        );
    if (!mounted) return leaveCancelledJoin(container, result);
    switch (result) {
      case Success(:final data):
        FrExpandOrigin.recordFrom(context);
        Navigator.of(context).pop(data);
      case FailureResult(:final failure):
        if (failure == const Failure.invalidAccessCode()) {
          unawaited(HapticFeedback.heavyImpact());
        }
        setState(() {
          _connecting = false;
          _failure = failure;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final join = t.lobby.join;
    final failure = _failure;
    final unreachable = failure == const Failure.hostUnreachable();
    final wrongCode = failure == const Failure.invalidAccessCode();
    return SingleChildScrollView(
      child: FrSheet(
        children: [
          JoinSheetHeader(
            kicker: join.ip.kicker,
            title: t.lobby.joinRoom,
            message: join.ip.message,
            onClose: () => Navigator.of(context).maybePop(),
          ),
          FieldWithAside(
            aside: join.port(port: _port),
            child: _ipField(unreachable: unreachable),
          ),
          _codeField(wrongCode: wrongCode),
          if (failure != null && !wrongCode)
            JoinFailureBanner(failure: failure),
          FrButton.drawn(
            label: join.ip.connect,
            icon: FrIcons.arrow,
            expand: true,
            loading: _connecting,
            onPressed: _connecting || _canConnect ? _connect : null,
          ),
        ],
      ),
    );
  }

  /// IP del anfitrión (el puerto va a la derecha de la etiqueta); en error
  /// si no es una IPv4 o si el anfitrión no responde.
  Widget _ipField({required bool unreachable}) {
    final join = t.lobby.join;
    return FrField(
      label: join.ip.host,
      controller: _ip,
      hint: IpJoinSheet.sampleIp,
      error: _invalidIp
          ? join.ip.invalid(ip: IpJoinSheet.sampleIp)
          : unreachable
          ? join.ip.noAnswer(port: _port)
          : null,
      mono: true,
      icon: Icons.hub_outlined,
      autofocus: true,
      keyboardType: TextInputType.url,
      textInputAction: TextInputAction.next,
      onChanged: _onChanged,
    );
  }

  /// Código de acceso de 4 dígitos; en error si el anfitrión lo rechaza.
  Widget _codeField({required bool wrongCode}) => FrField(
    label: t.lobby.accessCode,
    controller: _accessCode,
    error: wrongCode ? t.lobby.join.wrongCode : null,
    maxLength: PinJoinSheet.codeLength,
    mono: true,
    icon: Icons.lock_outline_rounded,
    keyboardType: TextInputType.number,
    textInputAction: TextInputAction.done,
    onChanged: _onChanged,
    onSubmitted: (_) => _connect(),
  );
}

/// Un texto en `labelS` a la derecha de la etiqueta de un `FrField`
/// (`.field-l` del prototipo), como «Puerto 47800».
class FieldWithAside extends StatelessWidget {
  /// Pone [aside] a la derecha de la etiqueta de [child].
  const FieldWithAside({required this.aside, required this.child, super.key});

  /// Texto de la derecha; se muestra en mayúsculas.
  final String aside;

  /// El campo.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final fr = context.fr;
    return Stack(
      children: [
        child,
        // Centrado en la línea de 14 px de la etiqueta.
        Positioned(
          top: 1,
          right: 0,
          child: Text(
            aside.toUpperCase(),
            maxLines: 1,
            style: fr.type.labelS.copyWith(color: fr.colors.tx3),
          ),
        ),
      ],
    );
  }
}
