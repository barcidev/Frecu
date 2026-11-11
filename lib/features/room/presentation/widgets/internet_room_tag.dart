import 'package:flutter/widgets.dart';
import 'package:frecu/core/design/fr_theme.dart';
import 'package:frecu/core/design/icons/fr_icon.dart';
import 'package:frecu/core/design/icons/fr_icons.dart';
import 'package:frecu/i18n/strings.g.dart';

/// «Por internet» (`.net-tag` del prototipo): indicador discreto bajo la
/// malla de una frecu abierta también por internet.
class InternetRoomTag extends StatelessWidget {
  /// Crea la etiqueta.
  const InternetRoomTag({super.key});

  @override
  Widget build(BuildContext context) {
    final fr = context.fr;
    final c = fr.colors;
    return Row(
      key: const Key('internet_room_tag'),
      mainAxisSize: MainAxisSize.min,
      spacing: 6,
      children: [
        FrIcon(FrIcons.globe, size: 16, color: c.signalFg),
        Text(
          t.room.header.internetTag.toUpperCase(),
          style: fr.type.labelS.copyWith(color: c.tx2),
        ),
      ],
    );
  }
}
