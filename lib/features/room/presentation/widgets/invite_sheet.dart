import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:frecu/core/design/fr_theme.dart';
import 'package:frecu/core/design/motion/reduced_motion.dart';
import 'package:frecu/core/design/widgets/fr_sheet.dart';
import 'package:frecu/features/room/domain/entities/room.dart';
import 'package:frecu/features/room/domain/entities/room_invite.dart';
import 'package:frecu/features/room/domain/usecases/build_invite_qr.dart';
import 'package:frecu/features/room/presentation/widgets/room_header.dart';
import 'package:frecu/features/room/presentation/widgets/room_sheets.dart';
import 'package:frecu/i18n/strings.g.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Hoja para invitar a la frecu (`SH.invite` del prototipo): el QR de la
/// invitación y, debajo, la nota, el código de acceso y la IP del anfitrión.
class InviteSheet extends StatelessWidget {
  /// Crea la hoja de [room].
  const InviteSheet({required this.room, super.key});

  /// Frecu a la que se invita.
  final Room room;

  /// Abre la hoja de [room] sobre [context].
  static Future<void> show(BuildContext context, Room room) =>
      showFrSheet<void>(context, builder: (_) => InviteSheet(room: room));

  @override
  Widget build(BuildContext context) {
    final fr = context.fr;
    final copy = t.room.sheets.invite;
    final uri = const BuildInviteQr().buildUri(
      RoomInvite(
        host: room.hostAddress,
        port: room.port,
        roomId: room.id,
        accessCode: room.accessCode,
        note: room.note,
      ),
    );
    return SingleChildScrollView(
      child: FrSheet(
        children: [
          RoomSheetHeader(
            kicker: copy.kicker,
            title: copy.title,
            message: copy.message,
          ),
          Center(child: InviteQr(data: uri)),
          _InviteFacts(room: room),
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

/// QR de la invitación (`.qr-frame` y `drawQR`): módulos redondos en tinta
/// sobre un marco claro en los dos temas, la firma de Frecu al centro y un
/// haz que lo recorre (quieto con movimiento reducido).
class InviteQr extends StatelessWidget {
  /// Crea el QR de [data].
  const InviteQr({required this.data, super.key});

  /// URI de la invitación (`frecu://join?…`).
  final String data;

  /// Lado del marco.
  static const double size = 236;

  /// Lado del código dentro del marco.
  static const double _code = 200;

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
          QrImageView(
            data: data,
            size: _code,
            padding: EdgeInsets.zero,
            errorCorrectionLevel: QrErrorCorrectLevel.H,
            semanticsLabel: t.room.sheets.invite.qr,
            eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: ink),
            dataModuleStyle: const QrDataModuleStyle(
              dataModuleShape: QrDataModuleShape.circle,
              color: ink,
            ),
          ),
          const _FrecuMark(cell: _code / 29),
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

/// Cuadro de tinta del centro del QR con la firma de Frecu.
class _FrecuMark extends StatelessWidget {
  const _FrecuMark({required this.cell});

  final double cell;

  @override
  Widget build(BuildContext context) {
    final side = cell * 7.2;
    return Container(
      width: side,
      height: side,
      decoration: BoxDecoration(
        color: InviteQr.ink,
        borderRadius: BorderRadius.circular(cell * 2),
      ),
      child: CustomPaint(
        painter: _FrecuSignaturePainter(
          radius: cell * 2.4,
          color: context.fr.colors.signal,
        ),
      ),
    );
  }
}

/// Firma de Frecu: Lissajous 2:3 con fase 0,6.
class _FrecuSignaturePainter extends CustomPainter {
  const _FrecuSignaturePainter({required this.radius, required this.color});

  final double radius;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final path = Path();
    const steps = 160;
    for (var i = 0; i <= steps; i++) {
      final u = i / steps * math.pi * 2;
      final point =
          center + Offset(math.sin(2 * u + 0.6), math.sin(3 * u)) * radius;
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
