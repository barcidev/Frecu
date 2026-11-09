import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frecu/core/design/fr_theme.dart';
import 'package:frecu/core/design/icons/fr_icons.dart';
import 'package:frecu/core/design/motion/reduced_motion.dart';
import 'package:frecu/core/design/widgets/fr_banner.dart';
import 'package:frecu/features/network/presentation/providers/local_hotspot_provider.dart';
import 'package:frecu/features/room/presentation/providers/room_provider.dart';
import 'package:frecu/i18n/strings.g.dart';

/// Aviso del anfitrión cuando Android apaga la red de la frecu
/// (`roomNetDown` del prototipo de la red de Frecu): «La red de la frecu se
/// apagó», con «Crear la red de nuevo». Al crearla, la invitación lleva la
/// red nueva (y la IPv4 nueva, si cambió) para volver a mostrar el QR.
///
/// Solo aparece en la frecu que se abrió con la red de Frecu; en las demás
/// no ocupa espacio.
class RoomNetworkNotice extends ConsumerWidget {
  /// Crea el aviso.
  const RoomNetworkNotice({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fr = context.fr;
    final hosted =
        ref.watch(localHotspotAvailableProvider) &&
        ref.watch(roomNotifierProvider.select((room) => room?.wifi != null));
    final state = hosted ? ref.watch(localHotspotProvider) : null;
    final copy = t.room.network;
    final notice = switch (state) {
      LocalHotspotLost() => FrBanner.drawn(
        key: const Key('room_network_lost'),
        tone: FrBannerTone.alert,
        icon: FrIcons.hotspot,
        title: copy.lostTitle,
        message: copy.lostMessage,
        actionLabel: copy.recreate,
        onAction: () => unawaited(_recreate(ref)),
        floating: true,
      ),
      LocalHotspotStarting() => FrBanner.drawn(
        key: const Key('room_network_recreating'),
        tone: FrBannerTone.info,
        icon: FrIcons.hotspot,
        title: copy.recreating,
        floating: true,
      ),
      LocalHotspotFailed() => FrBanner.drawn(
        key: const Key('room_network_failed'),
        tone: FrBannerTone.alert,
        icon: FrIcons.alert,
        title: copy.failedTitle,
        message: copy.failedMessage,
        actionLabel: copy.recreate,
        onAction: () => unawaited(_recreate(ref)),
        floating: true,
      ),
      _ => null,
    };
    return AnimatedSwitcher(
      duration: context.reduceMotion ? fr.motion.quick : fr.motion.smooth,
      child: notice ?? const SizedBox.shrink(),
    );
  }

  /// Vuelve a crear la red y, si sale, la pone en la invitación.
  static Future<void> _recreate(WidgetRef ref) async {
    final hotspot = ref.read(localHotspotProvider.notifier);
    final rooms = ref.read(roomNotifierProvider.notifier);
    final repository = ref.read(roomRepositoryProvider);
    final next = await hotspot.start();
    if (next case LocalHotspotReady(:final hotspot)) {
      final address = await repository.getLocalIpAddress();
      rooms.useNetwork(hotspot.credentials, hostAddress: address);
    }
  }
}
