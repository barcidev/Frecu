import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frecu/features/lobby/presentation/widgets/hotspot_credentials_sheet.dart';
import 'package:frecu/features/lobby/presentation/widgets/hotspot_guide_step.dart';
import 'package:frecu/features/network/presentation/providers/local_hotspot_provider.dart';
import 'package:frecu/features/network/presentation/providers/network_provider.dart';
import 'package:frecu/features/settings/presentation/providers/preferences_provider.dart';

/// Guía del punto de acceso abierta desde Ajustes: la misma de crear una
/// frecu ([HotspotGuideStep]), sola. Atrás y sus dos botones vuelven a
/// Ajustes, y el botón de la plataforma de este teléfono abre sus ajustes
/// del punto de acceso.
@RoutePage()
class HotspotGuidePage extends ConsumerWidget {
  /// Constructor constante.
  const HotspotGuidePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void back() => unawaited(context.router.maybePop());
    return HotspotGuideStep(
      onBack: back,
      onContinue: back,
      showStep: false,
      onOpenHotspotSettings: () => unawaited(
        ref.read(systemSettingsRepositoryProvider).openHotspotSettings(),
      ),
      onSaveHotspot: ref.watch(localHotspotAvailableProvider)
          ? () => unawaited(HotspotCredentialsSheet.show(context))
          : null,
      hotspotSaved: ref.watch(
        preferencesProvider.select((p) => p.value?.hotspot != null),
      ),
    );
  }
}
