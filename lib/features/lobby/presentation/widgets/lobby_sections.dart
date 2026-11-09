import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:frecu/app/router/app_router.gr.dart';
import 'package:frecu/core/design/fr_theme.dart';
import 'package:frecu/core/design/icons/fr_icons.dart';
import 'package:frecu/core/design/tokens/fr_type.dart';
import 'package:frecu/core/design/widgets/fr_banner.dart';
import 'package:frecu/core/design/widgets/fr_button.dart';
import 'package:frecu/core/design/widgets/fr_icon_button.dart';
import 'package:frecu/core/design/widgets/fr_pill.dart';
import 'package:frecu/core/design/widgets/signal_signature.dart';
import 'package:frecu/core/design/widgets/wave_loader.dart';
import 'package:frecu/features/network/domain/entities/network_state.dart';
import 'package:frecu/i18n/strings.g.dart';

/// Cabecera de 60 px: la marca, la píldora de red y Ajustes.
class LobbyHeader extends StatelessWidget {
  /// Crea la cabecera con el estado de la red [network].
  const LobbyHeader({required this.network, super.key});

  /// Estado de la red local; nulo si aún no se sabe.
  final NetworkState? network;

  @override
  Widget build(BuildContext context) {
    final lobby = t.lobby;
    final (label, tone) = switch (network) {
      null => (lobby.network.checking, FrPillTone.warn),
      NetworkConnected(:final ipAddress) => (
        lobby.network.connected(ip: ipAddress),
        FrPillTone.ok,
      ),
      NetworkDisconnected() => (lobby.network.offline, FrPillTone.alert),
    };
    return SizedBox(
      height: 60,
      child: Padding(
        padding: const EdgeInsets.only(left: 20, right: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const _Wordmark(),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: FrPill(
                    label: label,
                    tone: tone,
                    busy: network == null,
                  ),
                ),
              ),
            ),
            FrIconButton.drawn(
              icon: FrIcons.sliders,
              semanticLabel: lobby.settings,
              onPressed: () => context.router.push(const SettingsRoute()),
            ),
          ],
        ),
      ),
    );
  }
}

/// Marca: la firma de señal y «frecu».
class _Wordmark extends StatelessWidget {
  const _Wordmark();

  @override
  Widget build(BuildContext context) {
    final c = context.fr.colors;
    final title = t.lobby.title;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SignalSignature.brand(size: 26),
        const SizedBox(width: 8),
        Text(
          title,
          maxLines: 1,
          style: TextStyle(
            fontFamily: FrFonts.ui,
            fontSize: 21,
            height: 1,
            fontWeight: const FontWeight(780),
            fontVariations: const [
              FontVariation.weight(780),
              FontVariation.width(125),
            ],
            letterSpacing: -0.03 * 21,
            color: c.tx1,
          ),
        ),
      ],
    );
  }
}

/// «Frecus cercanas», «Elige tu frecu» y el número de frecus en dos cifras.
class LobbyHeading extends StatelessWidget {
  /// Crea el encabezado con [count] frecus cercanas.
  const LobbyHeading({required this.count, super.key});

  /// Frecus cercanas.
  final int count;

  @override
  Widget build(BuildContext context) {
    final fr = context.fr;
    final c = fr.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _Kicker(),
                const SizedBox(height: 10),
                Text(
                  t.lobby.heading,
                  style: fr.type.display.copyWith(fontSize: 28, color: c.tx1),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            count.toString().padLeft(2, '0'),
            style: fr.type.digits.copyWith(
              fontSize: 44,
              height: 0.8,
              color: c.tx1,
            ),
          ),
        ],
      ),
    );
  }
}

/// Búsqueda vacía: la onda y qué hacer mientras no aparecen frecus.
class LobbyEmptySearch extends StatelessWidget {
  /// Crea la búsqueda vacía; con [failed], la búsqueda no pudo empezar y se
  /// reintenta.
  const LobbyEmptySearch({this.failed = false, super.key});

  /// La búsqueda falló: en lugar de «La búsqueda sigue activa» dice que
  /// falló y que se reintenta.
  final bool failed;

  @override
  Widget build(BuildContext context) {
    final fr = context.fr;
    final c = fr.colors;
    final empty = t.lobby.empty;
    return ListView(
      padding: const EdgeInsets.fromLTRB(26, 26, 26, 200),
      children: [
        Column(
          children: [
            const WaveLoader(width: 80, height: 26),
            const SizedBox(height: 18),
            Text(
              empty.title,
              textAlign: TextAlign.center,
              style: fr.type.title.copyWith(
                fontSize: 18,
                height: 1.2,
                fontWeight: const FontWeight(640),
                fontVariations: const [
                  FontVariation.weight(640),
                  FontVariation.width(112),
                ],
                color: c.tx1,
              ),
            ),
            const SizedBox(height: 10),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 290),
              child: Text(
                empty.message,
                textAlign: TextAlign.center,
                style: fr.type.body.copyWith(
                  fontSize: 14,
                  height: 1.5,
                  color: c.tx2,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              (failed ? empty.failed : empty.searching).toUpperCase(),
              textAlign: TextAlign.center,
              style: fr.type.labelS.copyWith(color: failed ? c.alert : c.tx3),
            ),
          ],
        ),
      ],
    );
  }
}

/// Aviso sin red local: en lugar de la búsqueda vacía, con «Abrir ajustes
/// de Wi-Fi».
class LobbyOfflineNotice extends StatelessWidget {
  /// Crea el aviso; la acción llama a [onOpenSettings].
  const LobbyOfflineNotice({required this.onOpenSettings, super.key});

  /// Abre los ajustes de Wi-Fi del sistema.
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final offline = t.lobby.offline;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 200),
      children: [
        FrBanner.drawn(
          tone: FrBannerTone.alert,
          icon: FrIcons.wifi,
          title: offline.title,
          message: offline.message,
          actionLabel: offline.openSettings,
          onAction: onOpenSettings,
        ),
      ],
    );
  }
}

/// Dock: Crear frecu y Escanear en una fila (1,25 : 1) y Conectar por IP
/// debajo.
class LobbyDock extends StatelessWidget {
  /// Crea el dock; Conectar por IP llama a [onJoinByIp].
  const LobbyDock({required this.onJoinByIp, super.key});

  /// Abre el diálogo de unión por IP.
  final VoidCallback onJoinByIp;

  @override
  Widget build(BuildContext context) {
    final lobby = t.lobby;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              flex: 125,
              child: _FitWidth(
                child: FrButton.drawn(
                  label: lobby.createRoom,
                  icon: FrIcons.plus,
                  expand: true,
                  onPressed: () => context.router.push(const CreateRoomRoute()),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 100,
              child: _FitWidth(
                child: FrButton.drawn(
                  label: lobby.scanQr,
                  icon: FrIcons.scan,
                  variant: FrButtonVariant.secondary,
                  expand: true,
                  onPressed: () => context.router.push(ScanQrRoute()),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _FitWidth(
          child: FrButton.drawn(
            label: lobby.joinRoom,
            icon: FrIcons.nodes,
            variant: FrButtonVariant.ghost,
            expand: true,
            onPressed: onJoinByIp,
          ),
        ),
      ],
    );
  }
}

/// Ocupa todo el ancho y, si el botón no cabe (un teléfono de 360 px o un
/// texto largo), lo encoge en lugar de desbordarlo.
class _FitWidth extends StatelessWidget {
  const _FitWidth({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) => FittedBox(
      fit: BoxFit.scaleDown,
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: box.maxWidth),
        child: IntrinsicWidth(child: child),
      ),
    ),
  );
}

/// «Frecus cercanas» tras la línea de señal, en mayúsculas como etiqueta
/// (`.kicker`).
class _Kicker extends StatelessWidget {
  const _Kicker();

  @override
  Widget build(BuildContext context) {
    final fr = context.fr;
    final c = fr.colors;
    return Row(
      children: [
        SizedBox(width: 16, height: 1, child: ColoredBox(color: c.signalFg)),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            t.lobby.nearbyRooms.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: fr.type.label.copyWith(color: c.tx3),
          ),
        ),
      ],
    );
  }
}
