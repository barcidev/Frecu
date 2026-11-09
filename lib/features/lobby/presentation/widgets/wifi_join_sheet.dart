import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frecu/core/design/fr_theme.dart';
import 'package:frecu/core/design/icons/fr_icon.dart';
import 'package:frecu/core/design/icons/fr_icon_data.dart';
import 'package:frecu/core/design/icons/fr_icons.dart';
import 'package:frecu/core/design/widgets/fr_banner.dart';
import 'package:frecu/core/design/widgets/fr_button.dart';
import 'package:frecu/core/design/widgets/fr_sheet.dart';
import 'package:frecu/core/design/widgets/wave_loader.dart';
import 'package:frecu/core/error/failure.dart';
import 'package:frecu/core/result/result.dart';
import 'package:frecu/features/lobby/presentation/extensions/display_name_extension.dart';
import 'package:frecu/features/lobby/presentation/widgets/local_network_step.dart';
import 'package:frecu/features/lobby/presentation/widgets/pin_join_sheet.dart';
import 'package:frecu/features/lobby/presentation/widgets/room_note_label.dart';
import 'package:frecu/features/network/domain/entities/wifi_credentials.dart';
import 'package:frecu/features/network/presentation/providers/network_provider.dart';
import 'package:frecu/features/room/domain/entities/room_invite.dart';
import 'package:frecu/i18n/strings.g.dart';

/// Hoja que conecta el teléfono del invitado a la red de la frecu antes de
/// unirse (`joinSheet` del prototipo de la red de Frecu).
///
/// Al abrirse pide la red al sistema, que muestra su aviso, y espera a que
/// el anfitrión responda; si sale bien, se cierra con verdadero. Si el aviso
/// se canceló, la red no aparece o algo falla, lo dice con Reintentar y
/// «Conectarme a mano». A mano (también en Android 9 o anterior, que no se
/// conecta solo) muestra la red y la clave, con Copiar, «Abrir Wi-Fi» y «Ya
/// me conecté», que cierra con verdadero. Cerrar devuelve falso.
class WifiJoinSheet extends ConsumerStatefulWidget {
  /// Crea la hoja de [invite], que trae la red de la frecu.
  const WifiJoinSheet({required this.invite, super.key});

  /// Invitación con la red de la frecu.
  final RoomInvite invite;

  /// Abre la hoja sobre [context]; verdadero si el teléfono quedó en la red.
  static Future<bool> show(BuildContext context, RoomInvite invite) async =>
      await showFrSheet<bool>(
        context,
        builder: (_) => WifiJoinSheet(invite: invite),
      ) ??
      false;

  @override
  ConsumerState<WifiJoinSheet> createState() => _WifiJoinSheetState();
}

/// En qué está la hoja.
enum _Stage { connecting, failed, manual }

class _WifiJoinSheetState extends ConsumerState<WifiJoinSheet> {
  _Stage _stage = _Stage.connecting;
  WifiJoinFailureReason? _reason;
  bool _copied = false;
  int _attempt = 0;

  WifiCredentials get _wifi => widget.invite.wifi!;

  @override
  void initState() {
    super.initState();
    unawaited(_connect());
  }

  Future<void> _connect() async {
    final attempt = ++_attempt;
    final invite = widget.invite;
    final result = await ref
        .read(wifiJoinRepositoryProvider)
        .join(_wifi, host: invite.host, port: invite.port);
    if (!mounted || attempt != _attempt) return;
    switch (result) {
      case Success():
        Navigator.of(context).pop(true);
      case FailureResult(:final failure):
        final reason = failure.maybeWhen(
          wifiJoin: (reason) => reason,
          orElse: () => WifiJoinFailureReason.failed,
        );
        setState(() {
          _reason = reason;
          _stage = reason == WifiJoinFailureReason.unsupported
              ? _Stage.manual
              : _Stage.failed;
        });
    }
  }

  void _retry() {
    setState(() {
      _stage = _Stage.connecting;
      _reason = null;
    });
    unawaited(_connect());
  }

  void _manual() => setState(() => _stage = _Stage.manual);

  Future<void> _copy(String key) async {
    await Clipboard.setData(ClipboardData(text: key));
    if (mounted) setState(() => _copied = true);
  }

  @override
  Widget build(BuildContext context) {
    final invite = widget.invite;
    final note = invite.note;
    final copy = t.lobby.join.wifi;
    final message = switch (_stage) {
      _Stage.connecting => copy.message,
      _Stage.failed => copy.needed,
      _Stage.manual =>
        _reason == WifiJoinFailureReason.unsupported
            ? copy.manualOld
            : copy.manualMessage,
    };
    return SingleChildScrollView(
      child: FrSheet(
        children: [
          JoinSheetHeader(
            kicker: [
              if (note != null) ...[note.label, note.hzText],
              invite.host,
            ].join(' · '),
            title: invite.name ?? note?.label ?? t.lobby.unnamedRoom,
            message: message,
            onClose: () => Navigator.of(context).pop(false),
          ),
          ...switch (_stage) {
            _Stage.connecting => _connecting(context),
            _Stage.failed => _failed(),
            _Stage.manual => _manualStage(context),
          },
        ],
      ),
    );
  }

  List<Widget> _connecting(BuildContext context) {
    final fr = context.fr;
    final copy = t.lobby.join.wifi;
    return [
      LocalNetworkPanel(
        key: const Key('wifi_join_connecting'),
        leading: const WaveLoader(width: 46, height: 20),
        title: copy.connecting(ssid: _wifi.ssid),
        message: copy.confirmHint,
      ),
      Text.rich(
        TextSpan(
          text: '${t.lobby.join.pin.joiningAs} '.toUpperCase(),
          children: [
            TextSpan(
              text: ref.joinDisplayName.toUpperCase(),
              style: TextStyle(color: fr.colors.tx1),
            ),
          ],
        ),
        textAlign: TextAlign.center,
        style: fr.type.labelS.copyWith(color: fr.colors.tx3),
      ),
    ];
  }

  List<Widget> _failed() {
    final copy = t.lobby.join.wifi;
    final (tone, title, message) = switch (_reason) {
      WifiJoinFailureReason.declined => (
        FrBannerTone.warn,
        copy.declinedTitle,
        copy.declinedMessage,
      ),
      WifiJoinFailureReason.notFound => (
        FrBannerTone.alert,
        copy.notFoundTitle(ssid: _wifi.ssid),
        copy.notFoundMessage,
      ),
      _ => (FrBannerTone.alert, copy.failedTitle, copy.failedMessage),
    };
    return [
      FrBanner.drawn(
        key: const Key('wifi_join_failure'),
        tone: tone,
        icon: FrIcons.wifi,
        title: title,
        message: message,
      ),
      FrButton.drawn(
        label: copy.retry,
        icon: FrIcons.regen,
        expand: true,
        onPressed: _retry,
      ),
      FrButton(
        label: copy.manual,
        variant: FrButtonVariant.ghost,
        expand: true,
        onPressed: _manual,
      ),
    ];
  }

  List<Widget> _manualStage(BuildContext context) {
    final copy = t.lobby.join.wifi;
    final key = _wifi.passphrase;
    return [
      _CredentialRow(
        label: copy.networkLabel,
        icon: FrIcons.wifi,
        value: _wifi.ssid,
      ),
      _CredentialRow(
        label: copy.keyLabel,
        icon: FrIcons.lock,
        value: key ?? copy.noKey,
        mono: key != null,
        action: key == null
            ? null
            : (_copied ? copy.copied : copy.copy, () => unawaited(_copy(key))),
      ),
      FrButton.drawn(
        key: const Key('wifi_join_done'),
        label: copy.done,
        trailingIcon: FrIcons.arrow,
        expand: true,
        onPressed: () => Navigator.of(context).pop(true),
      ),
      FrButton.drawn(
        label: copy.openWifi,
        icon: FrIcons.wifi,
        variant: FrButtonVariant.secondary,
        expand: true,
        onPressed: () => unawaited(
          ref.read(systemSettingsRepositoryProvider).openWifiSettings(),
        ),
      ),
    ];
  }
}

/// Un dato para conectarse a mano: su etiqueta y su valor, con una acción
/// opcional a la derecha (Copiar).
class _CredentialRow extends StatelessWidget {
  const _CredentialRow({
    required this.label,
    required this.icon,
    required this.value,
    this.mono = true,
    this.action,
  });

  final String label;
  final FrIconData icon;
  final String value;
  final bool mono;
  final (String, VoidCallback)? action;

  @override
  Widget build(BuildContext context) {
    final fr = context.fr;
    final c = fr.colors;
    final action = this.action;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label.toUpperCase(),
                style: fr.type.labelS.copyWith(color: c.tx3),
              ),
            ),
            if (action != null)
              GestureDetector(
                onTap: action.$2,
                child: Text(
                  action.$1.toUpperCase(),
                  style: fr.type.labelS.copyWith(color: c.signalFg),
                ),
              ),
          ],
        ),
        DecoratedBox(
          decoration: ShapeDecoration(
            color: c.bg1,
            shape: RoundedSuperellipseBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: c.line1),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                FrIcon(icon, size: 18, color: c.tx3),
                const SizedBox(width: 12),
                Expanded(
                  child: SelectableText(
                    value,
                    style: (mono ? fr.type.data : fr.type.body).copyWith(
                      color: mono ? c.tx1 : c.tx2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
