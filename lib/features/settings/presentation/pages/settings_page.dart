import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frecu/app/router/app_router.gr.dart';
import 'package:frecu/core/design/fr_theme.dart';
import 'package:frecu/core/design/icons/fr_icon.dart';
import 'package:frecu/core/design/icons/fr_icons.dart';
import 'package:frecu/core/design/widgets/fr_icon_button.dart';
import 'package:frecu/core/design/widgets/fr_scaffold.dart';
import 'package:frecu/core/design/widgets/fr_segmented.dart';
import 'package:frecu/core/design/widgets/fr_toast.dart';
import 'package:frecu/core/result/result.dart';
import 'package:frecu/features/room/domain/entities/talk_mode.dart';
import 'package:frecu/features/settings/domain/entities/locale_preference.dart';
import 'package:frecu/features/settings/domain/entities/preferences.dart';
import 'package:frecu/features/settings/domain/entities/theme_preference.dart';
import 'package:frecu/features/settings/presentation/providers/app_version_provider.dart';
import 'package:frecu/features/settings/presentation/providers/preferences_provider.dart';
import 'package:frecu/features/settings/presentation/widgets/edit_name_sheet.dart';
import 'package:frecu/features/settings/presentation/widgets/language_sheet.dart';
import 'package:frecu/features/settings/presentation/widgets/permissions_row.dart';
import 'package:frecu/features/settings/presentation/widgets/profile_card.dart';
import 'package:frecu/features/settings/presentation/widgets/settings_footer.dart';
import 'package:frecu/features/settings/presentation/widgets/settings_group.dart';
import 'package:frecu/i18n/strings.g.dart';

/// Ajustes: nombre visible con su firma, modo de habla por defecto, idioma y
/// tema.
///
/// Cada cambio se guarda en las preferencias; el idioma y el tema cambian
/// toda la app al instante y, si algo no se pudo guardar, avisa y deja lo
/// guardado.
@RoutePage()
class SettingsPage extends ConsumerWidget {
  /// Constructor constante.
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferences =
        ref.watch(preferencesProvider).value ?? const Preferences();
    return FrScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SettingsAppBar(),
          // Una sola columna corta: se construye entera, también lo que queda
          // bajo el borde.
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ProfileCard(
                    name: preferences.displayName,
                    onEdit: () => EditNameSheet.show(
                      context,
                      current: preferences.displayName,
                    ),
                  ),
                  SettingsSectionLabel(t.settings.voice),
                  _TalkModeGroup(preferences.defaultTalkMode),
                  SettingsSectionLabel(t.settings.general),
                  _GeneralGroup(preferences.localePreference),
                  SettingsSectionLabel(t.settings.appearance),
                  _ThemeGroup(preferences.themePreference),
                  const SizedBox(height: 24),
                  const SettingsFooter(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Guarda con [change] y, si no se pudo, lo avisa con un [FrToast].
Future<void> _saveOrWarn(
  BuildContext context,
  Future<Result<void>> Function() change,
) async {
  final result = await change();
  if (result.isSuccess || !context.mounted) return;
  showFrToast(
    context,
    FrToast.drawn(icon: FrIcons.alert, message: t.settings.saveError),
  );
}

/// Cabecera de 60 px: Atrás, el título centrado y un hueco del ancho del
/// botón para centrarlo.
class _SettingsAppBar extends StatelessWidget {
  const _SettingsAppBar();

  @override
  Widget build(BuildContext context) {
    final fr = context.fr;
    return SizedBox(
      height: 60,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            FrIconButton.drawn(
              icon: FrIcons.back,
              semanticLabel: t.settings.back,
              variant: FrIconButtonVariant.ghost,
              onPressed: () => context.router.maybePop(),
            ),
            Expanded(
              child: Text(
                t.settings.title,
                textAlign: TextAlign.center,
                style: fr.type.title.copyWith(
                  color: fr.colors.tx1,
                  fontSize: 16,
                  height: 1,
                  fontWeight: const FontWeight(640),
                  fontVariations: const [
                    FontVariation.weight(640),
                    FontVariation.width(110),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 48),
          ],
        ),
      ),
    );
  }
}

/// Modo de habla por defecto: PTT o micrófono abierto.
class _TalkModeGroup extends ConsumerWidget {
  const _TalkModeGroup(this.value);

  final TalkMode value;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SettingsGroup(
      children: [
        SettingsRow(
          title: t.settings.defaultTalkMode,
          subtitle: t.settings.defaultTalkModeHelp,
          below: FrSegmented<TalkMode>(
            value: value,
            onChanged: (mode) => _saveOrWarn(
              context,
              () => ref
                  .read(preferencesProvider.notifier)
                  .setDefaultTalkMode(mode),
            ),
            segments: [
              FrSegment(
                value: TalkMode.pushToTalk,
                label: t.settings.talkMode.pushToTalk,
                icon: const FrIcon(FrIcons.walkie),
              ),
              FrSegment(
                value: TalkMode.openMic,
                label: t.settings.talkMode.openMic,
                icon: const FrIcon(FrIcons.openMic),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// General: el idioma de la app, los permisos y la guía del punto de acceso.
class _GeneralGroup extends ConsumerWidget {
  const _GeneralGroup(this.locale);

  final LocalePreference locale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SettingsGroup(
      children: [
        LanguageRow(
          value: locale,
          onChanged: (choice) => _saveOrWarn(
            context,
            () => ref
                .read(preferencesProvider.notifier)
                .setLocalePreference(choice),
          ),
        ),
        const PermissionsRow(),
        SettingsRow(
          title: t.settings.hotspotGuide,
          onPressed: () =>
              unawaited(context.router.push<void>(const HotspotGuideRoute())),
        ),
        SettingsRow(
          title: t.settings.licenses,
          onPressed: () => showLicensePage(
            context: context,
            applicationName: t.app.title,
            applicationVersion: ref.read(appVersionProvider).value,
          ),
        ),
      ],
    );
  }
}

/// Tema de la app: Auto (sigue al teléfono), Claro u Oscuro.
class _ThemeGroup extends ConsumerWidget {
  const _ThemeGroup(this.value);

  /// Ancho del selector, como `.v-settings .row .seg` del prototipo.
  static const double _selectorWidth = 196;

  final ThemePreference value;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SettingsGroup(
      children: [
        SettingsRow(
          title: t.settings.theme,
          subtitle: t.settings.themeHelp,
          trailing: SizedBox(
            width: _selectorWidth,
            child: FrSegmented<ThemePreference>(
              height: 40,
              value: value,
              onChanged: (theme) => _saveOrWarn(
                context,
                () => ref
                    .read(preferencesProvider.notifier)
                    .setThemePreference(theme),
              ),
              segments: [
                FrSegment(
                  value: ThemePreference.auto,
                  label: t.settings.themeMode.auto,
                ),
                FrSegment(
                  value: ThemePreference.light,
                  label: t.settings.themeMode.light,
                ),
                FrSegment(
                  value: ThemePreference.dark,
                  label: t.settings.themeMode.dark,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
