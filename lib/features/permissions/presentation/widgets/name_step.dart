import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frecu/core/design/fr_theme.dart';
import 'package:frecu/core/design/icons/fr_icons.dart';
import 'package:frecu/core/design/motion/fr_noise.dart';
import 'package:frecu/core/design/widgets/fr_button.dart';
import 'package:frecu/core/design/widgets/fr_field.dart';
import 'package:frecu/core/design/widgets/fr_scaffold.dart';
import 'package:frecu/core/design/widgets/signal_signature.dart';
import 'package:frecu/features/permissions/presentation/widgets/onboarding_layout.dart';
import 'package:frecu/features/settings/domain/entities/preferences.dart';
import 'package:frecu/features/settings/presentation/providers/preferences_provider.dart';
import 'package:frecu/i18n/strings.g.dart';

/// Segundo paso del recorrido: el nombre visible, con la firma de señal que
/// nace del texto en vivo.
///
/// Continuar solo se habilita si el dominio acepta el nombre
/// ([Preferences.normalizeDisplayName], que cuenta `runes`); lo guarda con
/// `preferencesProvider` y avanza, y si falla queda en el paso con el error.
class NameStep extends ConsumerStatefulWidget {
  /// Crea el paso con el texto de [controller]; [onSaved] avanza tras
  /// guardar el nombre.
  const NameStep({
    required this.controller,
    required this.onBack,
    required this.onSaved,
    super.key,
  });

  /// Texto del campo; lo guarda el recorrido para no perderlo al volver.
  final TextEditingController controller;

  /// Vuelve a la bienvenida.
  final VoidCallback onBack;

  /// Avanza a los permisos con el nombre ya guardado.
  final VoidCallback onSaved;

  @override
  ConsumerState<NameStep> createState() => _NameStepState();
}

class _NameStepState extends ConsumerState<NameStep> {
  TextEditingController get _controller => widget.controller;
  bool _prefilled = false;
  bool _saving = false;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    ref.listenManual(
      preferencesProvider,
      (_, next) => _prefill(next.value?.displayName),
      fireImmediately: true,
    );
    _controller.addListener(_onText);
  }

  @override
  void dispose() {
    _controller.removeListener(_onText);
    super.dispose();
  }

  /// Llena el campo vacío una sola vez con el nombre guardado, si lo hay.
  void _prefill(String? name) {
    if (_prefilled || name == null) return;
    _prefilled = true;
    if (_controller.text.isEmpty) _controller.text = name;
  }

  void _onText() {
    if (mounted) setState(() {});
  }

  bool get _isValid =>
      Preferences.normalizeDisplayName(_controller.text) != null;

  /// Error del campo: el del guardado, o el del largo si el texto no está
  /// vacío pero el dominio no lo acepta.
  String? get _error {
    if (_saveError case final error?) return error;
    if (_controller.text.trim().isEmpty || _isValid) return null;
    return t.permissions.name.tooLong(max: Preferences.displayNameMaxLength);
  }

  void _onChanged(String _) => setState(() => _saveError = null);

  Future<void> _save() async {
    if (_saving || !_isValid) return;
    setState(() => _saving = true);
    final result = await ref
        .read(preferencesProvider.notifier)
        .setDisplayName(_controller.text);
    if (!mounted) return;
    setState(() {
      _saving = false;
      _saveError = result.isSuccess ? null : t.permissions.name.saveError;
    });
    if (result.isSuccess) widget.onSaved();
  }

  @override
  Widget build(BuildContext context) {
    final copy = t.permissions.name;
    return FrScaffold(
      body: OnboardingScroll(
        children: [
          OnboardingTopLine(step: 1, onBack: widget.onBack),
          OnboardingHeading(title: copy.title, message: copy.message),
          _SignatureStage(controller: _controller),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: FrField(
              label: copy.label,
              controller: _controller,
              hint: copy.hint,
              help: copy.help,
              error: _error,
              maxLength: Preferences.displayNameMaxLength,
              textInputAction: TextInputAction.done,
              onChanged: _onChanged,
              onSubmitted: (_) => _save(),
            ),
          ),
        ],
      ),
      dock: FrButton.drawn(
        label: copy.next,
        trailingIcon: FrIcons.arrow,
        expand: true,
        loading: _saving,
        onPressed: _isValid ? _save : null,
      ),
    );
  }
}

/// Escenario de la firma (`.sig-stage`): un círculo con un anillo de marcas,
/// la firma que sigue al texto y la leyenda abajo.
class _SignatureStage extends StatelessWidget {
  const _SignatureStage({required this.controller});

  static const double _height = 270;
  static const double _signatureSize = 210;

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final fr = context.fr;
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: SizedBox(
        height: _height,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: const Size.square(_StagePainter.diameter),
              painter: _StagePainter(
                line: fr.colors.line1,
                ticks: fr.colors.line3,
                signal: fr.colors.signal,
              ),
            ),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (context, value, _) => SignalSignature(
                name: value.text,
                size: _signatureSize,
                mode: SignatureMode.speak,
                levelOf: (seconds) => frVoice(seconds) * 0.55,
                radius: 0.4,
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 4,
              child: Text(
                t.permissions.name.signature.toUpperCase(),
                textAlign: TextAlign.center,
                style: fr.type.labelS.copyWith(color: fr.colors.tx3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Círculo de 236 px con borde y halo de señal, y marcas cada 6° en su orilla.
class _StagePainter extends CustomPainter {
  const _StagePainter({
    required this.line,
    required this.ticks,
    required this.signal,
  });

  static const double diameter = 236;

  final Color line;
  final Color ticks;
  final Color signal;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    const radius = diameter / 2;
    final halo = Paint()
      ..shader = RadialGradient(
        colors: [signal.withValues(alpha: 0.06), signal.withValues(alpha: 0)],
        stops: const [0, 0.65],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    final border = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = line;
    final tick = Paint()
      ..strokeWidth = 0.8
      ..color = ticks.withValues(alpha: ticks.a * 0.7);
    canvas
      ..drawCircle(center, radius, halo)
      ..drawCircle(center, radius - 0.5, border);
    for (var i = 0; i < 60; i++) {
      final angle = i * math.pi / 30;
      final direction = Offset(math.cos(angle), math.sin(angle));
      canvas.drawLine(
        center + direction * (radius - 6),
        center + direction * radius,
        tick,
      );
    }
  }

  @override
  bool shouldRepaint(_StagePainter oldDelegate) =>
      oldDelegate.line != line ||
      oldDelegate.ticks != ticks ||
      oldDelegate.signal != signal;
}
