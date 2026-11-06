import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:frecu/app/router/app_router.dart';
import 'package:frecu/app/theme/app_theme.dart';
import 'package:frecu/i18n/strings.g.dart';

/// Widget raíz de la aplicación Frecu.
class FrecuApp extends StatefulWidget {
  /// Constructor constante con router inyectable para testing.
  const FrecuApp({super.key, this.appRouter});

  /// Router para navegación declarativa.
  final AppRouter? appRouter;

  @override
  State<FrecuApp> createState() => _FrecuAppState();
}

class _FrecuAppState extends State<FrecuApp> {
  late final AppRouter _appRouter;

  @override
  void initState() {
    super.initState();
    _appRouter = widget.appRouter ?? AppRouter();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: t.app.title,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      routerConfig: _appRouter.config(),
      locale: TranslationProvider.of(context).flutterLocale,
      supportedLocales: AppLocaleUtils.supportedLocales,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
    );
  }
}
