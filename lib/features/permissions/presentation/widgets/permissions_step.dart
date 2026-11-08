import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frecu/core/design/fr_theme.dart';
import 'package:frecu/core/design/icons/fr_icon.dart';
import 'package:frecu/core/design/icons/fr_icon_data.dart';
import 'package:frecu/core/design/icons/fr_icons.dart';
import 'package:frecu/core/design/widgets/fr_button.dart';
import 'package:frecu/core/design/widgets/fr_scaffold.dart';
import 'package:frecu/features/permissions/domain/entities/app_permission.dart';
import 'package:frecu/features/permissions/presentation/providers/onboarding_permissions_provider.dart';
import 'package:frecu/features/permissions/presentation/widgets/onboarding_layout.dart';
import 'package:frecu/features/permissions/presentation/widgets/permission_row.dart';
import 'package:frecu/i18n/strings.g.dart';

/// Último paso del recorrido: los tres permisos con su porqué.
///
/// Conceder permisos pide los que faltan; después, o si ya estaban todos
/// concedidos, Continuar termina el recorrido. Al volver a la app (p. ej.
/// desde sus ajustes) vuelve a leer los estados.
class PermissionsStep extends ConsumerStatefulWidget {
  /// Crea el paso; [onFinish] termina el recorrido.
  const PermissionsStep({
    required this.onBack,
    required this.onFinish,
    super.key,
  });

  /// Vuelve al paso del nombre.
  final VoidCallback onBack;

  /// Termina el recorrido.
  final VoidCallback onFinish;

  @override
  ConsumerState<PermissionsStep> createState() => _PermissionsStepState();
}

class _PermissionsStepState extends ConsumerState<PermissionsStep> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: _refresh);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  OnboardingPermissions get _notifier =>
      ref.read(onboardingPermissionsProvider.notifier);

  void _refresh() => unawaited(_notifier.refresh());

  void _request() => unawaited(_notifier.requestMissing());

  void _openSettings() => unawaited(_notifier.openSettings());

  @override
  Widget build(BuildContext context) {
    final copy = t.permissions;
    final state =
        ref.watch(onboardingPermissionsProvider).value ??
        const OnboardingPermissionsState();
    return FrScaffold(
      body: OnboardingScroll(
        children: [
          OnboardingTopLine(step: 2, onBack: widget.onBack),
          OnboardingHeading(title: copy.title, message: copy.description),
          _PermissionRows(state: state, onOpenSettings: _openSettings),
          const _CameraNote(),
        ],
      ),
      dock: state.canContinue
          ? FrButton.drawn(
              label: copy.finish,
              trailingIcon: FrIcons.arrow,
              expand: true,
              onPressed: widget.onFinish,
            )
          : FrButton.drawn(
              label: copy.grant,
              icon: FrIcons.check,
              expand: true,
              loading: state.requesting,
              onPressed: _request,
            ),
    );
  }
}

/// Las tres filas de permisos, en el orden de [onboardingPermissions].
class _PermissionRows extends StatelessWidget {
  const _PermissionRows({required this.state, required this.onOpenSettings});

  final OnboardingPermissionsState state;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final copy = t.permissions;
    final rows = <(AppPermission, FrIconData, String, String)>[
      (
        AppPermission.microphone,
        FrIcons.mic,
        copy.microphone,
        copy.microphoneDesc,
      ),
      (
        AppPermission.bluetoothConnect,
        FrIcons.wifi,
        copy.nearbyDevices,
        copy.nearbyDevicesDesc,
      ),
      (
        AppPermission.notification,
        FrIcons.bell,
        copy.notifications,
        copy.notificationsDesc,
      ),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        children: [
          for (final (index, (permission, icon, title, why))
              in rows.indexed) ...[
            if (index > 0) const SizedBox(height: 10),
            PermissionRow(
              icon: icon,
              title: title,
              description: why,
              state: state.stateOf(permission),
              onOpenSettings: onOpenSettings,
            ),
          ],
        ],
      ),
    );
  }
}

/// Nota de la cámara: se pide solo al escanear un QR.
class _CameraNote extends StatelessWidget {
  const _CameraNote();

  @override
  Widget build(BuildContext context) {
    final fr = context.fr;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          FrIcon(FrIcons.camera, size: 16, color: fr.colors.tx3),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              t.permissions.camera,
              style: fr.type.bodyS.copyWith(color: fr.colors.tx3),
            ),
          ),
        ],
      ),
    );
  }
}
