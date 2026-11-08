import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frecu/core/design/fr_theme.dart';
import 'package:frecu/core/design/icons/fr_icon.dart';
import 'package:frecu/core/design/icons/fr_icon_data.dart';
import 'package:frecu/core/design/icons/fr_icons.dart';
import 'package:frecu/core/design/widgets/fr_button.dart';
import 'package:frecu/core/design/widgets/fr_icon_button.dart';
import 'package:frecu/core/design/widgets/fr_pressable.dart';
import 'package:frecu/core/design/widgets/fr_sheet.dart';
import 'package:frecu/features/room/domain/entities/audio_route.dart';
import 'package:frecu/features/room/presentation/providers/voice_provider.dart';
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

/// Hoja de la salida de audio (`SH.route` del prototipo): altavoz, auricular
/// y Bluetooth, con la ruta activa marcada y las no disponibles apagadas.
/// Elegir una cambia la ruta y cierra la hoja.
class AudioRouteSheet extends ConsumerWidget {
  /// Crea la hoja.
  const AudioRouteSheet({super.key});

  /// Abre la hoja sobre [context].
  static Future<void> show(BuildContext context) =>
      showFrSheet<void>(context, builder: (_) => const AudioRouteSheet());

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final voice = ref.watch(voiceNotifierProvider);
    final copy = t.room.sheets.route;
    return SingleChildScrollView(
      child: FrSheet(
        children: [
          RoomSheetHeader(
            kicker: copy.kicker,
            title: copy.title,
            message: copy.message,
          ),
          Column(
            spacing: 8,
            children: [
              for (final route in AudioRoute.values)
                AudioRouteOption(
                  key: Key('audio_route_option_${route.name}'),
                  route: route,
                  selected: voice.audioRoute == route,
                  enabled: voice.availableAudioRoutes.contains(route),
                  deviceName: voice.bluetoothName,
                  onPressed: () => _choose(context, ref, route),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _choose(BuildContext context, WidgetRef ref, AudioRoute route) {
    unawaited(ref.read(voiceNotifierProvider.notifier).setAudioRoute(route));
    unawaited(Navigator.of(context).maybePop());
  }
}

/// Opción de una ruta de audio (`.opt`): ícono, nombre, detalle y marca.
class AudioRouteOption extends StatelessWidget {
  /// Crea la opción de [route].
  const AudioRouteOption({
    required this.route,
    required this.selected,
    required this.enabled,
    required this.onPressed,
    this.deviceName,
    super.key,
  });

  /// Ruta que elige.
  final AudioRoute route;

  /// Es la ruta activa.
  final bool selected;

  /// La ruta está disponible; si no, se ve apagada y no responde.
  final bool enabled;

  /// Elige la ruta.
  final VoidCallback onPressed;

  /// Nombre del dispositivo Bluetooth conectado, si hay uno.
  final String? deviceName;

  /// Nombre del dispositivo, solo si la ruta Bluetooth está disponible.
  String? get _device =>
      route == AudioRoute.bluetooth && enabled ? deviceName : null;

  String get _detail {
    final copy = t.room.sheets.route;
    return switch (route) {
      AudioRoute.speaker => copy.speakerSub,
      AudioRoute.earpiece => copy.earpieceSub,
      AudioRoute.bluetooth when !enabled => copy.bluetoothOff,
      AudioRoute.bluetooth =>
        _device == null ? copy.bluetoothOn : copy.bluetoothDevice,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      child: Opacity(
        opacity: enabled ? 1 : 0.45,
        child: FrPressable(
          onPressed: enabled ? onPressed : null,
          pressedScale: 0.98,
          builder: (context, _, _) => _surface(context),
        ),
      ),
    );
  }

  Widget _surface(BuildContext context) {
    final fr = context.fr;
    final c = fr.colors;
    return AnimatedContainer(
      duration: fr.motion.smooth,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.bg1,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: selected ? c.signal.withValues(alpha: 0.55) : c.line1,
        ),
        boxShadow: [
          if (selected)
            BoxShadow(
              color: c.signal.withValues(alpha: 0.8),
              blurRadius: 30,
              spreadRadius: -16,
            ),
        ],
      ),
      child: Row(
        children: [
          _iconBox(fr),
          const SizedBox(width: 14),
          Expanded(child: _texts(fr)),
          const SizedBox(width: 14),
          _check(fr),
        ],
      ),
    );
  }

  Widget _iconBox(FrTheme fr) {
    final c = fr.colors;
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? c.signal.withValues(alpha: 0.1) : c.bg2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.line1),
      ),
      child: FrIcon(
        audioRouteIcon(route),
        color: selected ? c.signalFg : c.tx1,
      ),
    );
  }

  Widget _texts(FrTheme fr) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: 4,
    children: [
      Text(
        audioRouteName(route, deviceName: _device),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: fr.type.body.copyWith(
          fontSize: 15,
          height: 1.2,
          fontWeight: FontWeight.w600,
          fontVariations: const [FontVariation.weight(600)],
          color: fr.colors.tx1,
        ),
      ),
      Text(
        _detail.toUpperCase(),
        style: fr.type.labelS.copyWith(color: fr.colors.tx3),
      ),
    ],
  );

  Widget _check(FrTheme fr) {
    final c = fr.colors;
    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? c.signal : null,
        border: selected ? null : Border.all(color: c.line3, width: 1.5),
      ),
      child: selected
          ? FrIcon(FrIcons.check, size: 16, color: c.signalInk)
          : null,
    );
  }
}

/// Hoja que confirma salir de la frecu (`SH.leave` del prototipo). Para el
/// anfitrión dice que la frecu se cierra para las [others] personas.
class LeaveSheet extends StatelessWidget {
  /// Crea la hoja; [host] si la persona propia es la anfitriona.
  const LeaveSheet({required this.host, required this.others, super.key});

  /// La persona propia es la anfitriona.
  final bool host;

  /// Personas en la frecu además de la propia.
  final int others;

  /// Abre la hoja; devuelve si se confirmó.
  static Future<bool> show(
    BuildContext context, {
    required bool host,
    required int others,
  }) async =>
      await showFrSheet<bool>(
        context,
        builder: (_) => LeaveSheet(host: host, others: others),
      ) ??
      false;

  String get _message {
    final copy = t.room.sheets.leave;
    if (!host) return copy.peerMessage;
    if (others <= 0) return copy.hostAlone;
    if (others == 1) return copy.hostOne;
    return copy.hostMany(count: others);
  }

  @override
  Widget build(BuildContext context) {
    final copy = t.room.sheets.leave;
    final navigator = Navigator.of(context);
    return SingleChildScrollView(
      child: FrSheet(
        children: [
          _LeaveHeading(
            icon: host ? FrIcons.antenna : FrIcons.exit,
            title: host ? copy.hostTitle : copy.peerTitle,
            message: _message,
          ),
          Column(
            spacing: 10,
            children: [
              FrButton.drawn(
                key: const Key('leave_confirm'),
                label: host ? copy.hostConfirm : copy.peerConfirm,
                icon: FrIcons.exit,
                variant: FrButtonVariant.dangerSolid,
                expand: true,
                onPressed: () => navigator.pop(true),
              ),
              FrButton(
                key: const Key('leave_cancel'),
                label: copy.cancel,
                variant: FrButtonVariant.secondary,
                expand: true,
                onPressed: () => navigator.pop(false),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Ícono en alerta, título y consecuencia de salir, centrados.
class _LeaveHeading extends StatelessWidget {
  const _LeaveHeading({
    required this.icon,
    required this.title,
    required this.message,
  });

  final FrIconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final fr = context.fr;
    final c = fr.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 10, 6, 4),
      child: Column(
        spacing: 12,
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: c.bg2,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: c.line1),
            ),
            child: FrIcon(icon, size: 28, color: c.alert),
          ),
          Text(
            title,
            textAlign: TextAlign.center,
            style: fr.type.titleL.copyWith(
              fontSize: 22,
              height: 1.2,
              color: c.tx1,
            ),
          ),
          Text(
            message,
            textAlign: TextAlign.center,
            style: fr.type.body.copyWith(
              fontSize: 14.5,
              height: 1.55,
              color: c.tx2,
            ),
          ),
        ],
      ),
    );
  }
}
