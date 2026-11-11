import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frecu/core/design/fr_theme.dart';
import 'package:frecu/core/design/icons/fr_icon.dart';
import 'package:frecu/core/design/icons/fr_icons.dart';
import 'package:frecu/core/design/widgets/fr_banner.dart';
import 'package:frecu/core/design/widgets/fr_button.dart';
import 'package:frecu/core/design/widgets/fr_pressable.dart';
import 'package:frecu/core/design/widgets/fr_sheet.dart';
import 'package:frecu/core/design/widgets/fr_toast.dart';
import 'package:frecu/core/design/widgets/signal_signature.dart';
import 'package:frecu/features/lobby/presentation/widgets/room_reach_step.dart';
import 'package:frecu/features/room/domain/entities/room_succession.dart';
import 'package:frecu/features/room/domain/repositories/room_handover.dart';
import 'package:frecu/features/room/presentation/providers/room_provider.dart';
import 'package:frecu/features/room/presentation/widgets/room_sheets.dart';
import 'package:frecu/i18n/strings.g.dart';

/// Lo que elige el anfitrión al salir de una frecu con traspaso.
enum HandoverChoice {
  /// Que siga sin él: la pasa a otra persona.
  keep,

  /// Cerrarla para todos.
  close,
}

/// Color de la firma de una persona ([id], [name]) en la malla.
typedef PeerColor = Color Function(String id, String name);

/// «¿Qué pasa con la frecu?» (`leaveHost('choose')` del prototipo del
/// anfitrión): «Que siga sin mí» (marcada) o «Cerrarla para todos», con
/// Seguir y Cancelar. [others] es cuántas personas más hay.
class HandoverChoiceSheet extends StatefulWidget {
  /// Crea la hoja.
  const HandoverChoiceSheet({required this.others, super.key});

  /// Personas en la frecu además del anfitrión.
  final int others;

  /// Abre la hoja; devuelve lo elegido, o nulo si se canceló.
  static Future<HandoverChoice?> show(
    BuildContext context, {
    required int others,
  }) => showFrSheet<HandoverChoice>(
    context,
    builder: (_) => HandoverChoiceSheet(others: others),
  );

  @override
  State<HandoverChoiceSheet> createState() => _HandoverChoiceSheetState();
}

class _HandoverChoiceSheetState extends State<HandoverChoiceSheet> {
  HandoverChoice _choice = HandoverChoice.keep;

  @override
  Widget build(BuildContext context) {
    final copy = t.room.handover;
    final navigator = Navigator.of(context);
    return SingleChildScrollView(
      child: FrSheet(
        children: [
          _heading(context),
          _option(HandoverChoice.keep),
          _option(HandoverChoice.close),
          Column(
            spacing: 10,
            children: [
              FrButton.drawn(
                key: const Key('handover_next'),
                label: copy.next,
                trailingIcon: FrIcons.arrow,
                expand: true,
                onPressed: () => navigator.pop(_choice),
              ),
              FrButton(
                key: const Key('handover_cancel'),
                label: copy.cancel,
                variant: FrButtonVariant.secondary,
                expand: true,
                onPressed: navigator.pop,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Antena, «¿Qué pasa con la frecu?» y cuántas personas más hay.
  Widget _heading(BuildContext context) {
    final fr = context.fr;
    final c = fr.colors;
    final copy = t.room.handover;
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 10, 6, 4),
      child: Column(
        spacing: 12,
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: c.bg2,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: c.line1),
            ),
            child: FrIcon(FrIcons.antenna, size: 28, color: c.signalFg),
          ),
          Text(
            copy.leaveTitle,
            textAlign: TextAlign.center,
            style: FrSheet.titleStyle(fr).copyWith(fontSize: 22),
          ),
          Text(
            widget.others == 1
                ? copy.leaveOne
                : copy.leaveMany(count: widget.others),
            textAlign: TextAlign.center,
            style: fr.type.body.copyWith(
              fontSize: 14.5,
              height: 1.55,
              color: c.tx2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _option(HandoverChoice choice) {
    final copy = t.room.handover;
    final keep = choice == HandoverChoice.keep;
    return RoomReachOption(
      key: Key(keep ? 'handover_keep' : 'handover_close'),
      icon: keep ? FrIcons.users : FrIcons.exit,
      title: keep ? copy.keep : copy.close,
      detail: keep ? copy.keepDetail : copy.closeDetail,
      selected: _choice == choice,
      enabled: true,
      onPressed: () => setState(() => _choice = choice),
    );
  }
}

/// «¿Quién lleva la frecu?» (`leaveHost('pick')` del prototipo): las
/// personas de la frecu ([members], en orden de sucesión) con su firma; la
/// primera, que lleva más tiempo, va sugerida y marcada.
class HandoverPickSheet extends StatefulWidget {
  /// Crea la hoja.
  const HandoverPickSheet({
    required this.members,
    required this.colorOf,
    super.key,
  });

  /// Quienes pueden llevar la frecu, en orden de sucesión.
  final List<RoomMember> members;

  /// Color de la firma de cada persona.
  final PeerColor colorOf;

  /// Abre la hoja; devuelve el id elegido, o nulo si se cerró.
  static Future<String?> show(
    BuildContext context, {
    required List<RoomMember> members,
    required PeerColor colorOf,
  }) => showFrSheet<String>(
    context,
    builder: (_) => HandoverPickSheet(members: members, colorOf: colorOf),
  );

  @override
  State<HandoverPickSheet> createState() => _HandoverPickSheetState();
}

class _HandoverPickSheetState extends State<HandoverPickSheet> {
  late String _chosen = widget.members.first.id;

  static String _time(DateTime at) {
    final local = at.toLocal();
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(local.hour)}:${two(local.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final copy = t.room.handover;
    final chosen = widget.members.firstWhere((m) => m.id == _chosen);
    return SingleChildScrollView(
      child: FrSheet(
        children: [
          RoomSheetHeader(
            kicker: copy.keep,
            title: copy.pickTitle,
            message: copy.pickMessage,
          ),
          Column(
            spacing: 8,
            children: [
              for (final (index, member) in widget.members.indexed)
                _PeerOption(
                  key: Key('handover_peer_${member.id}'),
                  name: member.displayName,
                  color: widget.colorOf(member.id, member.displayName),
                  detail: index == 0
                      ? copy.suggested
                      : copy.since(time: _time(member.joinedAt)),
                  suggested: index == 0,
                  selected: member.id == _chosen,
                  onPressed: () => setState(() => _chosen = member.id),
                ),
            ],
          ),
          FrButton.drawn(
            key: const Key('handover_pass'),
            label: copy.pass(name: chosen.displayName),
            icon: FrIcons.exit,
            expand: true,
            onPressed: () => Navigator.of(context).pop(_chosen),
          ),
        ],
      ),
    );
  }
}

/// Una persona que puede llevar la frecu (`.opt` con su firma).
class _PeerOption extends StatelessWidget {
  const _PeerOption({
    required this.name,
    required this.color,
    required this.detail,
    required this.suggested,
    required this.selected,
    required this.onPressed,
    super.key,
  });

  final String name;
  final Color color;
  final String detail;
  final bool suggested;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final fr = context.fr;
    final c = fr.colors;
    return Semantics(
      selected: selected,
      child: FrPressable(
        onPressed: onPressed,
        pressedScale: 0.98,
        builder: (context, _, _) => AnimatedContainer(
          duration: fr.motion.smooth,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: c.bg1,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? c.signal.withValues(alpha: 0.55) : c.line1,
            ),
          ),
          child: Row(
            spacing: 14,
            children: [
              SignalSignature(name: name, size: 34, color: color),
              Expanded(child: _texts(fr)),
              SizedBox(
                width: 16,
                child: selected
                    ? FrIcon(FrIcons.check, size: 16, color: c.signalFg)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _texts(FrTheme fr) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: 4,
    children: [
      Text(
        name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: fr.type.body.copyWith(
          fontSize: 15,
          height: 1.2,
          fontWeight: FontWeight.w600,
          color: fr.colors.tx1,
        ),
      ),
      Text(
        detail.toUpperCase(),
        style: fr.type.labelS.copyWith(
          color: suggested ? fr.colors.signalFg : fr.colors.tx3,
        ),
      ),
    ],
  );
}

/// Aviso del cambio de anfitrión (`guestAfter` y `heirView` del prototipo):
/// a quien recibe la frecu, «Ahora llevas la frecu.» con «Mostrar el QR»;
/// a los demás, un toast con la firma de quien la lleva. En cada cambio, la
/// invitación pasa a la IP de quien la lleva.
class HandoverNotice extends ConsumerStatefulWidget {
  /// Crea el aviso.
  const HandoverNotice({
    required this.onInvite,
    required this.colorOf,
    super.key,
  });

  /// Muestra el QR de la frecu.
  final VoidCallback? onInvite;

  /// Color de la firma de cada persona.
  final PeerColor colorOf;

  @override
  ConsumerState<HandoverNotice> createState() => _HandoverNoticeState();
}

class _HandoverNoticeState extends ConsumerState<HandoverNotice> {
  /// Cambio que hizo a este teléfono anfitrión, hasta cerrar el aviso.
  HostChange? _received;

  void _onChange(HostChange change) {
    ref.read(roomNotifierProvider.notifier).applyHostChange(change);
    if (change.you) {
      setState(() => _received = change);
      return;
    }
    final copy = t.room.handover;
    final previous = change.previousHost;
    final message = previous == null
        ? copy.taken(name: change.hostName)
        : change.reason == HostChangeReason.lost
        ? copy.lost(previous: previous, name: change.hostName)
        : copy.left(previous: previous, name: change.hostName);
    showFrToast(
      context,
      FrToast.signature(
        name: change.hostName,
        color: widget.colorOf(change.hostId, change.hostName),
        message: message,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<HostChange>>(hostChangesProvider, (_, next) {
      final change = next.value;
      if (change != null) _onChange(change);
    });
    final fr = context.fr;
    final received = _received;
    final copy = t.room.handover;
    final previous = received?.previousHost;
    return AnimatedSwitcher(
      duration: fr.motion.smooth,
      child: received == null
          ? const SizedBox.shrink()
          : FrBanner.drawn(
              key: const Key('handover_received'),
              tone: FrBannerTone.info,
              icon: FrIcons.antenna,
              title: copy.heirTitle,
              message: previous == null
                  ? null
                  : received.reason == HostChangeReason.lost
                  ? copy.heirLost(name: previous)
                  : copy.heirLeft(name: previous),
              actionLabel: copy.showQr,
              onAction: widget.onInvite,
              floating: true,
              dismissLabel: copy.dismiss,
              onDismiss: () => setState(() => _received = null),
            ),
    );
  }
}
