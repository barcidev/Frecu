// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'room_reach_step.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Dice si hay internet para crear una frecu por internet: si el nombre del
/// punto de encuentro se resuelve en 3 s. Sin punto de encuentro, no.
///
/// Se inyecta para que las pruebas decidan si hay internet.

@ProviderFor(internetCheck)
final internetCheckProvider = InternetCheckProvider._();

/// Dice si hay internet para crear una frecu por internet: si el nombre del
/// punto de encuentro se resuelve en 3 s. Sin punto de encuentro, no.
///
/// Se inyecta para que las pruebas decidan si hay internet.

final class InternetCheckProvider
    extends
        $FunctionalProvider<
          Future<bool> Function(),
          Future<bool> Function(),
          Future<bool> Function()
        >
    with $Provider<Future<bool> Function()> {
  /// Dice si hay internet para crear una frecu por internet: si el nombre del
  /// punto de encuentro se resuelve en 3 s. Sin punto de encuentro, no.
  ///
  /// Se inyecta para que las pruebas decidan si hay internet.
  InternetCheckProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'internetCheckProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$internetCheckHash();

  @$internal
  @override
  $ProviderElement<Future<bool> Function()> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Future<bool> Function() create(Ref ref) {
    return internetCheck(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Future<bool> Function() value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Future<bool> Function()>(value),
    );
  }
}

String _$internetCheckHash() => r'baaad266f45f0b152d8b10837715d9860e25de44';
