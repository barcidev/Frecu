import 'package:frecu/core/result/result.dart';
import 'package:frecu/features/messages/domain/entities/quick_message.dart';

/// Mensajes rápidos y SOS de la frecu activa.
abstract interface class MessagesRepository {
  /// Los mensajes que envían los demás, al llegar. Los propios no vuelven.
  Stream<QuickMessage> watchIncoming();

  /// Envía [kind] a toda la frecu; falla si no hay conexión con el
  /// anfitrión.
  Future<Result<void>> send(QuickMessageKind kind);
}
