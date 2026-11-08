import 'package:flutter/material.dart';
import 'package:frecu/core/design/fr_theme.dart';
import 'package:frecu/core/design/icons/fr_icon.dart';
import 'package:frecu/core/design/icons/fr_icons.dart';
import 'package:frecu/core/design/widgets/fr_pressable.dart';
import 'package:frecu/core/design/widgets/fr_sheet.dart';
import 'package:frecu/features/settings/domain/entities/locale_preference.dart';
import 'package:frecu/features/settings/presentation/widgets/settings_group.dart';
import 'package:frecu/i18n/strings.g.dart';

/// Idioma fijo de [preference]; nulo en Auto, que sigue al teléfono.
AppLocale? _localeOf(LocalePreference preference) => switch (preference) {
  LocalePreference.auto => null,
  LocalePreference.es => AppLocale.es,
  LocalePreference.en => AppLocale.en,
};

/// Nombre de [locale], escrito en su propio idioma.
String _nameOf(AppLocale locale) => switch (locale) {
  AppLocale.es => t.settings.language.es,
  AppLocale.en => t.settings.language.en,
};

/// Código corto de [locale] (`ES`, `EN`).
String _codeOf(AppLocale locale) => locale.languageCode.toUpperCase();

/// Fila «Idioma» de Ajustes (`UI.row('Idioma', 'Español', 'ES ›')`): la
/// elección guardada, el código del idioma en uso y un chevron.
///
/// Al tocarla abre [LanguageSheet] y, si vuelve una elección distinta, la
/// entrega a [onChanged].
class LanguageRow extends StatelessWidget {
  /// Crea la fila con la elección [value].
  const LanguageRow({required this.value, required this.onChanged, super.key});

  /// Idioma elegido.
  final LocalePreference value;

  /// Recibe la nueva elección.
  final ValueChanged<LocalePreference> onChanged;

  Future<void> _choose(BuildContext context) async {
    final choice = await LanguageSheet.show(context, current: value);
    if (choice == null || choice == value) return;
    onChanged(choice);
  }

  @override
  Widget build(BuildContext context) {
    final fr = context.fr;
    final inUse = TranslationProvider.of(context).locale;
    final copy = t.settings.language;
    return SettingsRow(
      title: copy.title,
      subtitle: switch (_localeOf(value)) {
        null => copy.autoValue(language: _nameOf(inUse)),
        final locale => _nameOf(locale),
      },
      trailing: Text(
        _codeOf(inUse),
        style: fr.type.labelS.copyWith(color: fr.colors.tx2),
      ),
      onPressed: () => _choose(context),
    );
  }
}

/// Hoja para elegir el idioma de la app: Auto, Español o English, con la
/// elección actual marcada. Elegir una cierra la hoja y la devuelve.
class LanguageSheet extends StatelessWidget {
  /// Crea la hoja con [current] marcada.
  const LanguageSheet({required this.current, super.key});

  /// Idioma elegido ahora.
  final LocalePreference current;

  /// Abre la hoja sobre [context]; devuelve la elección o nulo si se cerró
  /// sin elegir.
  static Future<LocalePreference?> show(
    BuildContext context, {
    required LocalePreference current,
  }) => showFrSheet<LocalePreference>(
    context,
    builder: (_) => LanguageSheet(current: current),
  );

  @override
  Widget build(BuildContext context) {
    final copy = t.settings.language;
    return SingleChildScrollView(
      child: FrSheet(
        title: copy.title,
        message: copy.message,
        children: [
          Column(
            spacing: 8,
            children: [
              for (final option in LocalePreference.values)
                LanguageOption(
                  key: Key('language_option_${option.name}'),
                  value: option,
                  selected: option == current,
                  onPressed: () => Navigator.of(context).pop(option),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Opción de un idioma (`.opt`): caja con el globo o el código, nombre,
/// explicación en Auto y marca de elegida.
class LanguageOption extends StatelessWidget {
  /// Crea la opción de [value].
  const LanguageOption({
    required this.value,
    required this.selected,
    required this.onPressed,
    super.key,
  });

  /// Idioma que elige.
  final LocalePreference value;

  /// Es la elección actual.
  final bool selected;

  /// Elige el idioma.
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      child: FrPressable(
        onPressed: onPressed,
        pressedScale: 0.98,
        builder: (context, _, _) => _surface(context.fr),
      ),
    );
  }

  Widget _surface(FrTheme fr) {
    final c = fr.colors;
    return AnimatedContainer(
      duration: fr.motion.smooth,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.bg1,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: selected ? c.signal.withValues(alpha: 0.55) : c.line1,
        ),
        boxShadow: [
          if (selected)
            BoxShadow(
              color: c.signal.withValues(alpha: 0.8),
              blurRadius: 30,
              spreadRadius: -16,
            ),
        ],
      ),
      child: Row(
        children: [
          _box(fr),
          const SizedBox(width: 14),
          Expanded(child: _texts(fr)),
          const SizedBox(width: 14),
          _check(fr),
        ],
      ),
    );
  }

  /// Caja de 44 px: el globo en Auto y el código en los idiomas.
  Widget _box(FrTheme fr) {
    final c = fr.colors;
    final ink = selected ? c.signalFg : c.tx1;
    final locale = _localeOf(value);
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? c.signal.withValues(alpha: 0.1) : c.bg2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.line1),
      ),
      child: locale == null
          ? FrIcon(FrIcons.globe, color: ink)
          : Text(_codeOf(locale), style: fr.type.label.copyWith(color: ink)),
    );
  }

  Widget _texts(FrTheme fr) {
    final copy = t.settings.language;
    final locale = _localeOf(value);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 4,
      children: [
        Text(
          locale == null ? copy.auto : _nameOf(locale),
          style: fr.type.body.copyWith(
            fontSize: 15,
            height: 1.2,
            fontWeight: FontWeight.w600,
            fontVariations: const [FontVariation.weight(600)],
            color: fr.colors.tx1,
          ),
        ),
        if (locale == null)
          Text(
            copy.autoHelp.toUpperCase(),
            style: fr.type.labelS.copyWith(color: fr.colors.tx3),
          ),
      ],
    );
  }

  Widget _check(FrTheme fr) {
    final c = fr.colors;
    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? c.signal : null,
        border: selected ? null : Border.all(color: c.line3, width: 1.5),
      ),
      child: selected
          ? FrIcon(FrIcons.check, size: 16, color: c.signalInk)
          : null,
    );
  }
}
