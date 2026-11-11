// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'room_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Cliente de señalización WebSocket compartido.

@ProviderFor(signalingClient)
final signalingClientProvider = SignalingClientProvider._();

/// Cliente de señalización WebSocket compartido.

final class SignalingClientProvider
    extends
        $FunctionalProvider<
          SignalingClientDataSource,
          SignalingClientDataSource,
          SignalingClientDataSource
        >
    with $Provider<SignalingClientDataSource> {
  /// Cliente de señalización WebSocket compartido.
  SignalingClientProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'signalingClientProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$signalingClientHash();

  @$internal
  @override
  $ProviderElement<SignalingClientDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SignalingClientDataSource create(Ref ref) {
    return signalingClient(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SignalingClientDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SignalingClientDataSource>(value),
    );
  }
}

String _$signalingClientHash() => r'52ee2a32cec51314ad03c66a3b98970915a38929';

/// Punto de encuentro del modo internet; sin `FRECU_CLOUD_URL` no hay modo
/// internet.

@ProviderFor(cloudConfig)
final cloudConfigProvider = CloudConfigProvider._();

/// Punto de encuentro del modo internet; sin `FRECU_CLOUD_URL` no hay modo
/// internet.

final class CloudConfigProvider
    extends $FunctionalProvider<CloudConfig, CloudConfig, CloudConfig>
    with $Provider<CloudConfig> {
  /// Punto de encuentro del modo internet; sin `FRECU_CLOUD_URL` no hay modo
  /// internet.
  CloudConfigProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cloudConfigProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cloudConfigHash();

  @$internal
  @override
  $ProviderElement<CloudConfig> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CloudConfig create(Ref ref) {
    return cloudConfig(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CloudConfig value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CloudConfig>(value),
    );
  }
}

String _$cloudConfigHash() => r'0336b9b10292b5986f4bb754fda4e6291de89227';

/// Servidores STUN y TURN de las frecus por internet.

@ProviderFor(turnCredentials)
final turnCredentialsProvider = TurnCredentialsProvider._();

/// Servidores STUN y TURN de las frecus por internet.

final class TurnCredentialsProvider
    extends
        $FunctionalProvider<
          TurnCredentialsDataSource,
          TurnCredentialsDataSource,
          TurnCredentialsDataSource
        >
    with $Provider<TurnCredentialsDataSource> {
  /// Servidores STUN y TURN de las frecus por internet.
  TurnCredentialsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'turnCredentialsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$turnCredentialsHash();

  @$internal
  @override
  $ProviderElement<TurnCredentialsDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  TurnCredentialsDataSource create(Ref ref) {
    return turnCredentials(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TurnCredentialsDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TurnCredentialsDataSource>(value),
    );
  }
}

String _$turnCredentialsHash() => r'ae59df9e24dc9aeec44335454632c1b51503d014';

/// Datasource del servicio en primer plano para persistencia.

@ProviderFor(foregroundServiceDataSource)
final foregroundServiceDataSourceProvider =
    ForegroundServiceDataSourceProvider._();

/// Datasource del servicio en primer plano para persistencia.

final class ForegroundServiceDataSourceProvider
    extends
        $FunctionalProvider<
          ForegroundServiceDataSource,
          ForegroundServiceDataSource,
          ForegroundServiceDataSource
        >
    with $Provider<ForegroundServiceDataSource> {
  /// Datasource del servicio en primer plano para persistencia.
  ForegroundServiceDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'foregroundServiceDataSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$foregroundServiceDataSourceHash();

  @$internal
  @override
  $ProviderElement<ForegroundServiceDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ForegroundServiceDataSource create(Ref ref) {
    return foregroundServiceDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ForegroundServiceDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ForegroundServiceDataSource>(value),
    );
  }
}

String _$foregroundServiceDataSourceHash() =>
    r'a963c648e1ae10bae2de89398365e0188529abb7';

/// Toques en «Salir» de la tarjeta de la frecu (Android).

@ProviderFor(notificationLeaveRequests)
final notificationLeaveRequestsProvider = NotificationLeaveRequestsProvider._();

/// Toques en «Salir» de la tarjeta de la frecu (Android).

final class NotificationLeaveRequestsProvider
    extends $FunctionalProvider<AsyncValue<int>, int, Stream<int>>
    with $FutureModifier<int>, $StreamProvider<int> {
  /// Toques en «Salir» de la tarjeta de la frecu (Android).
  NotificationLeaveRequestsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notificationLeaveRequestsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notificationLeaveRequestsHash();

  @$internal
  @override
  $StreamProviderElement<int> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<int> create(Ref ref) {
    return notificationLeaveRequests(ref);
  }
}

String _$notificationLeaveRequestsHash() =>
    r'448b80a239bb7ea4796638e61c795b4296e29a02';

/// Proveedor global singleton del repositorio de sala.

@ProviderFor(roomRepository)
final roomRepositoryProvider = RoomRepositoryProvider._();

/// Proveedor global singleton del repositorio de sala.

final class RoomRepositoryProvider
    extends $FunctionalProvider<RoomRepository, RoomRepository, RoomRepository>
    with $Provider<RoomRepository> {
  /// Proveedor global singleton del repositorio de sala.
  RoomRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'roomRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$roomRepositoryHash();

  @$internal
  @override
  $ProviderElement<RoomRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  RoomRepository create(Ref ref) {
    return roomRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RoomRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RoomRepository>(value),
    );
  }
}

String _$roomRepositoryHash() => r'2fa043e4227227878e20c0d3eb278f70487c0224';

/// Stream de los participantes de la sala activa.

@ProviderFor(roomParticipants)
final roomParticipantsProvider = RoomParticipantsProvider._();

/// Stream de los participantes de la sala activa.

final class RoomParticipantsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Participant>>,
          List<Participant>,
          Stream<List<Participant>>
        >
    with
        $FutureModifier<List<Participant>>,
        $StreamProvider<List<Participant>> {
  /// Stream de los participantes de la sala activa.
  RoomParticipantsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'roomParticipantsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$roomParticipantsHash();

  @$internal
  @override
  $StreamProviderElement<List<Participant>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Participant>> create(Ref ref) {
    return roomParticipants(ref);
  }
}

String _$roomParticipantsHash() => r'5a57766c89b3e144bf1259fb98445d8b47269773';

/// Stream del estado de conexión de la sala.

@ProviderFor(roomStatus)
final roomStatusProvider = RoomStatusProvider._();

/// Stream del estado de conexión de la sala.

final class RoomStatusProvider
    extends
        $FunctionalProvider<
          AsyncValue<RoomStatus>,
          RoomStatus,
          Stream<RoomStatus>
        >
    with $FutureModifier<RoomStatus>, $StreamProvider<RoomStatus> {
  /// Stream del estado de conexión de la sala.
  RoomStatusProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'roomStatusProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$roomStatusHash();

  @$internal
  @override
  $StreamProviderElement<RoomStatus> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<RoomStatus> create(Ref ref) {
    return roomStatus(ref);
  }
}

String _$roomStatusHash() => r'af945dc9ce617e95f2fc40fdf93bb5da18f2334c';

/// Traspaso de la frecu, si el repositorio lo admite (un doble de
/// `RoomRepository` no): sin él, la frecu se sale como siempre.

@ProviderFor(roomHandover)
final roomHandoverProvider = RoomHandoverProvider._();

/// Traspaso de la frecu, si el repositorio lo admite (un doble de
/// `RoomRepository` no): sin él, la frecu se sale como siempre.

final class RoomHandoverProvider
    extends $FunctionalProvider<RoomHandover?, RoomHandover?, RoomHandover?>
    with $Provider<RoomHandover?> {
  /// Traspaso de la frecu, si el repositorio lo admite (un doble de
  /// `RoomRepository` no): sin él, la frecu se sale como siempre.
  RoomHandoverProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'roomHandoverProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$roomHandoverHash();

  @$internal
  @override
  $ProviderElement<RoomHandover?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  RoomHandover? create(Ref ref) {
    return roomHandover(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RoomHandover? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RoomHandover?>(value),
    );
  }
}

String _$roomHandoverHash() => r'5a32dac9896c7d282b4877e3934d38506a9970d8';

/// Sucesión, turno y estado de la frecu que mandó el anfitrión.

@ProviderFor(roomSuccession)
final roomSuccessionProvider = RoomSuccessionProvider._();

/// Sucesión, turno y estado de la frecu que mandó el anfitrión.

final class RoomSuccessionProvider
    extends
        $FunctionalProvider<
          AsyncValue<RoomSuccession?>,
          RoomSuccession?,
          Stream<RoomSuccession?>
        >
    with $FutureModifier<RoomSuccession?>, $StreamProvider<RoomSuccession?> {
  /// Sucesión, turno y estado de la frecu que mandó el anfitrión.
  RoomSuccessionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'roomSuccessionProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$roomSuccessionHash();

  @$internal
  @override
  $StreamProviderElement<RoomSuccession?> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<RoomSuccession?> create(Ref ref) {
    return roomSuccession(ref);
  }
}

String _$roomSuccessionHash() => r'13737b811e583c3068912b02785c1c717cee7808';

/// Cada vez que otra persona (o este teléfono) toma la frecu.

@ProviderFor(hostChanges)
final hostChangesProvider = HostChangesProvider._();

/// Cada vez que otra persona (o este teléfono) toma la frecu.

final class HostChangesProvider
    extends
        $FunctionalProvider<
          AsyncValue<HostChange>,
          HostChange,
          Stream<HostChange>
        >
    with $FutureModifier<HostChange>, $StreamProvider<HostChange> {
  /// Cada vez que otra persona (o este teléfono) toma la frecu.
  HostChangesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'hostChangesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$hostChangesHash();

  @$internal
  @override
  $StreamProviderElement<HostChange> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<HostChange> create(Ref ref) {
    return hostChanges(ref);
  }
}

String _$hostChangesHash() => r'81fb72d84065c43e96a6fdc4833853d77dbebb75';

/// Dirección IP local del dispositivo.

@ProviderFor(localIp)
final localIpProvider = LocalIpProvider._();

/// Dirección IP local del dispositivo.

final class LocalIpProvider
    extends $FunctionalProvider<AsyncValue<String?>, String?, FutureOr<String?>>
    with $FutureModifier<String?>, $FutureProvider<String?> {
  /// Dirección IP local del dispositivo.
  LocalIpProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'localIpProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$localIpHash();

  @$internal
  @override
  $FutureProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String?> create(Ref ref) {
    return localIp(ref);
  }
}

String _$localIpHash() => r'5be2a8f3cfbbd6b3cb9f0399734fb6b9d321ec0e';

/// Gestor del ciclo de vida y estado de la sala activa.

@ProviderFor(RoomNotifier)
final roomProvider = RoomNotifierProvider._();

/// Gestor del ciclo de vida y estado de la sala activa.
final class RoomNotifierProvider
    extends $NotifierProvider<RoomNotifier, Room?> {
  /// Gestor del ciclo de vida y estado de la sala activa.
  RoomNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'roomProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$roomNotifierHash();

  @$internal
  @override
  RoomNotifier create() => RoomNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Room? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Room?>(value),
    );
  }
}

String _$roomNotifierHash() => r'61897b520a1737fbd38ec3d10a30d6173437d54a';

/// Gestor del ciclo de vida y estado de la sala activa.

abstract class _$RoomNotifier extends $Notifier<Room?> {
  Room? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<Room?, Room?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Room?, Room?>,
              Room?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
