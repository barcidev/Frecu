import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frecu/core/design/fr_theme.dart';
import 'package:frecu/core/design/icons/fr_icon.dart';
import 'package:frecu/core/design/icons/fr_icons.dart';
import 'package:frecu/core/design/widgets/fr_banner.dart';
import 'package:frecu/core/design/widgets/fr_button.dart';
import 'package:frecu/core/design/widgets/fr_sheet.dart';
import 'package:frecu/core/error/failure.dart';
import 'package:frecu/core/result/result.dart';
import 'package:frecu/features/lobby/presentation/widgets/pin_join_sheet.dart';
import 'package:frecu/features/nfc_invite/domain/repositories/nfc_invite_repository.dart';
import 'package:frecu/features/nfc_invite/presentation/providers/nfc_invite_provider.dart';
import 'package:frecu/i18n/strings.g.dart';

/// Hoja «Unirse por NFC» (`SH.nfc` del prototipo): espera a que se acerque
/// el teléfono del anfitrión o una etiqueta de la frecu y, al leer la
/// invitación, la muestra encontrada un momento y se cierra con ella (el
/// inicio la abre como un QR leído). Si lo que se acercó no la trae o falla,
/// lo dice con Reintentar. Cerrar cancela la lectura.
class NfcJoinSheet extends ConsumerStatefulWidget {
  /// Crea la hoja.
  const NfcJoinSheet({super.key});

  /// Lo que se ve «Frecu encontrada» antes de cerrarse.
  static const Duration foundDelay = Duration(milliseconds: 700);

  /// Abre la hoja sobre [context]; devuelve la invitación leída
  /// (`frecu://join?…`), o nula si se cerró.
  static Future<String?> show(BuildContext context) =>
      showFrSheet<String>(context, builder: (_) => const NfcJoinSheet());

  @override
  ConsumerState<NfcJoinSheet> createState() => _NfcJoinSheetState();
}

class _NfcJoinSheetState extends ConsumerState<NfcJoinSheet> {
  String? _found;
  NfcFailureReason? _failure;
  int _attempt = 0;

  /// Se lee al montar: al desmontar ya no se puede usar `ref`.
  late final NfcInviteRepository _nfc;

  @override
  void initState() {
    super.initState();
    _nfc = ref.read(nfcInviteRepositoryProvider);
    unawaited(_read());
  }

  @override
  void dispose() {
    if (_found == null) {
      unawaited(_nfc.cancel());
    }
    super.dispose();
  }

  Future<void> _read() async {
    final attempt = ++_attempt;
    final result = await _nfc.readInvite();
    if (!mounted || attempt != _attempt) return;
    switch (result) {
      case Success(:final data):
        unawaited(HapticFeedback.lightImpact());
        setState(() => _found = data);
        await Future<void>.delayed(NfcJoinSheet.foundDelay);
        if (mounted) Navigator.of(context).pop(data);
      case FailureResult(:final failure):
        final reason = failure.maybeWhen(
          nfc: (reason) => reason,
          orElse: () => NfcFailureReason.failed,
        );
        // Cancelar en el aviso de iPhone cierra la hoja.
        if (reason == NfcFailureReason.cancelled) {
          return Navigator.of(context).pop();
        }
        setState(() => _failure = reason);
    }
  }

  void _retry() {
    setState(() => _failure = null);
    unawaited(_read());
  }

  @override
  Widget build(BuildContext context) {
    final copy = t.lobby.nfc;
    final found = _found != null;
    final failure = _failure;
    final iphone = Theme.of(context).platform == TargetPlatform.iOS;
    return SingleChildScrollView(
      child: FrSheet(
        children: [
          JoinSheetHeader(
            kicker: copy.kicker,
            title: found ? copy.foundTitle : copy.title,
            message: found ? copy.foundMessage : copy.message,
            onClose: () => Navigator.of(context).maybePop(),
          ),
          Center(child: NfcStage(found: found)),
          if (failure != null) ...[
            FrBanner.drawn(
              key: const Key('nfc_join_failure'),
              tone: FrBannerTone.alert,
              icon: FrIcons.nfc,
              title: failure == NfcFailureReason.notInvite
                  ? copy.notInvite
                  : copy.failed,
            ),
            FrButton.drawn(
              label: copy.retry,
              icon: FrIcons.regen,
              expand: true,
              onPressed: _retry,
            ),
          ] else if (!found && iphone)
            Text(
              copy.iphoneHint.toUpperCase(),
              textAlign: TextAlign.center,
              style: context.fr.type.labelS.copyWith(
                color: context.fr.colors.tx3,
              ),
            ),
        ],
      ),
    );
  }
}

/// El ícono de NFC entre dos anillos (`.nfc-stage`); con la invitación
/// leída, la marca de hecho en señal.
class NfcStage extends StatelessWidget {
  /// Crea el escenario; [found] con la invitación leída.
  const NfcStage({required this.found, super.key});

  /// Si ya se leyó.
  final bool found;

  @override
  Widget build(BuildContext context) {
    final c = context.fr.colors;
    final ink = found ? c.signal : c.tx2;
    Widget ring(double size, double alpha) => Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: ink.withValues(alpha: alpha)),
      ),
    );
    return SizedBox(
      width: 168,
      height: 168,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ring(168, 0.18),
          ring(124, 0.32),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: c.bg2,
              border: Border.all(color: ink.withValues(alpha: 0.6)),
            ),
            child: Center(
              child: FrIcon(
                found ? FrIcons.check : FrIcons.nfc,
                key: ValueKey(found ? 'nfc_found' : 'nfc_waiting'),
                size: 34,
                color: ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
