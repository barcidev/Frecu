import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frecu/core/design/fr_theme.dart';
import 'package:frecu/core/design/widgets/fr_icon_button.dart';
import 'package:frecu/core/design/widgets/fr_scaffold.dart';
import 'package:frecu/core/design/widgets/fr_segmented.dart';
import 'package:frecu/core/design/widgets/fr_toast.dart';
import 'package:frecu/core/result/result.dart';
import 'package:frecu/features/room/domain/entities/talk_mode.dart';
import 'package:frecu/features/settings/domain/entities/preferences.dart';
import 'package:frecu/features/settings/domain/entities/theme_preference.dart';
import 'package:frecu/features/settings/presentation/providers/preferences_provider.dart';
import 'package:frecu/features/settings/presentation/widgets/settings_group.dart';
import 'package:frecu/i18n/strings.g.dart';

/// Ajustes: modo de habla por defecto y tema.
///
/// Cada cambio se guarda en las preferencias; el tema cambia toda la app al
/// instante y, si algo no se pudo guardar, avisa y deja lo guardado.
@RoutePage()
class SettingsPage extends ConsumerWidget {
  /// Constructor constante.
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferences =
        ref.watch(preferencesProvider).value ?? const Preferences();
    final fr = context.fr;
    return FrScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SettingsAppBar(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 32),
              children: [
                SettingsSectionLabel(t.settings.voice),
                _TalkModeGroup(preferences.defaultTalkMode),
                SettingsSectionLabel(t.settings.appearance),
                _ThemeGroup(preferences.themePreference),
                const SizedBox(height: 24),
                Text(
                  t.settings.footer,
                  textAlign: TextAlign.center,
                  style: fr.type.labelS.copyWith(color: fr.colors.tx3),
                ),
              ],
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
    FrToast.icon(
      icon: Icons.error_outline_rounded,
      message: t.settings.saveError,
    ),
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
            FrIconButton(
              icon: Icons.arrow_back_rounded,
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
                icon: const Icon(Icons.touch_app_outlined),
              ),
              FrSegment(
                value: TalkMode.openMic,
                label: t.settings.talkMode.openMic,
                icon: const Icon(Icons.mic_none_rounded),
              ),
            ],
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
