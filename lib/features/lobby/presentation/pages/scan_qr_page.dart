import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:frecu/i18n/strings.g.dart';

/// Pantalla para escanear código QR de invitación a una frecu.
@RoutePage()
class ScanQrPage extends StatelessWidget {
  /// Constructor constante.
  const ScanQrPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(t.lobby.scanQr)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.qr_code, size: 96),
            const SizedBox(height: 16),
            Text(t.lobby.scanQr),
          ],
        ),
      ),
    );
  }
}
