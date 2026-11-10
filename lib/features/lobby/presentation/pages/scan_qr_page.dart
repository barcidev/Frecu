import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frecu/app/router/app_router.gr.dart';
import 'package:frecu/app/theme/app_theme.dart';
import 'package:frecu/core/design/fr_theme.dart';
import 'package:frecu/core/design/icons/fr_icon.dart';
import 'package:frecu/core/design/icons/fr_icons.dart';
import 'package:frecu/core/design/motion/fr_spring_curve.dart';
import 'package:frecu/core/design/motion/reduced_motion.dart';
import 'package:frecu/core/design/tokens/fr_type.dart';
import 'package:frecu/core/design/widgets/fr_button.dart';
import 'package:frecu/core/design/widgets/fr_icon_button.dart';
import 'package:frecu/core/error/failure.dart';
import 'package:frecu/core/logging/app_logger.dart';
import 'package:frecu/core/result/result.dart';
import 'package:frecu/features/lobby/domain/usecases/parse_invite_from_qr.dart';
import 'package:frecu/features/lobby/presentation/extensions/display_name_extension.dart';
import 'package:frecu/features/lobby/presentation/widgets/ip_join_sheet.dart';
import 'package:frecu/features/lobby/presentation/widgets/pin_join_sheet.dart';
import 'package:frecu/features/lobby/presentation/widgets/room_note_label.dart';
import 'package:frecu/features/lobby/presentation/widgets/scan_reticle.dart';
import 'package:frecu/features/lobby/presentation/widgets/wifi_join_sheet.dart';
import 'package:frecu/features/network/domain/repositories/wifi_join_repository.dart';
import 'package:frecu/features/network/presentation/providers/network_provider.dart';
import 'package:frecu/features/room/domain/entities/room.dart';
import 'package:frecu/features/room/domain/entities/room_invite.dart';
import 'package:frecu/features/room/presentation/providers/room_provider.dart';
import 'package:frecu/i18n/strings.g.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Constructor de widget para inyectar escáner en pruebas: recibe dónde
/// avisar de cada código leído y de un problema con la cámara (nulo cuando
/// vuelve a funcionar).
typedef ScannerWidgetBuilder = Widget Function(
  BuildContext context,
  void Function(String barcode) onBarcodeScanned,
  void Function(ScanCameraIssue? issue) onCameraIssue,
);

/// Por qué no se ve la cámara.
enum ScanCameraIssue {
  /// Se negó el permiso de la cámara.
  denied,

  /// No hay cámara o el teléfono no puede usarla.
  unavailable,
}

/// Escáner de invitaciones (`scan` del prototipo), siempre en tema oscuro:
/// la cámara bajo la [ScanReticle], arriba Atrás y la linterna, y abajo la
/// indicación con Conectar por IP.
///
/// Al leer una invitación la retícula se cierra sobre el QR y aparece la
/// tarjeta «Frecu encontrada», sobre el fondo desenfocado, con «Escanear
/// otro QR» para volver a buscar; la unión empieza al tocar Unirme y, si sale
/// bien, la frecu activa reemplaza al escáner. Mientras se une no se puede
/// volver.
///
/// Si se niega la cámara o no hay, en lugar de la retícula explica qué pasa
/// con «Abrir ajustes» (si falta el permiso) y Conectar por IP. La cámara se
/// para cuando la app deja de estar al frente y vuelve al regresar, también
/// al volver de Ajustes ([ScanCameraLifecycle]).
@RoutePage()
class ScanQrPage extends ConsumerStatefulWidget {
  /// Constructor constante con escáner inyectable para pruebas; con
  /// [invite] abre con esa invitación ya leída.
  const ScanQrPage({super.key, this.scannerBuilder, this.invite});

  /// Constructor opcional para construir el widget del escáner en pruebas.
  final ScannerWidgetBuilder? scannerBuilder;

  /// Invitación ya leída (`frecu://join?…`) de un enlace o por NFC: se ve
  /// su tarjeta sin encender la cámara, que solo se enciende con «Escanear
  /// otro QR».
  final String? invite;

  @override
  ConsumerState<ScanQrPage> createState() => _ScanQrPageState();
}

class _ScanQrPageState extends ConsumerState<ScanQrPage>
    with WidgetsBindingObserver {
  final _parser = const ParseInviteFromQr();
  final _lifecycle = ScanCameraLifecycle();

  /// Cámara real; nula si las pruebas inyectan el escáner.
  MobileScannerController? _camera;

  /// Problema con la cámara; nulo si funciona.
  ScanCameraIssue? _issue;

  /// Invitación leída; con ella la retícula queda cerrada.
  RoomInvite? _invite;

  /// El último QR leído no era una invitación.
  bool _invalid = false;
  bool _joining = false;
  bool _torch = false;
  Failure? _failure;

  /// Cómo llega el teléfono a la red de la frecu.
  late final WifiJoinRepository _network;

  /// La app pudo conectar el teléfono a la red de la frecu: si no se entra,
  /// al salir del escáner la suelta.
  bool _networkTouched = false;

  /// Se entró a la frecu: la red sigue con ella.
  bool _entered = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _network = ref.read(wifiJoinRepositoryProvider);
    final link = widget.invite;
    if (link != null) {
      switch (_parser.parse(link)) {
        case Success(:final data):
          _invite = data;
        case FailureResult():
          _invalid = true;
      }
    }
    if (widget.scannerBuilder == null) {
      _camera = MobileScannerController(autoStart: _invite == null)
        ..addListener(_onCameraState);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_networkTouched && !_entered) unawaited(_network.release());
    final camera = _camera;
    if (camera != null) {
      camera.removeListener(_onCameraState);
      unawaited(camera.dispose());
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final camera = _camera;
    if (camera == null) return;
    final value = camera.value;
    switch (state) {
      case AppLifecycleState.inactive:
        if (_lifecycle.shouldStop(running: value.isRunning)) {
          // Parar la cámara apaga la linterna.
          if (_torch) setState(() => _torch = false);
          unawaited(_run('stop', camera.stop));
        }
      case AppLifecycleState.resumed:
        if (_lifecycle.shouldStart(
          running: value.isRunning,
          starting: value.isStarting,
        )) {
          unawaited(_run('start', camera.start));
        }
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        break;
    }
  }

  /// Para o enciende la cámara sin dejar escapar sus errores: si no vuelve,
  /// su estado lo dice.
  Future<void> _run(String action, Future<void> Function() camera) async {
    try {
      await camera();
    } on Object catch (error, stackTrace) {
      AppLogger.w('Could not $action the camera', error, stackTrace);
    }
  }

  void _onCameraState() {
    final error = _camera?.value.error;
    _setIssue(switch (error?.errorCode) {
      null => null,
      MobileScannerErrorCode.permissionDenied => ScanCameraIssue.denied,
      _ => ScanCameraIssue.unavailable,
    });
  }

  void _setIssue(ScanCameraIssue? issue) {
    if (mounted && issue != _issue) setState(() => _issue = issue);
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

  /// Suelta la invitación leída y vuelve a buscar.
  void _scanAnother() {
    if (_joining) return;
    setState(() {
      _invite = null;
      _failure = null;
      _invalid = false;
    });
    // Si se abrió con una invitación ya leída, la cámara aún no arrancó.
    final camera = _camera;
    if (camera != null && !camera.value.isRunning && !camera.value.isStarting) {
      unawaited(_run('start', camera.start));
    }
  }

  Future<void> _join() async {
    final invite = _invite;
    if (invite == null || _joining) return;
    setState(() {
      _joining = true;
      _failure = null;
    });
    if (invite.wifi != null && !await _onRoomNetwork(invite)) {
      if (mounted) setState(() => _joining = false);
      return;
    }
    if (!mounted) return;
    final result = await ref
        .read(roomNotifierProvider.notifier)
        .joinRoom(
          hostAddress: invite.host,
          port: invite.port,
          accessCode: invite.accessCode,
          displayName: ref.joinDisplayName,
          note: invite.note,
          wifi: invite.wifi,
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

  /// Verdadero si el teléfono está en la red de la frecu que trae [invite]:
  /// ya lo estaba (el anfitrión responde) o entró con la [WifiJoinSheet].
  Future<bool> _onRoomNetwork(RoomInvite invite) async {
    _networkTouched = true;
    if (await _network.reaches(invite.host, invite.port)) return true;
    if (!mounted) return false;
    return WifiJoinSheet.show(context, invite);
  }

  Future<void> _joinByIp() async {
    final room = await IpJoinSheet.show(context);
    if (room != null && mounted) _openRoom(room);
  }

  /// Abre los Ajustes de la app para dar el permiso de la cámara; al volver,
  /// la cámara se enciende de nuevo.
  Future<void> _openSettings() async {
    _lifecycle.openedSettings();
    await ref.read(systemSettingsRepositoryProvider).openAppSettings();
  }

  /// La frecu activa reemplaza al escáner; sin router (pruebas) no navega.
  void _openRoom(Room room) {
    _entered = true;
    final router = StackRouterScope.of(context)?.controller;
    if (router != null) unawaited(router.replace(RoomRoute(roomId: room.id)));
  }

  void _toggleTorch() {
    setState(() => _torch = !_torch);
    final camera = _camera;
    if (camera == null) return;
    unawaited(_run('toggle the torch of', camera.toggleTorch));
  }

  Widget _scanner(BuildContext context) {
    final builder = widget.scannerBuilder;
    if (builder != null) return builder(context, _onBarcode, _setIssue);
    return MobileScanner(
      controller: _camera,
      // El estado sin cámara lo dibuja la página, en Portadora.
      errorBuilder: (_, _) => const ColoredBox(color: Colors.black),
      onDetect: (capture) {
        final raw = capture.barcodes.firstOrNull?.rawValue;
        if (raw != null) _onBarcode(raw);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final invite = _invite;
    final issue = invite == null ? _issue : null;
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
              if (issue == null) ScanReticle(locked: invite != null),
              SafeArea(
                child: Stack(
                  children: [
                    ScanTopBar(
                      torch: _torch,
                      onTorch: issue == null ? _toggleTorch : null,
                    ),
                    if (issue != null)
                      Positioned.fill(
                        top: ScanTopBar.height,
                        child: Center(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(26, 0, 26, 34),
                            child: ScanCameraUnavailable(
                              issue: issue,
                              onOpenSettings: _openSettings,
                              onJoinByIp: _joinByIp,
                            ),
                          ),
                        ),
                      )
                    else
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
        const SizedBox(height: 10),
        Center(
          child: _FitWidth(
            child: FrButton.drawn(
              label: t.lobby.join.scan.another,
              icon: FrIcons.scan,
              variant: FrButtonVariant.ghost,
              size: FrButtonSize.small,
              onPressed: _joining ? null : _scanAnother,
            ),
          ),
        ),
      ],
    );
  }
}

/// Cuándo parar y volver a encender la cámara con el ciclo de vida de la app,
/// ya que el escáner pasa su propio controlador a `MobileScanner`.
///
/// La cámara se para si estaba en marcha cuando la app deja de estar al
/// frente, y al volver se enciende si la paró la app o si se fue a Ajustes a
/// dar el permiso. Tras negar el permiso no se reintenta sola: en Android
/// eso volvería a pedirlo sin fin.
class ScanCameraLifecycle {
  bool _stoppedByApp = false;
  bool _awaitingSettings = false;

  /// La app dejó de estar al frente: verdadero si hay que parar la cámara.
  bool shouldStop({required bool running}) {
    if (!running) return false;
    _stoppedByApp = true;
    return true;
  }

  /// Se fue a Ajustes a dar el permiso de la cámara.
  void openedSettings() => _awaitingSettings = true;

  /// La app volvió: verdadero si hay que encender la cámara.
  bool shouldStart({required bool running, required bool starting}) {
    final restart = _stoppedByApp || _awaitingSettings;
    _stoppedByApp = false;
    _awaitingSettings = false;
    return restart && !running && !starting;
  }
}

/// Barra del escáner: Atrás, el título y la linterna.
class ScanTopBar extends StatelessWidget {
  /// Crea la barra; la linterna está encendida si [torch].
  const ScanTopBar({required this.torch, required this.onTorch, super.key});

  /// Alto de la barra.
  static const double height = 60;

  /// Linterna encendida.
  final bool torch;

  /// Enciende o apaga la linterna; nulo sin cámara.
  final VoidCallback? onTorch;

  @override
  Widget build(BuildContext context) {
    final scan = t.lobby.join.scan;
    return SizedBox(
      height: height,
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

/// La cámara no está ([issue]): qué pasa y qué hacer, con «Abrir ajustes»
/// si falta el permiso y Conectar por IP.
class ScanCameraUnavailable extends StatelessWidget {
  /// Crea el aviso de [issue].
  const ScanCameraUnavailable({
    required this.issue,
    required this.onOpenSettings,
    required this.onJoinByIp,
    super.key,
  });

  /// Por qué no se ve la cámara.
  final ScanCameraIssue issue;

  /// Abre los Ajustes de la app.
  final VoidCallback onOpenSettings;

  /// Abre la hoja de conexión por IP.
  final VoidCallback onJoinByIp;

  @override
  Widget build(BuildContext context) {
    final fr = context.fr;
    final c = fr.colors;
    final camera = t.lobby.join.scan.camera;
    final denied = issue == ScanCameraIssue.denied;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const _CameraGlyph(),
        const SizedBox(height: 18),
        Text(
          denied ? camera.deniedTitle : camera.unavailableTitle,
          textAlign: TextAlign.center,
          style: fr.type.title.copyWith(
            fontSize: 18,
            height: 1.2,
            fontWeight: const FontWeight(640),
            fontVariations: const [
              FontVariation.weight(640),
              FontVariation.width(112),
            ],
            color: c.tx1,
          ),
        ),
        const SizedBox(height: 10),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 300),
          child: Text(
            denied ? camera.deniedMessage : camera.unavailableMessage,
            textAlign: TextAlign.center,
            style: fr.type.body.copyWith(
              fontSize: 14,
              height: 1.5,
              color: c.tx2,
            ),
          ),
        ),
        const SizedBox(height: 22),
        if (denied) ...[
          _FitWidth(
            child: FrButton.drawn(
              label: camera.openSettings,
              icon: FrIcons.sliders,
              size: FrButtonSize.small,
              onPressed: onOpenSettings,
            ),
          ),
          const SizedBox(height: 10),
        ],
        _FitWidth(
          child: FrButton.drawn(
            label: t.lobby.joinRoom,
            icon: FrIcons.nodes,
            variant: denied
                ? FrButtonVariant.secondary
                : FrButtonVariant.primary,
            size: FrButtonSize.small,
            onPressed: onJoinByIp,
          ),
        ),
      ],
    );
  }
}

/// Encoge [child] si no cabe a lo ancho (un teléfono estrecho o un texto
/// largo) en lugar de desbordarlo.
class _FitWidth extends StatelessWidget {
  const _FitWidth({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      FittedBox(fit: BoxFit.scaleDown, child: child);
}

/// La cámara en una caja de 56 px (`.perm .pic`), en alerta.
class _CameraGlyph extends StatelessWidget {
  const _CameraGlyph();

  @override
  Widget build(BuildContext context) {
    final c = context.fr.colors;
    return SizedBox.square(
      dimension: 56,
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: c.bg2,
          shape: RoundedSuperellipseBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: c.line1),
          ),
        ),
        child: Center(child: FrIcon(FrIcons.camera, size: 28, color: c.alert)),
      ),
    );
  }
}

/// Tarjeta «Frecu encontrada» (`.scan-card`): el nombre de la frecu (o, en
/// invitaciones sin nombre, la nota y sus Hz o «Frecu sin nota»), la nota y
/// la IP, y Unirme. Desenfoca lo que hay detrás y sube con el resorte
/// `flow`.
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

  /// Desenfoque del fondo (`backdrop-filter: blur(14px)`).
  static const double blur = 14;

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
    final shape = RoundedSuperellipseBorder(
      borderRadius: BorderRadius.circular(24),
    );
    return ClipPath(
      clipper: ShapeBorderClipper(shape: shape),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: DecoratedBox(
          decoration: ShapeDecoration(
            color: c.bg2.withValues(alpha: 0.92),
            shape: shape.copyWith(side: BorderSide(color: c.line2)),
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
        ),
      ),
    );
  }

  /// «Frecu encontrada», el nombre y abajo la nota y la IP; sin nombre en la
  /// invitación, la nota y sus Hz (o «Frecu sin nota») y la IP con el
  /// puerto.
  Widget _details(FrTheme fr) {
    final c = fr.colors;
    final scan = t.lobby.join.scan;
    final note = invite.note;
    final name = invite.name;
    final title =
        name ?? (note == null ? scan.noNote : '${note.label} · ${note.hzText}');
    final subtitle = name != null
        ? [?note?.label, invite.host].join(' · ')
        : '${invite.host} · ${t.lobby.join.port(port: invite.port)}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          scan.found.toUpperCase(),
          style: fr.type.labelS.copyWith(color: c.signalFg),
        ),
        const SizedBox(height: 7),
        Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
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
          subtitle.toUpperCase(),
          style: fr.type.labelS.copyWith(color: c.tx3),
        ),
        if (invite.wifi case final wifi?) ...[
          const SizedBox(height: 6),
          Row(
            key: const Key('scan_found_network'),
            children: [
              FrIcon(FrIcons.hotspot, size: 16, color: c.tx3),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  t.lobby.join.wifi.network(ssid: wifi.ssid),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: fr.type.bodyS.copyWith(color: c.tx3),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
