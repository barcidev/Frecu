// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'share_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Compartir del sistema (WhatsApp, mensajes…); en pruebas se reemplaza.

@ProviderFor(shareText)
final shareTextProvider = ShareTextProvider._();

/// Compartir del sistema (WhatsApp, mensajes…); en pruebas se reemplaza.

final class ShareTextProvider
    extends $FunctionalProvider<ShareText, ShareText, ShareText>
    with $Provider<ShareText> {
  /// Compartir del sistema (WhatsApp, mensajes…); en pruebas se reemplaza.
  ShareTextProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'shareTextProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$shareTextHash();

  @$internal
  @override
  $ProviderElement<ShareText> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ShareText create(Ref ref) {
    return shareText(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ShareText value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ShareText>(value),
    );
  }
}

String _$shareTextHash() => r'0b8d22589a55001de2298d8eb627b68f0c02e886';
