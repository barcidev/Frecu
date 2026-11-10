import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frecu/core/design/fr_theme.dart';
import 'package:frecu/core/design/icons/fr_icon.dart';
import 'package:frecu/core/design/icons/fr_icons.dart';
import 'package:frecu/core/design/motion/reduced_motion.dart';
import 'package:frecu/core/design/widgets/fr_button.dart';
import 'package:frecu/core/design/widgets/fr_sheet.dart';
import 'package:frecu/core/design/widgets/signal_signature.dart';
import 'package:frecu/features/network/domain/entities/wifi_credentials.dart';
import 'package:frecu/features/nfc_invite/presentation/providers/nfc_invite_provider.dart';
import 'package:frecu/features/nfc_invite/presentation/widgets/nfc_write_sheet.dart';
import 'package:frecu/features/room/domain/entities/room.dart';
import 'package:frecu/features/room/domain/entities/room_invite.dart';
import 'package:frecu/features/room/domain/usecases/build_invite_qr.dart';
import 'package:frecu/features/room/presentation/widgets/room_header.dart';
import 'package:frecu/features/room/presentation/widgets/room_sheets.dart';
import 'package:frecu/i18n/strings.g.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Hoja para invitar a la frecu (`SH.invite` del prototipo): el QR de la
/// invitación y, debajo, la nota, el código de acceso y la IP del anfitrión.
class InviteSheet extends ConsumerWidget {
  /// Crea la hoja de [room].
  const InviteSheet({required this.room, super.key});

  /// Frecu a la que se invita.
  final Room room;

  /// Abre la hoja de [room] sobre [context].
  static Future<void> show(BuildContext context, Room room) =>
      showFrSheet<void>(context, builder: (_) => InviteSheet(room: room));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fr = context.fr;
    final copy = t.room.sheets.invite;
    final nfc = ref.watch(nfcSupportedProvider).value ?? false;
    final wifi = room.wifi;
    final uri = const BuildInviteQr().buildUri(
      RoomInvite(
        host: room.hostAddress,
        port: room.port,
        roomId: room.id,
        accessCode: room.accessCode,
        note: room.note,
        name: room.name,
        wifi: wifi,
      ),
    );
    return SingleChildScrollView(
      child: FrSheet(
        children: [
          RoomSheetHeader(
            kicker: copy.kicker,
            title: copy.title,
            message: wifi == null ? copy.message : copy.messageWifi,
          ),
          Center(child: InviteQr(data: uri)),
          _InviteFacts(room: room),
          if (wifi != null) InviteNetwork(wifi: wifi),
          if (nfc) InviteNfc(invite: uri),
          Text(
            copy.footer(list: t.lobby.nearbyRooms),
            textAlign: TextAlign.center,
            style: fr.type.bodyS.copyWith(color: fr.colors.tx3),
          ),
        ],
      ),
    );
  }
}

/// «También por NFC» (`.nfc-box` del prototipo): en Android, acercar otro
/// teléfono lee la invitación (este hace de etiqueta mientras dura la
/// frecu); en los dos, «Grabar etiqueta» la graba en una etiqueta NFC.
class InviteNfc extends StatelessWidget {
  /// Crea el recuadro de [invite].
  const InviteNfc({required this.invite, super.key});

  /// Invitación (`frecu://join?…`).
  final String invite;

  @override
  Widget build(BuildContext context) {
    final fr = context.fr;
    final c = fr.colors;
    final copy = t.room.sheets.invite;
    final iphone = Theme.of(context).platform == TargetPlatform.iOS;
    return Container(
      key: const Key('invite_nfc'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.bg2,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.line1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: c.line2),
                ),
                child: Center(
                  child: FrIcon(FrIcons.nfc, size: 20, color: c.tx2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      copy.nfcTitle,
                      style: fr.type.body.copyWith(
                        fontWeight: FontWeight.w600,
                        fontVariations: const [FontVariation.weight(600)],
                        color: c.tx1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      iphone ? copy.nfcMessageTag : copy.nfcMessage,
                      style: fr.type.bodyS.copyWith(color: c.tx3),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Debajo del texto: a su lado lo aplastaba en un teléfono real.
          FrButton.drawn(
            key: const Key('invite_nfc_write'),
            label: copy.nfcWrite,
            icon: FrIcons.nfc,
            variant: FrButtonVariant.secondary,
            size: FrButtonSize.small,
            expand: true,
            onPressed: () => unawaited(NfcWriteSheet.show(context, invite)),
          ),
        ],
      ),
    );
  }
}

/// QR de la invitación (`.qr-frame` y `drawQR`): módulos redondos y ojos de
/// esquina suave en tinta sobre un marco claro en los dos temas, con
/// corrección H y la marca de Frecu al centro, y un haz que lo recorre
/// (quieto con movimiento reducido).
class InviteQr extends StatelessWidget {
  /// Crea el QR de [data].
  const InviteQr({required this.data, super.key});

  /// URI de la invitación (`frecu://join?…`).
  final String data;

  /// Lado del marco.
  static const double size = 236;

  /// Lado del código dentro del marco (18 px de margen silencioso).
  static const double _code = 200;

  /// Lado de la marca del centro: 7,2 celdas del QR de 29 del prototipo.
  static const double _mark = _code * 7.2 / 29;

  /// Fondo claro del marco, igual en los dos temas para poder escanearlo.
  static const Color paper = Color(0xFFF4F6F1);

  /// Tinta de los módulos.
  static const Color ink = Color(0xFF0B0D0F);

  @override
  Widget build(BuildContext context) {
    final c = context.fr.colors;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: paper,
        borderRadius: BorderRadius.circular(34),
        border: Border.all(color: c.line2),
        boxShadow: [
          BoxShadow(
            color: c.signal.withValues(alpha: 0.5),
            blurRadius: 60,
            spreadRadius: -20,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Semantics(
            image: true,
            label: t.room.sheets.invite.qr,
            child: CustomPaint(
              key: const Key('invite_qr_code'),
              size: const Size.square(_code),
              painter: InviteQrPainter(
                image: InviteQrPainter.encode(data),
                ink: ink,
                hole: _mark,
              ),
            ),
          ),
          const _FrecuMark(side: _mark),
          if (!context.reduceMotion)
            Positioned.fill(
              child: FrLoop(
                builder: (context, seconds) => CustomPaint(
                  painter: _ScanBeamPainter(seconds: seconds, color: c.signal),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Pintor del QR de la invitación (`drawQR` del prototipo) sobre el `QrCode`
/// del paquete `qr`: cada módulo oscuro es un punto de 0,8 celdas, los tres
/// ojos son un aro de una celda con radio 2 y un centro de 3 × 3 con radio
/// 1,1, y el cuadro central de lado [hole] queda libre para la marca.
class InviteQrPainter extends CustomPainter {
  /// Pinta [image] en [ink], dejando libre un cuadro central de [hole] px.
  const InviteQrPainter({
    required this.image,
    required this.ink,
    this.hole = 0,
  });

  /// Codifica [data] con corrección de errores H (la marca tapa el centro).
  static QrImage encode(String data) => QrImage(
    QrCode.fromData(data: data, errorCorrectLevel: QrErrorCorrectLevel.H),
  );

  /// Módulos del código.
  final QrImage image;

  /// Color de los módulos.
  final Color ink;

  /// Lado del cuadro central sin módulos, en px.
  final double hole;

  @override
  void paint(Canvas canvas, Size size) {
    final n = image.moduleCount;
    final cell = math.min(size.width, size.height) / n;
    final center = Offset(n * cell / 2, n * cell / 2);
    final free = Rect.fromCenter(center: center, width: hole, height: hole);
    final fill = Paint()..color = ink;
    for (var y = 0; y < n; y++) {
      for (var x = 0; x < n; x++) {
        if (_inEye(x, y, n) || !image.isDark(y, x)) continue;
        final dot = Offset((x + 0.5) * cell, (y + 0.5) * cell);
        if (hole > 0 && free.inflate(cell * 0.5).contains(dot)) continue;
        canvas.drawCircle(dot, cell * 0.4, fill);
      }
    }
    final ring = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = cell;
    for (final (ex, ey) in [(0, 0), (n - 7, 0), (0, n - 7)]) {
      canvas
        ..drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              (ex + 0.5) * cell,
              (ey + 0.5) * cell,
              6 * cell,
              6 * cell,
            ),
            Radius.circular(2 * cell),
          ),
          ring,
        )
        ..drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH((ex + 2) * cell, (ey + 2) * cell, 3 * cell, 3 * cell),
            Radius.circular(1.1 * cell),
          ),
          fill,
        );
    }
  }

  /// Si el módulo ([x], [y]) es parte de un ojo o de su separador.
  static bool _inEye(int x, int y, int n) =>
      (x < 8 && y < 8) || (x > n - 9 && y < 8) || (x < 8 && y > n - 9);

  @override
  bool shouldRepaint(InviteQrPainter oldDelegate) =>
      oldDelegate.image != image ||
      oldDelegate.ink != ink ||
      oldDelegate.hole != hole;
}

/// Cuadro de tinta del centro del QR con la marca de Frecu.
class _FrecuMark extends StatelessWidget {
  const _FrecuMark({required this.side});

  final double side;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: side,
      height: side,
      decoration: BoxDecoration(
        color: InviteQr.ink,
        borderRadius: BorderRadius.circular(side * 2 / 7.2),
      ),
      child: CustomPaint(
        painter: _FrecuSignaturePainter(
          radius: side / 3,
          color: context.fr.colors.signal,
        ),
      ),
    );
  }
}

/// Marca de Frecu: Lissajous 2:3 con fase 0,6 ([SignatureParams.brand]),
/// quieta y en el verde, que sobre la tinta se ve en los dos temas.
class _FrecuSignaturePainter extends CustomPainter {
  const _FrecuSignaturePainter({required this.radius, required this.color});

  final double radius;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const brand = SignatureParams.brand;
    final center = size.center(Offset.zero);
    final path = Path();
    const steps = 160;
    for (var i = 0; i <= steps; i++) {
      final u = i / steps * math.pi * 2;
      final point =
          center +
          Offset(math.sin(brand.a * u + brand.phase), math.sin(brand.b * u)) *
              radius;
      i == 0
          ? path.moveTo(point.dx, point.dy)
          : path.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_FrecuSignaturePainter old) =>
      old.radius != radius || old.color != color;
}

/// Haz de 30 px que baja y sube por el QR en 3,2 s (`qrscan`).
class _ScanBeamPainter extends CustomPainter {
  _ScanBeamPainter({required this.seconds, required this.color})
    : super(repaint: seconds);

  final ValueListenable<double> seconds;
  final Color color;

  static const double _period = 3.2;

  @override
  void paint(Canvas canvas, Size size) {
    final phase = seconds.value % _period / _period;
    final wave = (1 - math.cos(phase * math.pi * 2)) / 2;
    final top = 8 + (size.height - 46) * Curves.easeInOut.transform(wave);
    final band = Rect.fromLTWH(14, top, size.width - 28, 30);
    canvas.drawRRect(
      RRect.fromRectAndRadius(band, const Radius.circular(6)),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: 0),
            color.withValues(alpha: 0.35),
            color.withValues(alpha: 0),
          ],
        ).createShader(band),
    );
  }

  @override
  bool shouldRepaint(_ScanBeamPainter old) =>
      old.seconds != seconds || old.color != color;
}

/// Ficha de la invitación (`.inv-meta`): nota, código y anfitrión.
class _InviteFacts extends StatelessWidget {
  const _InviteFacts({required this.room});

  final Room room;

  @override
  Widget build(BuildContext context) {
    final fr = context.fr;
    final c = fr.colors;
    final copy = t.room.sheets.invite;
    final note = room.note;
    final big = fr.type.digits.copyWith(
      fontSize: 26,
      height: 0.9,
      color: c.tx1,
    );
    return RoomFacts(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      gap: 6,
      facts: [
        RoomFact(
          flex: 8,
          label: copy.note,
          values: [
            if (note != null)
              RoomNoteName(note: note, size: 26)
            else
              Text(t.lobby.noNote, style: big),
          ],
        ),
        RoomFact(
          flex: 9,
          label: copy.code,
          values: [
            Text(room.accessCode, key: const Key('invite_code'), style: big),
          ],
        ),
        RoomFact(
          flex: 13,
          label: copy.host,
          values: [
            Text(
              room.hostAddress,
              key: const Key('invite_host'),
              style: fr.type.data.copyWith(color: c.tx1),
            ),
            Text(
              copy.port(port: room.port).toUpperCase(),
              style: fr.type.labelS.copyWith(color: c.tx3),
            ),
          ],
        ),
      ],
    );
  }
}

/// La red de la frecu bajo la ficha (`.nfc-box` del prototipo de la red de
/// Frecu): su nombre y su clave, por si alguien se une a mano.
class InviteNetwork extends StatelessWidget {
  /// Crea la fila de la red [wifi].
  const InviteNetwork({required this.wifi, super.key});

  /// Red de la frecu.
  final WifiCredentials wifi;

  @override
  Widget build(BuildContext context) {
    final fr = context.fr;
    final c = fr.colors;
    final copy = t.room.sheets.invite;
    final key = wifi.passphrase;
    final data = fr.type.data;
    return DecoratedBox(
      key: const Key('invite_network'),
      decoration: ShapeDecoration(
        color: c.bg1,
        shape: RoundedSuperellipseBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: c.line1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: ShapeDecoration(
                color: c.bg2,
                shape: RoundedSuperellipseBorder(
                  borderRadius: BorderRadius.circular(13),
                  side: BorderSide(color: c.line1),
                ),
              ),
              child: Center(child: FrIcon(FrIcons.hotspot, color: c.signalFg)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 3,
                children: [
                  Text(
                    wifi.ssid,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: data.copyWith(color: c.tx1),
                  ),
                  if (key == null)
                    Text(
                      copy.wifiOpen,
                      style: fr.type.bodyS.copyWith(color: c.tx3),
                    )
                  else
                    Text.rich(
                      TextSpan(
                        text: copy.wifiKey(key: ''),
                        children: [
                          TextSpan(
                            text: key,
                            style: data.copyWith(color: c.tx2, fontSize: 12.5),
                          ),
                        ],
                      ),
                      style: fr.type.bodyS.copyWith(color: c.tx3),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              copy.byHand.toUpperCase(),
              style: fr.type.labelS.copyWith(color: c.tx3),
            ),
          ],
        ),
      ),
    );
  }
}

/// Celda de una [RoomFacts]: su etiqueta y sus valores.
@immutable
class RoomFact {
  /// Crea la celda; [flex] es su parte del ancho.
  const RoomFact({required this.label, required this.values, this.flex = 1});

  /// Etiqueta, en `labelS` y mayúsculas.
  final String label;

  /// Valores bajo la etiqueta; se achican si la celda queda angosta.
  final List<Widget> values;

  /// Parte del ancho de la ficha.
  final int flex;
}

/// Ficha en celdas `bg1` separadas por 1 px de `line1`, con radio 18
/// (`.inv-meta` y `.stats` del prototipo).
class RoomFacts extends StatelessWidget {
  /// Crea la ficha con [facts].
  const RoomFacts({
    required this.facts,
    this.padding = const EdgeInsets.all(14),
    this.gap = 8,
    super.key,
  });

  /// Celdas, de izquierda a derecha.
  final List<RoomFact> facts;

  /// Relleno de cada celda.
  final EdgeInsets padding;

  /// Separación entre la etiqueta y los valores.
  final double gap;

  @override
  Widget build(BuildContext context) {
    final c = context.fr.colors;
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: c.line1,
          border: Border.all(color: c.line1),
          borderRadius: BorderRadius.circular(18),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 1,
            children: [for (final fact in facts) _cell(context, fact)],
          ),
        ),
      ),
    );
  }

  Widget _cell(BuildContext context, RoomFact fact) {
    final fr = context.fr;
    return Expanded(
      flex: fact.flex,
      child: ColoredBox(
        color: fr.colors.bg1,
        child: Padding(
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: gap,
            children: [
              Text(
                fact.label.toUpperCase(),
                style: fr.type.labelS.copyWith(color: fr.colors.tx3),
              ),
              for (final value in fact.values)
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: value,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
