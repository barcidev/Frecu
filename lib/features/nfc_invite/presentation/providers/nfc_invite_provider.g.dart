// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nfc_invite_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Invitación por NFC: leer, grabar etiquetas y hacer de etiqueta.

@ProviderFor(nfcInviteRepository)
final nfcInviteRepositoryProvider = NfcInviteRepositoryProvider._();

/// Invitación por NFC: leer, grabar etiquetas y hacer de etiqueta.

final class NfcInviteRepositoryProvider
    extends
        $FunctionalProvider<
          NfcInviteRepository,
          NfcInviteRepository,
          NfcInviteRepository
        >
    with $Provider<NfcInviteRepository> {
  /// Invitación por NFC: leer, grabar etiquetas y hacer de etiqueta.
  NfcInviteRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'nfcInviteRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$nfcInviteRepositoryHash();

  @$internal
  @override
  $ProviderElement<NfcInviteRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  NfcInviteRepository create(Ref ref) {
    return nfcInviteRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NfcInviteRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NfcInviteRepository>(value),
    );
  }
}

String _$nfcInviteRepositoryHash() =>
    r'f625f22632b380608d7663f7d8b5386cc78cfe52';

/// Si el teléfono tiene NFC: sin él no se ofrece.

@ProviderFor(nfcSupported)
final nfcSupportedProvider = NfcSupportedProvider._();

/// Si el teléfono tiene NFC: sin él no se ofrece.

final class NfcSupportedProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  /// Si el teléfono tiene NFC: sin él no se ofrece.
  NfcSupportedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'nfcSupportedProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$nfcSupportedHash();

  @$internal
  @override
  $FutureProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    return nfcSupported(ref);
  }
}

String _$nfcSupportedHash() => r'a4f5490506f11be7bf3bfba53344f92778ba41ae';
