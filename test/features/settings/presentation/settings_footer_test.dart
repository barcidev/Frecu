// P135: CUANDO se abre Ajustes ENTONCES el pie dice «FRECU 0.1.0 · 100% LOCAL · SIN INTERNET» en `labelS`, mayúsculas y `tx3`, con la versión instalada que lee `package_info_plus` (`screens.js`), en español y en inglés; si la versión no se puede leer, dice «FRECU · 100% LOCAL · SIN INTERNET».
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/app/theme/app_theme.dart';
import 'package:frecu/core/design/tokens/fr_colors.dart';
import 'package:frecu/core/design/tokens/fr_type.dart';
import 'package:frecu/features/settings/data/datasources/app_info_datasource.dart';
import 'package:frecu/features/settings/presentation/providers/app_version_provider.dart';
import 'package:frecu/features/settings/presentation/widgets/settings_footer.dart';
import 'package:frecu/i18n/strings.g.dart';
import 'package:package_info_plus/package_info_plus.dart';

PackageInfo _info(String version) => PackageInfo(
  appName: 'Frecu',
  packageName: 'com.frecu.app',
  version: version,
  buildNumber: '1',
);

Future<void> _pumpFooter(WidgetTester tester, AppInfoDataSource source) async {
  await tester.pumpWidget(
    TranslationProvider(
      child: ProviderScope(
        overrides: [appInfoDataSourceProvider.overrideWithValue(source)],
        child: MaterialApp(
          theme: AppTheme.dark,
          home: const Scaffold(body: Center(child: SettingsFooter())),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.es));

  testWidgets('P135: el pie lleva la versión instalada en mayúsculas', (
    tester,
  ) async {
    LocaleSettings.setLocaleSync(AppLocale.es);
    await _pumpFooter(
      tester,
      AppInfoDataSource(read: () async => _info('0.1.0')),
    );

    final footer = find.text('FRECU 0.1.0 · 100% LOCAL · SIN INTERNET');
    expect(footer, findsOneWidget);
    final style = tester.widget<Text>(footer).style!;
    expect(style.fontSize, FrType.standard.labelS.fontSize);
    expect(style.fontFamily, FrType.standard.labelS.fontFamily);
    expect(style.color, FrColors.dark.tx3);
  });

  testWidgets('P135: en inglés', (tester) async {
    await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.en));
    await _pumpFooter(
      tester,
      AppInfoDataSource(read: () async => _info('0.1.0')),
    );

    expect(find.text('FRECU 0.1.0 · 100% LOCAL · NO INTERNET'), findsOneWidget);
  });

  testWidgets('P135: sin versión dice solo Frecu', (tester) async {
    LocaleSettings.setLocaleSync(AppLocale.es);
    await _pumpFooter(
      tester,
      AppInfoDataSource(read: () async => throw StateError('sin plugin')),
    );

    expect(find.text('FRECU · 100% LOCAL · SIN INTERNET'), findsOneWidget);
    expect(SettingsFooter.textFor(null), 'FRECU · 100% LOCAL · SIN INTERNET');
  });

  test(
    'P135: la fuente lee la versión del paquete sin el número de compilación',
    () async {
      final source = AppInfoDataSource(read: () async => _info(' 0.1.0 '));

      expect(await source.version(), '0.1.0');
    },
  );
}
