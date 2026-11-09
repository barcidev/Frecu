import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frecu/features/location/presentation/location_labels.dart';
import 'package:frecu/features/location/presentation/providers/location_provider.dart';
import 'package:frecu/features/messages/presentation/providers/messages_provider.dart';
import 'package:frecu/features/messages/presentation/widgets/sos_alert_view.dart';
import 'package:frecu/features/room/presentation/providers/room_provider.dart';
import 'package:frecu/i18n/strings.g.dart';

/// Capa de la frecu que muestra la alarma del SOS más antiguo sin atender y
/// vuelve a vibrar cada [remindEvery] mientras quede alguno. Sin SOS no
/// ocupa nada. Al salir de la frecu los olvida.
class SosAlertLayer extends ConsumerStatefulWidget {
  /// Crea la capa.
  const SosAlertLayer({super.key});

  /// Cada cuánto vuelve a vibrar un SOS sin atender.
  static const Duration remindEvery = Duration(seconds: 5);

  @override
  ConsumerState<SosAlertLayer> createState() => _SosAlertLayerState();
}

class _SosAlertLayerState extends ConsumerState<SosAlertLayer> {
  Timer? _reminder;
  late SosAlerts _alerts;

  @override
  void initState() {
    super.initState();
    _alerts = ref.read(sosAlertsProvider.notifier);
  }

  @override
  void dispose() {
    _reminder?.cancel();
    // Fuera del desmontaje: no se cambian providers mientras se retira el
    // árbol.
    final alerts = _alerts;
    scheduleMicrotask(alerts.clear);
    super.dispose();
  }

  void _syncReminder({required bool active}) {
    if (!active) {
      _reminder?.cancel();
      _reminder = null;
      return;
    }
    _reminder ??= Timer.periodic(SosAlertLayer.remindEvery, (_) {
      ref.read(sosAlertsProvider.notifier).remind();
    });
  }

  @override
  Widget build(BuildContext context) {
    final alerts = ref.watch(sosAlertsProvider);
    _syncReminder(active: alerts.isNotEmpty);
    if (alerts.isEmpty) return const SizedBox.shrink();
    final sos = alerts.first;
    final people = ref.watch(roomParticipantsProvider).value ?? const [];
    final name = people
        .where((p) => p.id == sos.senderId)
        .map((p) => p.displayName)
        .firstOrNull;
    final notifier = ref.read(sosAlertsProvider.notifier);
    final towards = ref.watch(locationSharingProvider).towards(sos.senderId);
    return Positioned.fill(
      child: SosAlertView(
        key: ValueKey('sos_${sos.senderId}'),
        name: name ?? '',
        // Con las dos ubicaciones compartidas, a qué distancia y hacia dónde.
        detail: towards == null
            ? null
            : t.location.sosDetail(
                distance: distanceLabel(towards.meters),
                direction: compassLongLabel(towards.bearing),
              ),
        onMyWay: () => unawaited(notifier.dismiss(sos.senderId, onMyWay: true)),
        onDismiss: () => unawaited(notifier.dismiss(sos.senderId)),
      ),
    );
  }
}
