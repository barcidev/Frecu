// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bluetooth_invite_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Invitación por Bluetooth: anunciar la frecu y encontrar las cercanas.

@ProviderFor(bluetoothInviteRepository)
final bluetoothInviteRepositoryProvider = BluetoothInviteRepositoryProvider._();

/// Invitación por Bluetooth: anunciar la frecu y encontrar las cercanas.

final class BluetoothInviteRepositoryProvider
    extends
        $FunctionalProvider<
          BluetoothInviteRepository,
          BluetoothInviteRepository,
          BluetoothInviteRepository
        >
    with $Provider<BluetoothInviteRepository> {
  /// Invitación por Bluetooth: anunciar la frecu y encontrar las cercanas.
  BluetoothInviteRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'bluetoothInviteRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$bluetoothInviteRepositoryHash();

  @$internal
  @override
  $ProviderElement<BluetoothInviteRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  BluetoothInviteRepository create(Ref ref) {
    return bluetoothInviteRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BluetoothInviteRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BluetoothInviteRepository>(value),
    );
  }
}

String _$bluetoothInviteRepositoryHash() =>
    r'd753162c26ce8e1c9336fe6eb8ecc058e0dc6ea3';

/// Frecus anunciadas por Bluetooth cerca, también fuera de su red. Como la
/// búsqueda en la red, queda en pausa con una frecu activa.

@ProviderFor(bluetoothNearbyRooms)
final bluetoothNearbyRoomsProvider = BluetoothNearbyRoomsProvider._();

/// Frecus anunciadas por Bluetooth cerca, también fuera de su red. Como la
/// búsqueda en la red, queda en pausa con una frecu activa.

final class BluetoothNearbyRoomsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<NearbyRoom>>,
          List<NearbyRoom>,
          Stream<List<NearbyRoom>>
        >
    with $FutureModifier<List<NearbyRoom>>, $StreamProvider<List<NearbyRoom>> {
  /// Frecus anunciadas por Bluetooth cerca, también fuera de su red. Como la
  /// búsqueda en la red, queda en pausa con una frecu activa.
  BluetoothNearbyRoomsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'bluetoothNearbyRoomsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$bluetoothNearbyRoomsHash();

  @$internal
  @override
  $StreamProviderElement<List<NearbyRoom>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<NearbyRoom>> create(Ref ref) {
    return bluetoothNearbyRooms(ref);
  }
}

String _$bluetoothNearbyRoomsHash() =>
    r'5e17a2a64c18b130d914e6a0d036d0ae62fa7ae1';
