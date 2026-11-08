import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frecu/core/design/motion/fr_noise.dart';
import 'package:frecu/core/design/widgets/fr_button.dart';
import 'package:frecu/core/design/widgets/fr_field.dart';
import 'package:frecu/core/design/widgets/fr_sheet.dart';
import 'package:frecu/core/design/widgets/signal_signature.dart';
import 'package:frecu/features/settings/domain/entities/preferences.dart';
import 'package:frecu/features/settings/presentation/providers/preferences_provider.dart';
import 'package:frecu/i18n/strings.g.dart';

/// Hoja para cambiar el nombre visible, con la firma que sigue al texto.
///
/// Guardar solo se habilita si el dominio acepta el nombre
/// ([Preferences.normalizeDisplayName], que cuenta `runes`); al guardarlo se
/// cierra, y si falla queda abierta con el error.
class EditNameSheet extends ConsumerStatefulWidget {
  /// Crea la hoja con [initialName] en el campo.
  const EditNameSheet({this.initialName, super.key});

  /// Nombre con el que abre el campo.
  final String? initialName;

  /// Abre la hoja sobre [context] con el nombre [current].
  static Future<void> show(BuildContext context, {String? current}) =>
      showFrSheet<void>(
        context,
        builder: (_) => EditNameSheet(initialName: current),
      );

  @override
  ConsumerState<EditNameSheet> createState() => _EditNameSheetState();
}

class _EditNameSheetState extends ConsumerState<EditNameSheet> {
  static const double _signatureSize = 120;

  late final TextEditingController _controller = TextEditingController(
    text: widget.initialName ?? '',
  );
  bool _saving = false;
  String? _saveError;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isValid =>
      Preferences.normalizeDisplayName(_controller.text) != null;

  /// Error del campo: el del guardado, o el del largo si el texto no está
  /// vacío pero el dominio no lo acepta.
  String? get _error {
    if (_saveError case final error?) return error;
    if (_controller.text.trim().isEmpty || _isValid) return null;
    return t.settings.editName.tooLong(max: Preferences.displayNameMaxLength);
  }

  void _onChanged(String _) => setState(() => _saveError = null);

  Future<void> _save() async {
    if (_saving || !_isValid) return;
    setState(() => _saving = true);
    final result = await ref
        .read(preferencesProvider.notifier)
        .setDisplayName(_controller.text);
    if (!mounted) return;
    if (result.isSuccess) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _saving = false;
      _saveError = t.settings.editName.saveError;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FrSheet(
      title: t.settings.editName.title,
      message: t.settings.editName.message,
      children: [
        Center(
          child: ValueListenableBuilder<TextEditingValue>(
            valueListenable: _controller,
            builder: (context, value, _) => SignalSignature(
              name: value.text,
              size: _signatureSize,
              mode: SignatureMode.speak,
              levelOf: (seconds) => frVoice(seconds) * 0.55,
              radius: 0.4,
            ),
          ),
        ),
        FrField(
          label: t.settings.displayName,
          controller: _controller,
          hint: t.settings.editName.hint,
          error: _error,
          maxLength: Preferences.displayNameMaxLength,
          autofocus: true,
          textInputAction: TextInputAction.done,
          onChanged: _onChanged,
          onSubmitted: (_) => _save(),
        ),
        FrButton(
          label: t.settings.editName.save,
          loading: _saving,
          expand: true,
          onPressed: _isValid ? _save : null,
        ),
      ],
    );
  }
}
