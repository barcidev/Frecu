import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frecu/core/design/icons/fr_icons.dart';
import 'package:frecu/core/design/widgets/fr_button.dart';
import 'package:frecu/core/design/widgets/fr_field.dart';
import 'package:frecu/core/design/widgets/fr_sheet.dart';
import 'package:frecu/features/lobby/presentation/widgets/pin_join_sheet.dart';
import 'package:frecu/features/network/domain/entities/wifi_credentials.dart';
import 'package:frecu/features/settings/presentation/providers/preferences_provider.dart';
import 'package:frecu/i18n/strings.g.dart';

/// Hoja «Tu zona Wi-Fi» (`SH.hscred` del prototipo): el anfitrión Android
/// que usa su propia zona Wi-Fi escribe una vez su nombre y su clave
/// (ninguna app puede leerlos) para entregarlos por Bluetooth, con el código,
/// a quien esté cerca. Se guardan solo en este teléfono.
class HotspotCredentialsSheet extends ConsumerStatefulWidget {
  /// Crea la hoja.
  const HotspotCredentialsSheet({super.key});

  /// Abre la hoja sobre [context].
  static Future<void> show(BuildContext context) => showFrSheet<void>(
    context,
    builder: (_) => const HotspotCredentialsSheet(),
  );

  @override
  ConsumerState<HotspotCredentialsSheet> createState() =>
      _HotspotCredentialsSheetState();
}

class _HotspotCredentialsSheetState
    extends ConsumerState<HotspotCredentialsSheet> {
  late final WifiCredentials? _saved = ref
      .read(preferencesProvider)
      .value
      ?.hotspot;
  late final TextEditingController _ssid = TextEditingController(
    text: _saved?.ssid,
  );
  late final TextEditingController _key = TextEditingController(
    text: _saved?.passphrase,
  );
  bool _saving = false;

  @override
  void dispose() {
    _ssid.dispose();
    _key.dispose();
    super.dispose();
  }

  bool get _canSave => _ssid.text.trim().isNotEmpty && !_saving;

  Future<void> _save(WifiCredentials? hotspot) async {
    setState(() => _saving = true);
    await ref.read(preferencesProvider.notifier).setHotspot(hotspot);
    if (mounted) Navigator.of(context).pop();
  }

  void _submit() {
    if (!_canSave) return;
    final key = _key.text;
    unawaited(
      _save(
        WifiCredentials(
          ssid: _ssid.text.trim(),
          passphrase: key.isEmpty ? null : key,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final copy = t.lobby.newRoom.guide.hotspotSheet;
    return SingleChildScrollView(
      child: FrSheet(
        children: [
          JoinSheetHeader(
            kicker: copy.kicker,
            title: copy.title,
            message: copy.message,
            onClose: () => Navigator.of(context).maybePop(),
          ),
          FrField.drawn(
            key: const Key('hotspot_ssid'),
            label: copy.ssid,
            controller: _ssid,
            hint: copy.ssidHint,
            icon: FrIcons.hotspot,
            autofocus: _saved == null,
            textInputAction: TextInputAction.next,
            onChanged: (_) => setState(() {}),
          ),
          FrField.drawn(
            key: const Key('hotspot_key'),
            label: copy.key,
            controller: _key,
            help: copy.keyHelp,
            mono: true,
            icon: FrIcons.lock,
            keyboardType: TextInputType.visiblePassword,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
          ),
          FrButton.drawn(
            key: const Key('hotspot_save'),
            label: copy.save,
            icon: FrIcons.check,
            expand: true,
            loading: _saving,
            onPressed: _canSave ? _submit : null,
          ),
          if (_saved != null)
            FrButton(
              key: const Key('hotspot_forget'),
              label: copy.forget,
              variant: FrButtonVariant.ghost,
              expand: true,
              onPressed: _saving ? null : () => unawaited(_save(null)),
            ),
        ],
      ),
    );
  }
}
