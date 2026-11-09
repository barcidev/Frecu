import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frecu/core/design/fr_theme.dart';
import 'package:frecu/core/design/icons/fr_icon.dart';
import 'package:frecu/core/design/icons/fr_icons.dart';
import 'package:frecu/core/design/widgets/fr_banner.dart';
import 'package:frecu/core/design/widgets/fr_button.dart';
import 'package:frecu/core/design/widgets/fr_pill.dart';
import 'package:frecu/core/design/widgets/fr_scaffold.dart';
import 'package:frecu/core/design/widgets/wave_loader.dart';
import 'package:frecu/core/error/failure.dart';
import 'package:frecu/features/lobby/presentation/widgets/create_room_layout.dart';
import 'package:frecu/features/lobby/presentation/widgets/hotspot_guide_step.dart';
import 'package:frecu/features/lobby/presentation/widgets/hotspot_illustration.dart';
import 'package:frecu/features/network/presentation/providers/local_hotspot_provider.dart';
import 'package:frecu/features/network/presentation/providers/network_provider.dart';
import 'package:frecu/i18n/strings.g.dart';

/// Paso 1 de 2 de la creación en Android (`hostNet` del prototipo de la red
/// de Frecu): Frecu crea la red de la frecu con `LocalOnlyHotspot`.
///
/// Sin red, explica en tres pasos qué pasa, con «Crear la red» y «Prefiero
/// mi zona Wi-Fi» (la guía de siempre). Mientras Android la crea, la onda y
/// Cancelar; al aire, su nombre y Seguir; si falla, un aviso con qué hacer
/// (encender permisos, apagar la zona Wi-Fi…) y Reintentar.
class LocalNetworkStep extends ConsumerWidget {
  /// Crea el paso.
  const LocalNetworkStep({
    required this.onBack,
    required this.onContinue,
    required this.onUseHotspot,
    super.key,
  });

  /// Sale de la creación.
  final VoidCallback onBack;

  /// Pasa a la nueva frecu: con la red al aire o, si la zona Wi-Fi ya está
  /// encendida, con ella.
  final VoidCallback onContinue;

  /// Abre la guía de la zona Wi-Fi.
  final VoidCallback onUseHotspot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(localHotspotProvider);
    final hotspot = ref.read(localHotspotProvider.notifier);
    final dock = _NetworkDock(
      state: state,
      onCreate: () => unawaited(hotspot.start()),
      onCancel: () => unawaited(hotspot.stop()),
      onContinue: onContinue,
      onUseHotspot: () {
        unawaited(hotspot.stop());
        onUseHotspot();
      },
    );
    return FrScaffold(
      dock: dock,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CreateRoomAppBar(
            step: 1,
            title: t.lobby.newRoom.guide.title,
            onBack: onBack,
          ),
          Expanded(
            child: CreateRoomScroll(
              dockHeight: dock.oneButton
                  ? CreateRoomScroll.oneButtonDock
                  : CreateRoomScroll.twoButtonDock,
              children: [
                const HotspotIllustration(),
                _Heading(ready: state is LocalHotspotReady),
                _body(context, ref, state),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _body(BuildContext context, WidgetRef ref, LocalHotspotState state) {
    final settings = ref.read(systemSettingsRepositoryProvider);
    return switch (state) {
      LocalHotspotOff() || LocalHotspotLost() => const _Steps(),
      LocalHotspotStarting() => const _Padded(child: _Creating()),
      LocalHotspotReady(:final hotspot) => _Padded(
        child: LocalNetworkCard(ssid: hotspot.credentials.ssid),
      ),
      LocalHotspotFailed(:final reason) => _Padded(
        child: LocalNetworkFailure(
          reason: reason,
          onOpenHotspotSettings: () =>
              unawaited(settings.openHotspotSettings()),
          onOpenAppSettings: () => unawaited(settings.openAppSettings()),
          onOpenLocationSettings: () =>
              unawaited(settings.openLocationSettings()),
        ),
      ),
    };
  }
}

/// «Frecu crea la red» o, al aire, «Tu red está al aire», con su texto.
class _Heading extends StatelessWidget {
  const _Heading({required this.ready});

  final bool ready;

  @override
  Widget build(BuildContext context) {
    final fr = context.fr;
    final copy = t.lobby.newRoom.network;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ready ? copy.readyHeading : copy.heading,
            style: createRoomTitleStyle(fr),
          ),
          const SizedBox(height: 8),
          Text(
            ready ? copy.readyMessage : copy.message,
            style: createRoomMessageStyle(fr),
          ),
        ],
      ),
    );
  }
}

class _Padded extends StatelessWidget {
  const _Padded({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      Padding(padding: const EdgeInsets.fromLTRB(20, 20, 20, 0), child: child);
}

/// Los tres pasos: crear la red, mostrar el QR y que se apaga al cerrar.
class _Steps extends StatelessWidget {
  const _Steps();

  @override
  Widget build(BuildContext context) {
    final steps = t.lobby.newRoom.network.steps;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < steps.length; i++)
            HotspotGuideStepRow(number: i + 1, step: steps[i]),
        ],
      ),
    );
  }
}

/// «Creando la red…» con la onda (`.wifi-step`).
class _Creating extends StatelessWidget {
  const _Creating();

  @override
  Widget build(BuildContext context) {
    final copy = t.lobby.newRoom.network;
    return LocalNetworkPanel(
      leading: const WaveLoader(width: 46, height: 20),
      title: copy.creating,
      message: copy.creatingHint,
    );
  }
}

/// Recuadro de la red (`.wifi-step` y `.nfc-box`): algo a la izquierda, un
/// título y un texto, y algo opcional a la derecha.
class LocalNetworkPanel extends StatelessWidget {
  /// Crea el recuadro.
  const LocalNetworkPanel({
    required this.leading,
    required this.title,
    required this.message,
    this.kicker,
    this.trailing,
    this.titleStyle,
    super.key,
  });

  /// Ícono u onda de la izquierda.
  final Widget leading;

  /// Línea superior, en `labelS` y mayúsculas.
  final String? kicker;

  /// Título.
  final String title;

  /// Texto bajo el título.
  final String message;

  /// Píldora u otra cosa a la derecha.
  final Widget? trailing;

  /// Estilo del título; por defecto, 600 a 14,5 px.
  final TextStyle? titleStyle;

  @override
  Widget build(BuildContext context) {
    final fr = context.fr;
    final c = fr.colors;
    final kicker = this.kicker;
    final trailing = this.trailing;
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: c.bg1,
        shape: RoundedSuperellipseBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: c.signal.withValues(alpha: 0.35)),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            leading,
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (kicker != null) ...[
                    Text(
                      kicker.toUpperCase(),
                      style: fr.type.labelS.copyWith(color: c.signalFg),
                    ),
                    const SizedBox(height: 4),
                  ],
                  Text(
                    title,
                    style:
                        titleStyle ??
                        fr.type.body.copyWith(
                          fontSize: 14.5,
                          height: 1.3,
                          color: c.tx1,
                          fontWeight: FontWeight.w600,
                          fontVariations: const [FontVariation.weight(600)],
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(message, style: fr.type.bodyS.copyWith(color: c.tx3)),
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 12), trailing],
          ],
        ),
      ),
    );
  }
}

/// La red al aire: su nombre, que la clave viaja en el QR y «Al aire».
class LocalNetworkCard extends StatelessWidget {
  /// Crea la tarjeta de la red [ssid].
  const LocalNetworkCard({required this.ssid, super.key});

  /// Nombre de la red.
  final String ssid;

  @override
  Widget build(BuildContext context) {
    final fr = context.fr;
    final c = fr.colors;
    final copy = t.lobby.newRoom.network;
    return LocalNetworkPanel(
      leading: Container(
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
      kicker: copy.label,
      title: ssid,
      titleStyle: fr.type.data.copyWith(fontSize: 15, color: c.tx1),
      message: copy.keyInQr,
      trailing: FrPill(label: copy.onAir),
    );
  }
}

/// Aviso de por qué no se creó la red, con su acción: abrir los ajustes de
/// la zona Wi-Fi, de la app (el permiso) o de ubicación.
class LocalNetworkFailure extends StatelessWidget {
  /// Crea el aviso de [reason].
  const LocalNetworkFailure({
    required this.reason,
    required this.onOpenHotspotSettings,
    required this.onOpenAppSettings,
    required this.onOpenLocationSettings,
    super.key,
  });

  /// Por qué no se creó.
  final HotspotFailureReason reason;

  /// Abre los ajustes de la zona Wi-Fi.
  final VoidCallback onOpenHotspotSettings;

  /// Abre los ajustes de la app, donde están sus permisos.
  final VoidCallback onOpenAppSettings;

  /// Abre los ajustes de ubicación.
  final VoidCallback onOpenLocationSettings;

  @override
  Widget build(BuildContext context) {
    final copy = t.lobby.newRoom.network;
    final (tone, icon, title, message, action, onAction) = switch (reason) {
      HotspotFailureReason.hotspotOn => (
        FrBannerTone.warn,
        FrIcons.hotspot,
        copy.hotspotOnTitle,
        copy.hotspotOnMessage,
        copy.hotspotOnAction,
        onOpenHotspotSettings,
      ),
      HotspotFailureReason.nearbyDenied => (
        FrBannerTone.alert,
        FrIcons.lock,
        copy.nearbyDeniedTitle,
        copy.nearbyDeniedMessage,
        copy.permissionAction,
        onOpenAppSettings,
      ),
      HotspotFailureReason.locationDenied => (
        FrBannerTone.alert,
        FrIcons.lock,
        copy.locationDeniedTitle,
        copy.locationDeniedMessage,
        copy.permissionAction,
        onOpenAppSettings,
      ),
      HotspotFailureReason.locationOff => (
        FrBannerTone.alert,
        FrIcons.alert,
        copy.locationOffTitle,
        copy.locationOffMessage,
        copy.locationOffAction,
        onOpenLocationSettings,
      ),
      HotspotFailureReason.unsupported => (
        FrBannerTone.info,
        FrIcons.info,
        copy.unsupportedTitle,
        copy.unsupportedMessage,
        null,
        null,
      ),
      HotspotFailureReason.failed => (
        FrBannerTone.alert,
        FrIcons.alert,
        copy.failedTitle,
        copy.failedMessage,
        null,
        null,
      ),
    };
    return FrBanner.drawn(
      tone: tone,
      icon: icon,
      title: title,
      message: message,
      actionLabel: action,
      onAction: onAction,
    );
  }
}

/// Dock del paso, según en qué está la red.
class _NetworkDock extends StatelessWidget {
  const _NetworkDock({
    required this.state,
    required this.onCreate,
    required this.onCancel,
    required this.onContinue,
    required this.onUseHotspot,
  });

  final LocalHotspotState state;
  final VoidCallback onCreate;
  final VoidCallback onCancel;
  final VoidCallback onContinue;
  final VoidCallback onUseHotspot;

  /// Con la red al aire, o sin forma de crearla, el dock lleva un solo botón.
  bool get oneButton =>
      state is LocalHotspotReady ||
      state == const LocalHotspotState.failed(HotspotFailureReason.unsupported);

  @override
  Widget build(BuildContext context) {
    final copy = t.lobby.newRoom.network;
    final (Widget primary, Widget? secondary) = switch (state) {
      LocalHotspotOff() || LocalHotspotLost() => (
        FrButton.drawn(
          label: copy.create,
          icon: FrIcons.hotspot,
          expand: true,
          onPressed: onCreate,
        ),
        _ghost(copy.useHotspot, onUseHotspot),
      ),
      LocalHotspotStarting() => (
        FrButton(
          label: copy.creating,
          loading: true,
          expand: true,
          onPressed: () {},
        ),
        _ghost(copy.cancel, onCancel),
      ),
      LocalHotspotReady() => (
        FrButton.drawn(
          label: copy.kContinue,
          trailingIcon: FrIcons.arrow,
          expand: true,
          onPressed: onContinue,
        ),
        null,
      ),
      LocalHotspotFailed(reason: HotspotFailureReason.unsupported) => (
        FrButton.drawn(
          label: copy.useHotspot,
          icon: FrIcons.hotspot,
          expand: true,
          onPressed: onUseHotspot,
        ),
        null,
      ),
      LocalHotspotFailed(:final reason) => (
        FrButton.drawn(
          label: copy.retry,
          icon: FrIcons.regen,
          expand: true,
          onPressed: onCreate,
        ),
        reason == HotspotFailureReason.hotspotOn
            ? _ghost(copy.keepHotspot, onContinue)
            : _ghost(copy.useHotspot, onUseHotspot),
      ),
    };
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CreateRoomFitWidth(child: primary),
        if (secondary != null) ...[
          const SizedBox(height: 10),
          CreateRoomFitWidth(child: secondary),
        ],
      ],
    );
  }

  static Widget _ghost(String label, VoidCallback onPressed) => FrButton(
    label: label,
    variant: FrButtonVariant.ghost,
    expand: true,
    onPressed: onPressed,
  );
}
