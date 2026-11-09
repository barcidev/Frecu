import 'package:flutter/material.dart';
import 'package:frecu/core/design/fr_theme.dart';
import 'package:frecu/core/design/icons/fr_icon.dart';
import 'package:frecu/core/design/icons/fr_icons.dart';
import 'package:frecu/core/design/tokens/fr_colors.dart';
import 'package:frecu/core/design/widgets/fr_button.dart';
import 'package:frecu/i18n/strings.g.dart';

/// Alarma de SOS a pantalla completa (`.sos-ov` del prototipo), siempre de
/// noche: quién pide ayuda y dos respuestas, «Voy en camino» (avisa al
/// grupo) y «Entendido». Tapa la frecu hasta que se atiende.
class SosAlertView extends StatelessWidget {
  /// Crea la alarma de [name].
  const SosAlertView({
    required this.name,
    required this.onMyWay,
    required this.onDismiss,
    this.detail,
    super.key,
  });

  /// Quién pide ayuda.
  final String name;

  /// Texto bajo el título; por defecto, el de la alarma.
  final String? detail;

  /// Responde «Voy en camino» y la cierra.
  final VoidCallback onMyWay;

  /// La cierra sin responder.
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final fr = context.fr;
    const c = FrColors.dark;
    final copy = t.messages.sos;
    return Semantics(
      container: true,
      liveRegion: true,
      label: copy.title(name: name),
      // Fondo opaco: la frecu no se ve detrás de la alarma.
      child: DecoratedBox(
        decoration: BoxDecoration(color: c.bg0),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, -0.4),
              radius: 1.1,
              colors: [
                c.alert.withValues(alpha: 0.45),
                c.alert.withValues(alpha: 0.08),
                c.bg0.withValues(alpha: 0),
              ],
              stops: const [0, 0.6, 1],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 30),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                spacing: 12,
                children: [
                  Container(
                    width: 104,
                    height: 104,
                    margin: const EdgeInsets.only(bottom: 28),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: c.alert,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: c.alert.withValues(alpha: 0.9),
                          blurRadius: 60,
                          spreadRadius: -10,
                        ),
                      ],
                    ),
                    child: const FrIcon(
                      FrIcons.sos,
                      size: 34,
                      color: Color(0xFFFFFFFF),
                    ),
                  ),
                  Text(
                    copy.kicker.toUpperCase(),
                    style: fr.type.label.copyWith(color: c.alertFg),
                  ),
                  Text(
                    copy.title(name: name),
                    textAlign: TextAlign.center,
                    style: fr.type.display.copyWith(color: c.tx1, fontSize: 30),
                  ),
                  Text(
                    detail ?? copy.body,
                    textAlign: TextAlign.center,
                    style: fr.type.body.copyWith(color: c.tx2),
                  ),
                  const SizedBox(height: 18),
                  FrButton.drawn(
                    key: const Key('sos_on_my_way'),
                    label: copy.onMyWay,
                    icon: FrIcons.check,
                    expand: true,
                    onPressed: onMyWay,
                  ),
                  FrButton.drawn(
                    key: const Key('sos_dismiss'),
                    label: copy.dismiss,
                    variant: FrButtonVariant.secondary,
                    expand: true,
                    onPressed: onDismiss,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
