import 'package:flutter/widgets.dart';
import 'package:frecu/core/design/fr_theme.dart';
import 'package:frecu/core/design/tokens/fr_type.dart';
import 'package:frecu/features/room/domain/entities/room_note.dart';
import 'package:frecu/i18n/strings.g.dart';

/// Textos de una [RoomNote] en el idioma de la app.
extension RoomNoteLabels on RoomNote {
  /// Nombre de la nota en el idioma de la app («Fa♯», «F♯»).
  String get localizedName => t.lobby.noteNames[pitchClass];

  /// Nombre y octava («Fa♯4»).
  String get label => '$localizedName$octave';

  /// Frecuencia con un decimal y el separador del idioma («329,6 Hz»).
  String get hzText => t.lobby.hz(
    value: hz.toStringAsFixed(1).replaceAll('.', t.lobby.decimalSeparator),
  );
}

/// Nota de una frecu (`.note` del prototipo): el nombre sin alteración en
/// `digits`, la alteración en Martian Mono a la mitad y arriba, y la octava
/// en `labelS` y `tx3` abajo.
class RoomNoteText extends StatelessWidget {
  /// Crea la nota [note] con el nombre a [size] px.
  const RoomNoteText({
    required this.note,
    this.size = 24,
    this.octaveSize,
    this.glow = false,
    super.key,
  });

  /// Nota que se muestra.
  final RoomNote note;

  /// Tamaño del nombre en px.
  final double size;

  /// Tamaño de la octava en px; por defecto, el de `labelS`.
  final double? octaveSize;

  /// Brillo de señal alrededor del nombre (`.note.big`).
  final bool glow;

  static final RegExp _accidental = RegExp('[♯♭]');

  /// Brillo de señal de `.note.big`.
  static Shadow _glowOf(Color signal) =>
      Shadow(color: signal.withValues(alpha: 0.3), blurRadius: 24);

  @override
  Widget build(BuildContext context) {
    final fr = context.fr;
    final c = fr.colors;
    final name = note.localizedName;
    final match = _accidental.firstMatch(name);
    final base = match == null ? name : name.substring(0, match.start);
    final accidental = match?.group(0);
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          base,
          maxLines: 1,
          style: fr.type.digits.copyWith(
            fontSize: size,
            height: 0.9,
            color: c.tx1,
            shadows: glow ? [_glowOf(c.signal)] : null,
          ),
        ),
        if (accidental != null)
          Padding(
            padding: EdgeInsets.only(left: 1, bottom: size * 0.42),
            child: Text(
              accidental,
              style: TextStyle(
                fontFamily: FrFonts.mono,
                fontSize: size / 2,
                height: 1,
                fontWeight: FontWeight.w600,
                color: c.tx1,
              ),
            ),
          ),
        _octave(fr),
      ],
    );
  }

  /// Octava abajo, en `labelS` y `tx3` o a [octaveSize] px.
  Widget _octave(FrTheme fr) => Padding(
    padding: EdgeInsets.only(left: 2, bottom: octaveSize == null ? 1 : 4),
    child: Text(
      '${note.octave}',
      style: fr.type.labelS.copyWith(
        height: 1,
        fontSize: octaveSize,
        color: fr.colors.tx3,
      ),
    ),
  );
}
