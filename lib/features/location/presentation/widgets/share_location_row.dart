import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frecu/core/design/widgets/fr_toast.dart';
import 'package:frecu/core/design/widgets/fr_toggle.dart';
import 'package:frecu/features/location/presentation/providers/location_provider.dart';
import 'package:frecu/features/settings/presentation/widgets/settings_group.dart';
import 'package:frecu/i18n/strings.g.dart';

/// «Compartir mi ubicación» (al final de la hoja de mensajes): apagado por
/// defecto; al encenderlo pide el permiso de ubicación si falta.
class ShareLocationRow extends ConsumerWidget {
  /// Crea la fila.
  const ShareLocationRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sharing = ref.watch(
      locationSharingProvider.select((location) => location.sharing),
    );
    final copy = t.location.share;
    return SettingsGroup(
      margin: EdgeInsets.zero,
      children: [
        SettingsRow(
          key: const Key('share_location_row'),
          title: copy.title,
          subtitle: sharing ? copy.on : copy.off,
          trailing: FrToggle(
            key: const Key('share_location_toggle'),
            value: sharing,
            semanticLabel: copy.title,
            onChanged: (on) => _toggle(context, ref, on: on),
          ),
        ),
      ],
    );
  }

  Future<void> _toggle(
    BuildContext context,
    WidgetRef ref, {
    required bool on,
  }) async {
    final outcome = await ref
        .read(locationSharingProvider.notifier)
        .setSharing(on: on);
    if (!context.mounted) return;
    final texts = t.location;
    final message = switch (outcome) {
      ShareLocationOutcome.sharing => null,
      ShareLocationOutcome.denied => texts.denied,
      ShareLocationOutcome.deniedForever => texts.deniedForever,
      ShareLocationOutcome.failed => texts.failed,
    };
    if (message != null) showFrToast(context, FrToast(message: message));
  }
}
