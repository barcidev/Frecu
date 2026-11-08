// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'new_room_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Reloj de la nueva frecu: la hora con la que se calcula su nota.
///
/// Se inyecta para que las pruebas fijen la hora en lugar de leer la del
/// teléfono.

@ProviderFor(newRoomClock)
final newRoomClockProvider = NewRoomClockProvider._();

/// Reloj de la nueva frecu: la hora con la que se calcula su nota.
///
/// Se inyecta para que las pruebas fijen la hora en lugar de leer la del
/// teléfono.

final class NewRoomClockProvider
    extends
        $FunctionalProvider<
          DateTime Function(),
          DateTime Function(),
          DateTime Function()
        >
    with $Provider<DateTime Function()> {
  /// Reloj de la nueva frecu: la hora con la que se calcula su nota.
  ///
  /// Se inyecta para que las pruebas fijen la hora en lugar de leer la del
  /// teléfono.
  NewRoomClockProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'newRoomClockProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$newRoomClockHash();

  @$internal
  @override
  $ProviderElement<DateTime Function()> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DateTime Function() create(Ref ref) {
    return newRoomClock(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DateTime Function() value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DateTime Function()>(value),
    );
  }
}

String _$newRoomClockHash() => r'cc7eaee589e0ee2ba1659dfc8aa896715cea9423';

/// Generador del código de acceso de una frecu nueva: cuatro cifras de 1000
/// a 9999 al azar.

@ProviderFor(accessCodeGenerator)
final accessCodeGeneratorProvider = AccessCodeGeneratorProvider._();

/// Generador del código de acceso de una frecu nueva: cuatro cifras de 1000
/// a 9999 al azar.

final class AccessCodeGeneratorProvider
    extends
        $FunctionalProvider<
          String Function(),
          String Function(),
          String Function()
        >
    with $Provider<String Function()> {
  /// Generador del código de acceso de una frecu nueva: cuatro cifras de 1000
  /// a 9999 al azar.
  AccessCodeGeneratorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'accessCodeGeneratorProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$accessCodeGeneratorHash();

  @$internal
  @override
  $ProviderElement<String Function()> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  String Function() create(Ref ref) {
    return accessCodeGenerator(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String Function() value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String Function()>(value),
    );
  }
}

String _$accessCodeGeneratorHash() =>
    r'35658b797da2e0fb5aad26451e906c25595f2080';
