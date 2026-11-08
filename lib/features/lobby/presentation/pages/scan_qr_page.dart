import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frecu/app/router/app_router.gr.dart';
import 'package:frecu/app/theme/app_theme.dart';
import 'package:frecu/core/design/fr_theme.dart';
import 'package:frecu/core/design/icons/fr_icons.dart';
import 'package:frecu/core/design/motion/fr_spring_curve.dart';
import 'package:frecu/core/design/motion/reduced_motion.dart';
import 'package:frecu/core/design/tokens/fr_type.dart';
import 'package:frecu/core/design/widgets/fr_button.dart';
import 'package:frecu/core/design/widgets/fr_icon_button.dart';
import 'package:frecu/core/error/failure.dart';
import 'package:frecu/core/result/result.dart';
import 'package:frecu/features/lobby/domain/usecases/parse_invite_from_qr.dart';
import 'package:frecu/features/lobby/presentation/extensions/display_name_extension.dart';
import 'package:frecu/features/lobby/presentation/widgets/ip_join_sheet.dart';
import 'package:frecu/features/lobby/presentation/widgets/pin_join_sheet.dart';
import 'package:frecu/features/lobby/presentation/widgets/room_note_label.dart';
import 'package:frecu/features/lobby/presentation/widgets/scan_reticle.dart';
import 'package:frecu/features/room/domain/entities/room.dart';
import 'package:frecu/features/room/domain/entities/room_invite.dart';
import 'package:frecu/features/room/presentation/providers/room_provider.dart';
import 'package:frecu/i18n/strings.g.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Constructor de widget para inyectar escáner en pruebas.
typedef ScannerWidgetBuilder = Widget Function(
  BuildContext context,
  void Function(String barcode) onBarcodeScanned,
);

/// Escáner de invitaciones (`scan` del prototipo), siempre en tema oscuro:
/// la cámara bajo la [ScanReticle], arriba Atrás y la linterna, y abajo la
/// indicación con Conectar por IP.
///
/// Al leer una invitación la retícula se cierra sobre el QR y aparece la
/// tarjeta «Frecu encontrada»; la unión empieza al tocar Unirme y, si sale
/// bien, la frecu activa reemplaza al escáner. Mientras se une no se puede
/// volver.
@RoutePage()
class ScanQrPage extends ConsumerStatefulWidget {
  /// Constructor constante con escáner inyectable para pruebas.
  const ScanQrPage({super.key, this.scannerBuilder});

  /// Constructor opcional para construir el widget del escáner en pruebas.
  final ScannerWidgetBuilder? scannerBuilder;

  @override
  ConsumerState<ScanQrPage> createState() => _ScanQrPageState();
}

class _ScanQrPageState extends ConsumerState<ScanQrPage> {
  final _parser = const ParseInviteFromQr();

  /// Cámara real; nula si las pruebas inyectan el escáner.
  MobileScannerController? _camera;

  /// Invitación leída; con ella la retícula queda cerrada.
  RoomInvite? _invite;

  /// El último QR leído no era una invitación.
  bool _invalid = false;
  bool _joining = false;
  bool _torch = false;
  Failure? _failure;

  @override
  void initState() {
    super.initState();
    if (widget.scannerBuilder == null) _camera = MobileScannerController();
  }

  @override
  void dispose() {
    unawaited(_camera?.dispose());
    super.dispose();
  }

  void _onBarcode(String raw) {
    if (_invite != null) return;
    switch (_parser.parse(raw)) {
      case Success(:final data):
        setState(() {
          _invite = data;
          _invalid = false;
        });
        unawaited(HapticFeedback.lightImpact());
      case FailureResult():
        if (!_invalid) setState(() => _invalid = true);
    }
  }

  Future<void> _join() async {
    final invite = _invite;
    if (invite == null || _joining) return;
    setState(() {
      _joining = true;
      _failure = null;
    });
    final result = await ref
        .read(roomNotifierProvider.notifier)
        .joinRoom(
          hostAddress: invite.host,
          port: invite.port,
          accessCode: invite.accessCode,
          displayName: ref.joinDisplayName,
          note: invite.note,
        );
    if (!mounted) return;
    switch (result) {
      case Success(:final data):
        setState(() => _joining = false);
        _openRoom(data);
      case FailureResult(:final failure):
        setState(() {
          _joining = false;
          _failure = failure;
        });
    }
  }

  Future<void> _joinByIp() async {
    final room = await IpJoinSheet.show(context);
    if (room != null && mounted) _openRoom(room);
  }

  /// La frecu activa reemplaza al escáner; sin router (pruebas) no navega.
  void _openRoom(Room room) {
    final router = StackRouterScope.of(context)?.controller;
    if (router != null) unawaited(router.replace(RoomRoute(roomId: room.id)));
  }

  void _toggleTorch() {
    setState(() => _torch = !_torch);
    unawaited(_camera?.toggleTorch());
  }

  Widget _scanner(BuildContext context) {
    final builder = widget.scannerBuilder;
    if (builder != null) return builder(context, _onBarcode);
    return MobileScanner(
      controller: _camera,
      onDetect: (capture) {
        final raw = capture.barcodes.firstOrNull?.rawValue;
        if (raw != null) _onBarcode(raw);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final invite = _invite;
    return Theme(
      data: AppTheme.dark,
      child: PopScope(
        canPop: !_joining,
        child: Material(
          color: Colors.black,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _scanner(context),
              ScanReticle(locked: invite != null),
              SafeArea(
                child: Stack(
                  children: [
                    ScanTopBar(torch: _torch, onTorch: _toggleTorch),
                    Positioned(
                      left: 20,
                      right: 20,
                      bottom: 34,
                      child: invite == null
                          ? ScanHint(invalid: _invalid, onJoinByIp: _joinByIp)
                          : _found(invite),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _found(RoomInvite invite) {
    final failure = _failure;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (failure != null) ...[
          JoinFailureBanner(failure: failure),
          const SizedBox(height: 14),
        ],
        ScanFoundCard(invite: invite, joining: _joining, onJoin: _join),
      ],
    );
  }
}

/// Barra del escáner: Atrás, el título y la linterna.
class ScanTopBar extends StatelessWidget {
  /// Crea la barra; la linterna está encendida si [torch].
  const ScanTopBar({required this.torch, required this.onTorch, super.key});

  /// Linterna encendida.
  final bool torch;

  /// Enciende o apaga la linterna.
  final VoidCallback onTorch;

  @override
  Widget build(BuildContext context) {
    final scan = t.lobby.join.scan;
    return SizedBox(
      height: 60,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            FrIconButton.drawn(
              icon: FrIcons.back,
              semanticLabel: scan.back,
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            const SizedBox(width: 10),
            Expanded(child: _title(context.fr)),
            const SizedBox(width: 10),
            FrIconButton.drawn(
              icon: FrIcons.flash,
              semanticLabel: scan.torch,
              selected: torch,
              onPressed: onTorch,
            ),
          ],
        ),
      ),
    );
  }

  /// «Escanear invitación» y «QR de la frecu».
  Widget _title(FrTheme fr) {
    final c = fr.colors;
    final scan = t.lobby.join.scan;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          scan.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: fr.type.title.copyWith(
            fontSize: 16,
            height: 1,
            fontWeight: const FontWeight(640),
            fontVariations: const [
              FontVariation.weight(640),
              FontVariation.width(110),
            ],
            color: c.tx1,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          scan.subtitle.toUpperCase(),
          style: fr.type.labelS.copyWith(color: c.tx3),
        ),
      ],
    );
  }
}

/// Indicación mientras busca: apuntar al QR (o que el último no era una
/// invitación) y Conectar por IP.
class ScanHint extends StatelessWidget {
  /// Crea la indicación; Conectar por IP llama a [onJoinByIp].
  const ScanHint({required this.invalid, required this.onJoinByIp, super.key});

  /// El último QR leído no era una invitación.
  final bool invalid;

  /// Abre la hoja de conexión por IP.
  final VoidCallback onJoinByIp;

  @override
  Widget build(BuildContext context) {
    final fr = context.fr;
    final c = fr.colors;
    final scan = t.lobby.join.scan;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 300),
          child: Text(
            invalid ? scan.invalid : scan.hint,
            textAlign: TextAlign.center,
            style: fr.type.body.copyWith(
              height: 1.5,
              color: invalid ? c.alert : c.tx2,
            ),
          ),
        ),
        const SizedBox(height: 14),
        FrButton.drawn(
          label: t.lobby.joinRoom,
          icon: FrIcons.nodes,
          variant: FrButtonVariant.secondary,
          size: FrButtonSize.small,
          onPressed: onJoinByIp,
        ),
      ],
    );
  }
}

/// Tarjeta «Frecu encontrada» (`.scan-card`): la nota y sus Hz (o «Frecu
/// sin nota»), la IP y el puerto, y Unirme. Sube con el resorte `flow`.
class ScanFoundCard extends StatelessWidget {
  /// Crea la tarjeta de [invite]; Unirme llama a [onJoin].
  const ScanFoundCard({
    required this.invite,
    required this.joining,
    required this.onJoin,
    super.key,
  });

  /// Invitación leída.
  final RoomInvite invite;

  /// Uniéndose: Unirme muestra la onda de carga.
  final bool joining;

  /// Se une a la frecu.
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    final fr = context.fr;
    final reduce = context.reduceMotion;
    const rise = Duration(milliseconds: 600);
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: reduce ? fr.motion.quick : rise,
      curve: reduce
          ? fr.motion.easeOut
          : FrSpringCurve(fr.motion.springFlow, rise),
      builder: (context, shown, child) => Opacity(
        opacity: shown.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, reduce ? 0 : 18 * (1 - shown)),
          child: child,
        ),
      ),
      child: _card(fr),
    );
  }

  Widget _card(FrTheme fr) {
    final c = fr.colors;
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: c.bg2.withValues(alpha: 0.92),
        shape: RoundedSuperellipseBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: c.line2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(child: _details(fr)),
            const SizedBox(width: 12),
            FrButton(
              label: t.lobby.join.scan.join,
              size: FrButtonSize.small,
              loading: joining,
              onPressed: onJoin,
            ),
          ],
        ),
      ),
    );
  }

  /// «Frecu encontrada», la nota y sus Hz (o «Frecu sin nota») y la IP con
  /// el puerto.
  Widget _details(FrTheme fr) {
    final c = fr.colors;
    final scan = t.lobby.join.scan;
    final note = invite.note;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          scan.found.toUpperCase(),
          style: fr.type.labelS.copyWith(color: c.signalFg),
        ),
        const SizedBox(height: 7),
        Text(
          note == null ? scan.noNote : '${note.label} · ${note.hzText}',
          style: TextStyle(
            fontFamily: FrFonts.ui,
            fontSize: 18,
            height: 1.2,
            fontWeight: const FontWeight(660),
            fontVariations: const [
              FontVariation.weight(660),
              FontVariation.width(108),
            ],
            color: c.tx1,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${invite.host} · ${t.lobby.join.port(port: invite.port)}'
              .toUpperCase(),
          style: fr.type.labelS.copyWith(color: c.tx3),
        ),
      ],
    );
  }
}
