import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frecu/features/nfc_invite/domain/repositories/nfc_invite_repository.dart';
import 'package:frecu/features/nfc_invite/presentation/providers/nfc_invite_provider.dart';
import 'package:frecu/features/room/domain/entities/room_invite.dart';
import 'package:frecu/features/room/domain/usecases/build_invite_qr.dart';
import 'package:frecu/features/room/presentation/providers/room_provider.dart';

/// Invitación por NFC en la frecu activa: mientras se está en ella, un
/// teléfono Android hace de etiqueta con la misma invitación del QR, para
/// quien acerque el suyo («Acerca otro teléfono al tuyo»). Al salir deja de
/// hacerlo. En iPhone no se puede: solo se graban etiquetas.
class RoomNfcShare {
  NfcInviteRepository? _repository;
  ProviderSubscription<String?>? _watch;
  String? _current;

  /// Empieza a seguir la frecu con [ref] (en el `initState`).
  void start(WidgetRef ref) {
    _repository = ref.read(nfcInviteRepositoryProvider);
    _watch = ref.listenManual<String?>(
      _invite,
      (_, next) => _apply(next),
      fireImmediately: true,
    );
  }

  /// La invitación de la frecu activa (la del QR), o nula sin frecu.
  static final _invite = Provider.autoDispose<String?>((ref) {
    final room = ref.watch(roomNotifierProvider);
    if (room == null) return null;
    return const BuildInviteQr().buildUri(
      RoomInvite(
        host: room.hostAddress,
        port: room.port,
        roomId: room.id,
        accessCode: room.accessCode,
        note: room.note,
        name: room.name,
        wifi: room.wifi,
        internetId: room.internetId,
      ),
    );
  });

  void _apply(String? invite) {
    final repository = _repository;
    if (repository == null || invite == _current) return;
    _current = invite;
    unawaited(repository.share(invite));
  }

  /// Deja de hacer de etiqueta y de escuchar (en el `dispose`).
  void stop() {
    _watch?.close();
    _watch = null;
    if (_current != null) unawaited(_repository?.share(null));
    _current = null;
    _repository = null;
  }
}
