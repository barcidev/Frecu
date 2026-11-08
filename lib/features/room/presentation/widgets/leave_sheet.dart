import 'dart:async';

import 'package:flutter/material.dart';
import 'package:frecu/core/design/fr_theme.dart';
import 'package:frecu/core/design/icons/fr_icon.dart';
import 'package:frecu/core/design/icons/fr_icon_data.dart';
import 'package:frecu/core/design/icons/fr_icons.dart';
import 'package:frecu/core/design/widgets/fr_button.dart';
import 'package:frecu/core/design/widgets/fr_sheet.dart';
import 'package:frecu/i18n/strings.g.dart';

/// Hoja que confirma salir de la frecu (`SH.leave` del prototipo). Para el
/// anfitrión dice que la frecu se cierra para las [others] personas.
class LeaveSheet extends StatelessWidget {
  /// Crea la hoja; [host] si la persona propia es la anfitriona.
  const LeaveSheet({required this.host, required this.others, super.key});

  /// La persona propia es la anfitriona.
  final bool host;

  /// Personas en la frecu además de la propia.
  final int others;

  /// Abre la hoja; devuelve si se confirmó.
  static Future<bool> show(
    BuildContext context, {
    required bool host,
    required int others,
  }) async =>
      await showFrSheet<bool>(
        context,
        builder: (_) => LeaveSheet(host: host, others: others),
      ) ??
      false;

  String get _message {
    final copy = t.room.sheets.leave;
    if (!host) return copy.peerMessage;
    if (others <= 0) return copy.hostAlone;
    if (others == 1) return copy.hostOne;
    return copy.hostMany(count: others);
  }

  @override
  Widget build(BuildContext context) {
    final copy = t.room.sheets.leave;
    final navigator = Navigator.of(context);
    return SingleChildScrollView(
      child: FrSheet(
        children: [
          _LeaveHeading(
            icon: host ? FrIcons.antenna : FrIcons.exit,
            title: host ? copy.hostTitle : copy.peerTitle,
            message: _message,
          ),
          Column(
            spacing: 10,
            children: [
              FrButton.drawn(
                key: const Key('leave_confirm'),
                label: host ? copy.hostConfirm : copy.peerConfirm,
                icon: FrIcons.exit,
                variant: FrButtonVariant.danger,
                expand: true,
                onPressed: () => navigator.pop(true),
              ),
              FrButton(
                key: const Key('leave_cancel'),
                label: copy.cancel,
                variant: FrButtonVariant.secondary,
                expand: true,
                onPressed: () => navigator.pop(false),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Ícono en alerta, título y consecuencia de salir, centrados.
class _LeaveHeading extends StatelessWidget {
  const _LeaveHeading({
    required this.icon,
    required this.title,
    required this.message,
  });

  final FrIconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final fr = context.fr;
    final c = fr.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 10, 6, 4),
      child: Column(
        spacing: 12,
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: c.bg2,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: c.line1),
            ),
            child: FrIcon(icon, size: 28, color: c.alert),
          ),
          Text(
            title,
            textAlign: TextAlign.center,
            style: fr.type.titleL.copyWith(
              fontSize: 22,
              height: 1.2,
              color: c.tx1,
            ),
          ),
          Text(
            message,
            textAlign: TextAlign.center,
            style: fr.type.body.copyWith(
              fontSize: 14.5,
              height: 1.55,
              color: c.tx2,
            ),
          ),
        ],
      ),
    );
  }
}
