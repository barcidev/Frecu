import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frecu/core/design/fr_theme.dart';
import 'package:frecu/features/settings/presentation/providers/app_version_provider.dart';
import 'package:frecu/i18n/strings.g.dart';

/// Pie de Ajustes (`v-settings` del prototipo): «FRECU 0.1.0 · 100% LOCAL ·
/// SIN INTERNET» en `labelS`, mayúsculas y `tx3`, con la versión instalada.
/// Mientras la versión no se conoce (o si no se puede leer), dice solo
/// «FRECU».
class SettingsFooter extends ConsumerWidget {
  /// Constructor constante.
  const SettingsFooter({super.key});

  /// Texto del pie para [version], en mayúsculas.
  static String textFor(String? version) => t.settings
      .footer(
        app: version == null
            ? t.app.title
            : t.settings.appVersion(version: version),
      )
      .toUpperCase();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fr = context.fr;
    final version = ref.watch(appVersionProvider).value;
    return Text(
      textFor(version),
      key: const Key('settings_footer'),
      textAlign: TextAlign.center,
      style: fr.type.labelS.copyWith(color: fr.colors.tx3),
    );
  }
}
