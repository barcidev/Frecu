// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_version_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Proveedor global de la fuente de datos de la app instalada.

@ProviderFor(appInfoDataSource)
final appInfoDataSourceProvider = AppInfoDataSourceProvider._();

/// Proveedor global de la fuente de datos de la app instalada.

final class AppInfoDataSourceProvider
    extends
        $FunctionalProvider<
          AppInfoDataSource,
          AppInfoDataSource,
          AppInfoDataSource
        >
    with $Provider<AppInfoDataSource> {
  /// Proveedor global de la fuente de datos de la app instalada.
  AppInfoDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appInfoDataSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appInfoDataSourceHash();

  @$internal
  @override
  $ProviderElement<AppInfoDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AppInfoDataSource create(Ref ref) {
    return appInfoDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppInfoDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppInfoDataSource>(value),
    );
  }
}

String _$appInfoDataSourceHash() => r'4b5f35189cb2ab26815f37f3fb2f47ad7ab51d22';

/// Versión de la app instalada (p. ej. `0.1.0`); nula si no se pudo leer o
/// viene vacía.

@ProviderFor(appVersion)
final appVersionProvider = AppVersionProvider._();

/// Versión de la app instalada (p. ej. `0.1.0`); nula si no se pudo leer o
/// viene vacía.

final class AppVersionProvider
    extends $FunctionalProvider<AsyncValue<String?>, String?, FutureOr<String?>>
    with $FutureModifier<String?>, $FutureProvider<String?> {
  /// Versión de la app instalada (p. ej. `0.1.0`); nula si no se pudo leer o
  /// viene vacía.
  AppVersionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appVersionProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appVersionHash();

  @$internal
  @override
  $FutureProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String?> create(Ref ref) {
    return appVersion(ref);
  }
}

String _$appVersionHash() => r'dfc852bd20c36592a7682e752e9b4bc6507bac9d';
