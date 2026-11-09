// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'messages_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Repositorio de mensajes rápidos sobre la señalización compartida.

@ProviderFor(messagesRepository)
final messagesRepositoryProvider = MessagesRepositoryProvider._();

/// Repositorio de mensajes rápidos sobre la señalización compartida.

final class MessagesRepositoryProvider
    extends
        $FunctionalProvider<
          MessagesRepository,
          MessagesRepository,
          MessagesRepository
        >
    with $Provider<MessagesRepository> {
  /// Repositorio de mensajes rápidos sobre la señalización compartida.
  MessagesRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'messagesRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$messagesRepositoryHash();

  @$internal
  @override
  $ProviderElement<MessagesRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  MessagesRepository create(Ref ref) {
    return messagesRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MessagesRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MessagesRepository>(value),
    );
  }
}

String _$messagesRepositoryHash() =>
    r'be2b0cb526c283523afe72aa13df9c92901fea33';

/// Mensajes rápidos que llegan de los demás.

@ProviderFor(incomingQuickMessages)
final incomingQuickMessagesProvider = IncomingQuickMessagesProvider._();

/// Mensajes rápidos que llegan de los demás.

final class IncomingQuickMessagesProvider
    extends
        $FunctionalProvider<
          AsyncValue<QuickMessage>,
          QuickMessage,
          Stream<QuickMessage>
        >
    with $FutureModifier<QuickMessage>, $StreamProvider<QuickMessage> {
  /// Mensajes rápidos que llegan de los demás.
  IncomingQuickMessagesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'incomingQuickMessagesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$incomingQuickMessagesHash();

  @$internal
  @override
  $StreamProviderElement<QuickMessage> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<QuickMessage> create(Ref ref) {
    return incomingQuickMessages(ref);
  }
}

String _$incomingQuickMessagesHash() =>
    r'b2761d5bebe0d0066f81513a4828ed29213a4324';

/// SOS que llegaron y aún no se atendieron, el más antiguo primero; uno por
/// persona.

@ProviderFor(SosAlerts)
final sosAlertsProvider = SosAlertsProvider._();

/// SOS que llegaron y aún no se atendieron, el más antiguo primero; uno por
/// persona.
final class SosAlertsProvider
    extends $NotifierProvider<SosAlerts, List<QuickMessage>> {
  /// SOS que llegaron y aún no se atendieron, el más antiguo primero; uno por
  /// persona.
  SosAlertsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sosAlertsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sosAlertsHash();

  @$internal
  @override
  SosAlerts create() => SosAlerts();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<QuickMessage> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<QuickMessage>>(value),
    );
  }
}

String _$sosAlertsHash() => r'df6d92f9b32b242e8cd0be620150e00171a7ea5f';

/// SOS que llegaron y aún no se atendieron, el más antiguo primero; uno por
/// persona.

abstract class _$SosAlerts extends $Notifier<List<QuickMessage>> {
  List<QuickMessage> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<List<QuickMessage>, List<QuickMessage>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<QuickMessage>, List<QuickMessage>>,
              List<QuickMessage>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
