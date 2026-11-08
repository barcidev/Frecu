import 'package:flutter/material.dart';
import 'package:frecu/core/design/fr_theme.dart';
import 'package:frecu/core/design/icons/fr_icons.dart';
import 'package:frecu/core/design/motion/fr_noise.dart';
import 'package:frecu/core/design/widgets/fr_button.dart';
import 'package:frecu/core/design/widgets/signal_signature.dart';
import 'package:frecu/i18n/strings.g.dart';

/// Tarjeta del nombre visible en Ajustes (`.profile`): la firma de señal del
/// nombre, el nombre y el botón para cambiarlo.
class ProfileCard extends StatelessWidget {
  /// Crea la tarjeta de [name]; nulo si aún no hay nombre.
  const ProfileCard({required this.name, required this.onEdit, super.key});

  /// Nombre visible guardado; nulo si aún no se eligió.
  final String? name;

  /// Abre el cambio de nombre.
  final VoidCallback onEdit;

  static const double _signatureSize = 96;

  @override
  Widget build(BuildContext context) {
    final fr = context.fr;
    final c = fr.colors;
    final name = this.name;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: c.bg1,
          shape: RoundedSuperellipseBorder(
            borderRadius: BorderRadius.circular(26),
            side: BorderSide(color: c.line1),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              _signature(fr, name ?? ''),
              const SizedBox(width: 16),
              Expanded(child: _details(fr, name)),
            ],
          ),
        ),
      ),
    );
  }

  /// Etiqueta, nombre (o «Sin nombre») y el botón Editar.
  Widget _details(FrTheme fr, String? name) {
    final c = fr.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.settings.displayName.toUpperCase(),
          style: fr.type.labelS.copyWith(color: c.tx3),
        ),
        const SizedBox(height: 8),
        Text(
          name ?? t.settings.noName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: fr.type.titleL.copyWith(
            color: name == null ? c.tx3 : c.tx1,
            fontSize: 26,
            height: 1,
            letterSpacing: -0.52,
            fontWeight: FontWeight.w700,
            fontVariations: const [
              FontVariation.weight(700),
              FontVariation.width(120),
            ],
          ),
        ),
        const SizedBox(height: 8),
        FrButton.drawn(
          label: t.settings.edit,
          icon: FrIcons.edit,
          variant: FrButtonVariant.secondary,
          size: FrButtonSize.small,
          onPressed: onEdit,
        ),
      ],
    );
  }

  /// Firma en un círculo con borde y un halo de señal al 8 %.
  Widget _signature(FrTheme fr, String name) {
    final c = fr.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: c.line1),
        gradient: RadialGradient(
          colors: [
            c.signal.withValues(alpha: 0.08),
            c.signal.withValues(alpha: 0),
          ],
          stops: const [0, 0.7],
        ),
      ),
      child: SignalSignature(
        name: name,
        size: _signatureSize,
        mode: SignatureMode.speak,
        levelOf: (seconds) => frVoice(seconds) * 0.55,
        radius: 0.38,
      ),
    );
  }
}
