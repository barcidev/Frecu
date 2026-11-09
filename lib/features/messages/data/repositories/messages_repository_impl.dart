import 'package:frecu/core/error/failure.dart';
import 'package:frecu/core/result/result.dart';
import 'package:frecu/features/messages/domain/entities/quick_message.dart';
import 'package:frecu/features/messages/domain/repositories/messages_repository.dart';
import 'package:frecu/features/room/data/datasources/signaling_client_datasource.dart';
import 'package:frecu/features/room/data/models/signaling_message.dart';

/// Mensajes rápidos por la señalización de la frecu (`quick_message`).
///
/// El anfitrión pone el remitente y no se lo devuelve a quien lo envía. Los
/// tipos que esta versión no conoce se ignoran.
class MessagesRepositoryImpl implements MessagesRepository {
  /// Crea el repositorio sobre el cliente de señalización compartido.
  MessagesRepositoryImpl(this._signaling);

  final SignalingClientDataSource _signaling;

  @override
  Stream<QuickMessage> watchIncoming() => _signaling.messages
      .where((message) => message is SignalingQuickMessage)
      .cast<SignalingQuickMessage>()
      .map((message) {
        final kind = QuickMessageKind.fromName(message.kind);
        return kind == null
            ? null
            : QuickMessage(senderId: message.peerId, kind: kind);
      })
      .where((message) => message != null)
      .cast<QuickMessage>();

  @override
  Future<Result<void>> send(QuickMessageKind kind) async {
    if (!_signaling.isConnected) {
      return const Result.failure(Failure.hostUnreachable());
    }
    // El anfitrión cambia el id por el del socket que lo envía.
    _signaling.send(SignalingMessage.quickMessage(peerId: '', kind: kind.name));
    return const Result.success(null);
  }
}
