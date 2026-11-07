import 'package:flutter/material.dart';

/// Botón interactivo Push-to-Talk (PTT) que transmite mientras se mantiene presionado.
class PttButton extends StatelessWidget {
  /// Constructor constante.
  const PttButton({
    required this.isTalking,
    required this.onStartTalking,
    required this.onStopTalking,
    this.label,
    this.activeLabel,
    super.key,
  });

  /// Indica si el micrófono está transmitiendo audio activamente.
  final bool isTalking;

  /// Callback invocado cuando se inicia la presión del botón (`onPointerDown`).
  final VoidCallback onStartTalking;

  /// Callback invocado cuando se libera o cancela la presión (`onPointerUp` / `onPointerCancel`).
  final VoidCallback onStopTalking;

  /// Texto mostrado en estado de reposo.
  final String? label;

  /// Texto mostrado en estado de transmisión activa.
  final String? activeLabel;

  BoxDecoration _buildDecoration(ColorScheme colorScheme) {
    final backgroundColor = isTalking
        ? colorScheme.error
        : colorScheme.primaryContainer;
    return BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(16),
      boxShadow: isTalking
          ? [
              BoxShadow(
                color: colorScheme.error.withValues(alpha: 0.4),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ]
          : null,
    );
  }

  Widget _buildContent(ThemeData theme, Color foregroundColor) {
    final text = isTalking
        ? (activeLabel ?? 'Hablando...')
        : (label ?? 'Mantén presionado para hablar');

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          isTalking ? Icons.mic : Icons.mic_none,
          color: foregroundColor,
          size: 28,
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            text,
            style: theme.textTheme.titleMedium?.copyWith(
              color: foregroundColor,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final foregroundColor = isTalking
        ? colorScheme.onError
        : colorScheme.onPrimaryContainer;

    return Listener(
      key: const Key('ptt_button'),
      onPointerDown: (_) => onStartTalking(),
      onPointerUp: (_) => onStopTalking(),
      onPointerCancel: (_) => onStopTalking(),
      child: AnimatedContainer(
        key: isTalking
            ? const Key('ptt_button_active')
            : const Key('ptt_button_idle'),
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: _buildDecoration(colorScheme),
        child: _buildContent(theme, foregroundColor),
      ),
    );
  }
}
