import 'package:frecu/features/nfc_invite/data/repositories/nfc_invite_repository_impl.dart';
import 'package:frecu/features/nfc_invite/domain/repositories/nfc_invite_repository.dart';
import 'package:frecu/i18n/strings.g.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'nfc_invite_provider.g.dart';

/// Invitación por NFC: leer, grabar etiquetas y hacer de etiqueta.
@Riverpod(keepAlive: true)
NfcInviteRepository nfcInviteRepository(Ref ref) => NfcInviteRepositoryImpl(
  texts: () => (
    read: t.nfcIos.read,
    write: t.nfcIos.write,
    done: t.nfcIos.done,
    notInvite: t.nfcIos.notInvite,
    failed: t.nfcIos.failed,
  ),
);

/// Si el teléfono tiene NFC: sin él no se ofrece.
@Riverpod(keepAlive: true)
Future<bool> nfcSupported(Ref ref) =>
    ref.watch(nfcInviteRepositoryProvider).isSupported();
