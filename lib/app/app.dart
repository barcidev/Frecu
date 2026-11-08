import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:frecu/app/intro/frecu_intro.dart';
import 'package:frecu/app/needs_onboarding_provider.dart';
import 'package:frecu/app/router/app_router.dart';
import 'package:frecu/app/router/app_router.gr.dart';
import 'package:frecu/app/theme/app_theme.dart';
import 'package:frecu/core/logging/app_logger.dart';
import 'package:frecu/features/settings/domain/entities/theme_preference.dart';
import 'package:frecu/features/settings/presentation/providers/preferences_provider.dart';
import 'package:frecu/i18n/strings.g.dart';

/// Widget raíz de la aplicación Frecu.
///
/// Aplica el tema guardado en las preferencias (Auto sigue al sistema) y
/// cambia de tema en cuanto cambia la preferencia. Al arrancar muestra la
/// intro de la portadora (`FrecuIntroGate`) mientras se abre la primera ruta
/// debajo: el recorrido de la primera vez si aún no hay nombre guardado o no
/// se completó; si no, el inicio.
class FrecuApp extends ConsumerStatefulWidget {
  /// Constructor constante con router inyectable para testing.
  const FrecuApp({super.key, this.appRouter, this.showIntro});

  /// Router para navegación declarativa. Uno inyectado abre su ruta inicial
  /// sin comprobar la primera apertura.
  final AppRouter? appRouter;

  /// Muestra la intro de la portadora antes de la primera ruta; por defecto,
  /// solo al arrancar de verdad (sin router inyectado).
  final bool? showIntro;

  @override
  ConsumerState<FrecuApp> createState() => _FrecuAppState();
}

class _FrecuAppState extends ConsumerState<FrecuApp> {
  late final AppRouter _appRouter;
  late final bool _showIntro;

  @override
  void initState() {
    super.initState();
    _appRouter = widget.appRouter ?? AppRouter();
    _showIntro = widget.showIntro ?? widget.appRouter == null;
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
      routerConfig: _appRouter.config(
        deepLinkBuilder: widget.appRouter == null ? _firstRoute : null,
      ),
      locale: TranslationProvider.of(context).flutterLocale,
      supportedLocales: AppLocaleUtils.supportedLocales,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      builder: _showIntro ? _withIntro : null,
    );
  }

  static Widget _withIntro(BuildContext context, Widget? child) =>
      FrecuIntroGate(child: child ?? const SizedBox.shrink());

  /// Ruta con la que se abre la app: el recorrido de la primera vez si hace
  /// falta y, si no, la del enlace (el inicio). Se decide una sola vez al
  /// abrir; terminar el recorrido guarda que se completó.
  Future<DeepLink> _firstRoute(PlatformDeepLink link) async {
    if (!link.initial) return link;
    try {
      return await _needsOnboarding()
          ? DeepLink.single(const PermissionsRoute())
          : link;
    } on Object catch (e, st) {
      AppLogger.e('Error checking the first opening', e, st);
      return link;
    }
  }

  /// Lee una vez si hace falta el recorrido, sin dejar vivos los permisos
  /// leídos.
  Future<bool> _needsOnboarding() async {
    final subscription = ref.listenManual(
      needsOnboardingProvider.future,
      (_, _) {},
    );
    try {
      return await subscription.read();
    } finally {
      subscription.close();
    }
  }
}

/// Traduce el tema guardado al `ThemeMode` de Flutter: Auto sigue al sistema.
ThemeMode _themeModeOf(ThemePreference preference) => switch (preference) {
  ThemePreference.auto => ThemeMode.system,
  ThemePreference.light => ThemeMode.light,
  ThemePreference.dark => ThemeMode.dark,
};
