import 'package:flutter/material.dart';
import 'package:frecu/core/design/fr_theme.dart';
import 'package:frecu/core/design/icons/fr_icon_data.dart';
import 'package:frecu/core/design/icons/fr_icons.dart';
import 'package:frecu/core/design/widgets/fr_icon_button.dart';
import 'package:frecu/core/design/widgets/fr_sheet.dart';
import 'package:frecu/features/room/domain/entities/audio_route.dart';
import 'package:frecu/i18n/strings.g.dart';

/// Ícono propio de cada ruta de audio (`ROUTES` del prototipo).
FrIconData audioRouteIcon(AudioRoute route) => switch (route) {
  AudioRoute.speaker => FrIcons.speaker,
  AudioRoute.earpiece => FrIcons.earpiece,
  AudioRoute.bluetooth => FrIcons.headset,
};

/// Nombre de cada ruta de audio; la de Bluetooth lleva el nombre del
/// dispositivo ([deviceName], p. ej. «Sena 50S») si se conoce.
String audioRouteName(AudioRoute route, {String? deviceName}) =>
    switch (route) {
      AudioRoute.speaker => t.room.speaker,
      AudioRoute.earpiece => t.room.earpiece,
      AudioRoute.bluetooth => deviceName ?? t.room.bluetooth,
    };

/// Encabezado de las hojas de la frecu (`.sh-h`): la línea superior, el
/// título, el mensaje y Cerrar.
class RoomSheetHeader extends StatelessWidget {
  /// Crea el encabezado.
  const RoomSheetHeader({
    required this.kicker,
    required this.title,
    required this.message,
    super.key,
  });

  /// Línea superior, en `labelS` y mayúsculas.
  final String kicker;

  /// Título.
  final String title;

  /// Mensaje bajo el título.
  final String message;

  @override
  Widget build(BuildContext context) {
    final fr = context.fr;
    final c = fr.colors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                kicker.toUpperCase(),
                style: fr.type.labelS.copyWith(color: c.tx3),
              ),
              const SizedBox(height: 8),
              Text(title, style: FrSheet.titleStyle(fr)),
              const SizedBox(height: 6),
              Text(
                message,
                style: fr.type.body.copyWith(
                  fontSize: 14,
                  height: 1.45,
                  color: c.tx2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        FrIconButton.drawn(
          key: const Key('sheet_close'),
          icon: FrIcons.close,
          semanticLabel: t.room.sheets.close,
          compact: true,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ],
    );
  }
}
