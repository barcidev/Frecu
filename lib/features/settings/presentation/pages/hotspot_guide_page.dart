import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/widgets.dart';
import 'package:frecu/features/lobby/presentation/widgets/hotspot_guide_step.dart';

/// Guía del punto de acceso abierta desde Ajustes: la misma de crear una
/// frecu ([HotspotGuideStep]), sola. Atrás y sus dos botones vuelven a
/// Ajustes.
@RoutePage()
class HotspotGuidePage extends StatelessWidget {
  /// Constructor constante.
  const HotspotGuidePage({super.key});

  @override
  Widget build(BuildContext context) {
    void back() => unawaited(context.router.maybePop());
    return HotspotGuideStep(onBack: back, onContinue: back, showStep: false);
  }
}
