import 'package:frecu/core/haptics/haptics.dart';
import 'package:frecu/core/result/result.dart';
import 'package:frecu/features/messages/data/repositories/messages_repository_impl.dart';
import 'package:frecu/features/messages/domain/entities/quick_message.dart';
import 'package:frecu/features/messages/domain/repositories/messages_repository.dart';
import 'package:frecu/features/room/presentation/providers/room_provider.dart';
import 'package:frecu/features/settings/presentation/providers/vibration_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'messages_provider.g.dart';

/// Repositorio de mensajes rápidos sobre la señalización compartida.
@Riverpod(keepAlive: true)
MessagesRepository messagesRepository(Ref ref) =>
    MessagesRepositoryImpl(ref.watch(signalingClientProvider));

/// Mensajes rápidos que llegan de los demás.
@riverpod
Stream<QuickMessage> incomingQuickMessages(Ref ref) =>
    ref.watch(messagesRepositoryProvider).watchIncoming();

/// SOS que llegaron y aún no se atendieron, el más antiguo primero; uno por
/// persona.
@Riverpod(keepAlive: true)
class SosAlerts extends _$SosAlerts {
  @override
  List<QuickMessage> build() {
    final subscription = ref
        .watch(messagesRepositoryProvider)
        .watchIncoming()
        .where((message) => message.kind == QuickMessageKind.sos)
        .listen(_add);
    ref.onDispose(subscription.cancel);
    return const [];
  }

  void _add(QuickMessage sos) {
    if (state.any((alert) => alert.senderId == sos.senderId)) return;
    state = [...state, sos];
    _vibrate();
  }

  void _vibrate() => ref.read(vibrationProvider)(HapticPattern.sos).ignore();

  /// Vuelve a vibrar si sigue habiendo un SOS sin atender (la pantalla lo
  /// llama cada pocos segundos).
  void remind() {
    if (state.isNotEmpty) _vibrate();
  }

  /// Atiende el SOS de [senderId]; con [onMyWay] le responde «Voy en
  /// camino» a toda la frecu.
  Future<Result<void>> dismiss(String senderId, {bool onMyWay = false}) async {
    state = [
      for (final alert in state)
        if (alert.senderId != senderId) alert,
    ];
    if (!onMyWay) return const Result.success(null);
    return ref.read(messagesRepositoryProvider).send(QuickMessageKind.onMyWay);
  }

  /// Olvida todos, p. ej. al salir de la frecu.
  void clear() {
    // La app puede estar cerrándose con el provider ya liberado.
    if (!ref.mounted) return;
    state = const [];
  }
}
