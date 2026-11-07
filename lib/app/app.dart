import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:frecu/app/router/app_router.dart';
import 'package:frecu/app/theme/app_theme.dart';
import 'package:frecu/features/settings/domain/entities/theme_preference.dart';
import 'package:frecu/features/settings/presentation/providers/preferences_provider.dart';
import 'package:frecu/i18n/strings.g.dart';

/// Widget raíz de la aplicación Frecu.
///
/// Aplica el tema guardado en las preferencias (Auto sigue al sistema) y
/// cambia de tema en cuanto cambia la preferencia.
class FrecuApp extends ConsumerStatefulWidget {
  /// Constructor constante con router inyectable para testing.
  const FrecuApp({super.key, this.appRouter});

  /// Router para navegación declarativa.
  final AppRouter? appRouter;

  @override
  ConsumerState<FrecuApp> createState() => _FrecuAppState();
}

class _FrecuAppState extends ConsumerState<FrecuApp> {
  late final AppRouter _appRouter;

  @override
  void initState() {
    super.initState();
    _appRouter = widget.appRouter ?? AppRouter();
  }

  @override
  Widget build(BuildContext context) {
    final themePreference = ref.watch(
      preferencesProvider.select(
        (preferences) =>
            preferences.value?.themePreference ?? ThemePreference.auto,
      ),
    );
    return MaterialApp.router(
      title: t.app.title,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: _themeModeOf(themePreference),
      routerConfig: _appRouter.config(),
      locale: TranslationProvider.of(context).flutterLocale,
      supportedLocales: AppLocaleUtils.supportedLocales,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
    );
  }
}

/// Traduce el tema guardado al `ThemeMode` de Flutter: Auto sigue al sistema.
ThemeMode _themeModeOf(ThemePreference preference) => switch (preference) {
  ThemePreference.auto => ThemeMode.system,
  ThemePreference.light => ThemeMode.light,
  ThemePreference.dark => ThemeMode.dark,
};
