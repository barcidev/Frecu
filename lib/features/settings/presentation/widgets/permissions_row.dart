import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frecu/core/design/widgets/fr_tag.dart';
import 'package:frecu/features/permissions/presentation/providers/onboarding_permissions_provider.dart';
import 'package:frecu/features/settings/presentation/widgets/settings_group.dart';
import 'package:frecu/i18n/strings.g.dart';

/// Fila «Permisos» de Ajustes (`UI.row('Permisos', …, '3/3 ›')`): los
/// permisos que pide la bienvenida y cuántos están concedidos, en señal si
/// están todos.
///
/// Al tocarla pide los que faltan y, si alguno quedó negado para siempre (o
/// ya estaban todos), abre los ajustes de la app. Al volver a la app, p. ej.
/// desde esos ajustes, vuelve a leer los permisos.
class PermissionsRow extends ConsumerStatefulWidget {
  /// Crea la fila.
  const PermissionsRow({super.key});

  @override
  ConsumerState<PermissionsRow> createState() => _PermissionsRowState();
}

class _PermissionsRowState extends ConsumerState<PermissionsRow> {
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

  void _manage() => unawaited(_notifier.requestOrOpenSettings());

  @override
  Widget build(BuildContext context) {
    final copy = t.settings.permissions;
    final state = ref.watch(onboardingPermissionsProvider).value;
    return SettingsRow(
      title: copy.title,
      subtitle: copy.subtitle,
      trailing: state == null ? null : _count(state),
      onPressed: _manage,
    );
  }

  /// Etiqueta «concedidos/total».
  Widget _count(OnboardingPermissionsState state) {
    final granted = onboardingPermissions
        .where(
          (permission) => state.stateOf(permission) == PermissionState.granted,
        )
        .length;
    return FrTag(
      label: t.settings.permissions.count(
        granted: granted,
        total: onboardingPermissions.length,
      ),
      tone: state.allGranted ? FrTagTone.signal : FrTagTone.neutral,
    );
  }
}
