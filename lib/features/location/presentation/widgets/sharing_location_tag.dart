import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frecu/core/design/fr_theme.dart';
import 'package:frecu/core/design/icons/fr_icon.dart';
import 'package:frecu/core/design/icons/fr_icons.dart';
import 'package:frecu/features/location/presentation/providers/location_provider.dart';
import 'package:frecu/i18n/strings.g.dart';

/// «Compartes tu ubicación» (`.geo-tag`): bajo la malla mientras se
/// comparte; si no, no ocupa nada.
class SharingLocationTag extends ConsumerWidget {
  /// Crea la etiqueta.
  const SharingLocationTag({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sharing = ref.watch(
      locationSharingProvider.select((location) => location.sharing),
    );
    if (!sharing) return const SizedBox.shrink();
    final fr = context.fr;
    final c = fr.colors;
    return Row(
      key: const Key('sharing_location_tag'),
      mainAxisSize: MainAxisSize.min,
      spacing: 6,
      children: [
        FrIcon(FrIcons.pin, size: 16, color: c.signalFg),
        Text(
          t.location.sharingTag.toUpperCase(),
          style: fr.type.labelS.copyWith(color: c.tx2),
        ),
      ],
    );
  }
}
