import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frecu/core/constants/network_constants.dart';
import 'package:frecu/core/design/icons/fr_icons.dart';
import 'package:frecu/core/design/widgets/fr_button.dart';
import 'package:frecu/core/design/widgets/fr_field.dart';
import 'package:frecu/core/design/widgets/fr_sheet.dart';
import 'package:frecu/core/error/failure.dart';
import 'package:frecu/core/result/result.dart';
import 'package:frecu/features/lobby/presentation/extensions/display_name_extension.dart';
import 'package:frecu/features/lobby/presentation/widgets/pin_join_sheet.dart';
import 'package:frecu/features/room/domain/entities/room.dart';
import 'package:frecu/features/room/presentation/providers/room_provider.dart';
import 'package:frecu/i18n/strings.g.dart';

/// Hoja de conexión manual por IP (`SH.ip` del prototipo), para cuando la
/// frecu no aparece en la lista: la IP del anfitrión y el código de acceso.
///
/// Se une en el puerto de señalización y sin nota. Si el anfitrión acepta,
/// se cierra con la frecu activa; si no responde, el campo de IP pasa a error
/// con un aviso; si el código es incorrecto, el campo del código. Mientras
/// conecta no se cierra.
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

  void _onChanged(String _) => setState(() => _failure = null);

  Future<void> _connect() async {
    if (!_canConnect) return;
    setState(() {
      _connecting = true;
      _failure = null;
    });
    final result = await ref
        .read(roomNotifierProvider.notifier)
        .joinRoom(
          hostAddress: _ip.text.trim(),
          port: _port,
          accessCode: _accessCode.text.trim(),
          displayName: ref.joinDisplayName,
        );
    if (!mounted) return;
    switch (result) {
      case Success(:final data):
        Navigator.of(context).pop(data);
      case FailureResult(:final failure):
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
    return PopScope(
      canPop: !_connecting,
      child: SingleChildScrollView(
        child: FrSheet(
          children: [
            JoinSheetHeader(
              kicker: join.ip.kicker,
              title: t.lobby.joinRoom,
              message: join.ip.message,
              onClose: _connecting
                  ? null
                  : () => Navigator.of(context).maybePop(),
            ),
            _ipField(unreachable: unreachable),
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
      ),
    );
  }

  /// IP del anfitrión, con el puerto debajo; en error si no responde.
  Widget _ipField({required bool unreachable}) {
    final join = t.lobby.join;
    return FrField(
      label: join.ip.host,
      controller: _ip,
      hint: IpJoinSheet.sampleIp,
      help: join.port(port: _port),
      error: unreachable ? join.ip.noAnswer(port: _port) : null,
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
