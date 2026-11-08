import 'package:flutter/widgets.dart';
import 'package:frecu/core/design/fr_theme.dart';
import 'package:frecu/core/design/icons/fr_icons.dart';
import 'package:frecu/core/design/widgets/fr_button.dart';
import 'package:frecu/core/design/widgets/fr_scaffold.dart';
import 'package:frecu/features/permissions/presentation/widgets/onboarding_layout.dart';
import 'package:frecu/features/permissions/presentation/widgets/welcome_mesh.dart';
import 'package:frecu/i18n/strings.g.dart';

/// Primer paso del recorrido: la malla de 6 lugares explica el producto y
/// Empezar lleva al nombre.
class WelcomeStep extends StatelessWidget {
  /// Crea la bienvenida; [onStart] avanza al paso del nombre.
  const WelcomeStep({required this.onStart, super.key});

  /// Alto de la malla (`.hero-c`).
  static const double meshHeight = 380;

  /// Avanza al paso siguiente.
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final fr = context.fr;
    final copy = t.permissions.welcome;
    return FrScaffold(
      body: OnboardingScroll(
        children: [
          const OnboardingTopLine(step: 0),
          const SizedBox(height: meshHeight, child: WelcomeMesh()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Kicker(copy.kicker),
                const SizedBox(height: 14),
                Text(copy.title, style: onboardingTitleStyle(fr)),
                const SizedBox(height: 14),
                Text(copy.message, style: onboardingMessageStyle(fr)),
              ],
            ),
          ),
        ],
      ),
      dock: FrButton.drawn(
        label: copy.start,
        trailingIcon: FrIcons.arrow,
        expand: true,
        onPressed: onStart,
      ),
    );
  }
}

/// Aviso sobre el título: una raya de señal y el texto en mayúsculas.
class _Kicker extends StatelessWidget {
  const _Kicker(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final fr = context.fr;
    return Row(
      children: [
        SizedBox(
          width: 16,
          height: 1,
          child: ColoredBox(color: fr.colors.signalFg),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            text.toUpperCase(),
            style: fr.type.label.copyWith(color: fr.colors.tx3),
          ),
        ),
      ],
    );
  }
}
