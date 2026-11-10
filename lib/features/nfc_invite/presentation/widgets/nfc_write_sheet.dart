import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frecu/core/design/icons/fr_icons.dart';
import 'package:frecu/core/design/widgets/fr_banner.dart';
import 'package:frecu/core/design/widgets/fr_button.dart';
import 'package:frecu/core/design/widgets/fr_sheet.dart';
import 'package:frecu/core/error/failure.dart';
import 'package:frecu/core/result/result.dart';
import 'package:frecu/features/lobby/presentation/widgets/pin_join_sheet.dart';
import 'package:frecu/features/nfc_invite/domain/repositories/nfc_invite_repository.dart';
import 'package:frecu/features/nfc_invite/presentation/providers/nfc_invite_provider.dart';
import 'package:frecu/features/nfc_invite/presentation/widgets/nfc_join_sheet.dart';
import 'package:frecu/i18n/strings.g.dart';

/// Hoja «Grabar invitación»: espera una etiqueta NFC y graba en ella la
/// invitación de la frecu (la misma del QR). Al grabarla lo dice un momento
/// y se cierra; si la etiqueta no se puede grabar, no cabe o falla, lo dice
/// con Reintentar. Cerrar cancela.
class NfcWriteSheet extends ConsumerStatefulWidget {
  /// Crea la hoja para grabar [invite].
  const NfcWriteSheet({required this.invite, super.key});

  /// Invitación que se graba (`frecu://join?…`).
  final String invite;

  /// Lo que se ve «Invitación grabada» antes de cerrarse.
  static const Duration doneDelay = Duration(milliseconds: 900);

  /// Abre la hoja sobre [context]; devuelve si se grabó.
  static Future<bool> show(BuildContext context, String invite) async =>
      await showFrSheet<bool>(
        context,
        builder: (_) => NfcWriteSheet(invite: invite),
      ) ??
      false;

  @override
  ConsumerState<NfcWriteSheet> createState() => _NfcWriteSheetState();
}

class _NfcWriteSheetState extends ConsumerState<NfcWriteSheet> {
  bool _done = false;
  NfcFailureReason? _failure;
  int _attempt = 0;

  /// Se lee al montar: al desmontar ya no se puede usar `ref`.
  late final NfcInviteRepository _nfc;

  @override
  void initState() {
    super.initState();
    _nfc = ref.read(nfcInviteRepositoryProvider);
    unawaited(_write());
  }

  @override
  void dispose() {
    if (!_done) unawaited(_nfc.cancel());
    super.dispose();
  }

  Future<void> _write() async {
    final attempt = ++_attempt;
    final result = await _nfc.writeInvite(widget.invite);
    if (!mounted || attempt != _attempt) return;
    switch (result) {
      case Success():
        unawaited(HapticFeedback.lightImpact());
        setState(() => _done = true);
        await Future<void>.delayed(NfcWriteSheet.doneDelay);
        if (mounted) Navigator.of(context).pop(true);
      case FailureResult(:final failure):
        final reason = failure.maybeWhen(
          nfc: (reason) => reason,
          orElse: () => NfcFailureReason.failed,
        );
        if (reason == NfcFailureReason.cancelled) {
          return Navigator.of(context).pop(false);
        }
        setState(() => _failure = reason);
    }
  }

  void _retry() {
    setState(() => _failure = null);
    unawaited(_write());
  }

  @override
  Widget build(BuildContext context) {
    final copy = t.room.sheets.invite.nfcSheet;
    final failure = _failure;
    return SingleChildScrollView(
      child: FrSheet(
        children: [
          JoinSheetHeader(
            kicker: copy.kicker,
            title: _done ? copy.done : copy.title,
            message: copy.message,
            onClose: () => Navigator.of(context).maybePop(false),
          ),
          Center(child: NfcStage(found: _done)),
          if (failure != null) ...[
            FrBanner.drawn(
              key: const Key('nfc_write_failure'),
              tone: FrBannerTone.alert,
              icon: FrIcons.nfc,
              title: switch (failure) {
                NfcFailureReason.readOnly => copy.readOnly,
                NfcFailureReason.tooSmall => copy.tooSmall,
                _ => copy.failed,
              },
            ),
            FrButton.drawn(
              label: copy.retry,
              icon: FrIcons.regen,
              expand: true,
              onPressed: _retry,
            ),
          ],
        ],
      ),
    );
  }
}
