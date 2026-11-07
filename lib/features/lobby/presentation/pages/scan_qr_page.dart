import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frecu/app/router/app_router.gr.dart';
import 'package:frecu/core/result/result.dart';
import 'package:frecu/features/lobby/domain/usecases/parse_invite_from_qr.dart';
import 'package:frecu/features/room/domain/entities/room_invite.dart';
import 'package:frecu/features/room/presentation/extensions/failure_extension.dart';
import 'package:frecu/features/room/presentation/providers/room_provider.dart';
import 'package:frecu/i18n/strings.g.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Constructor de widget para inyectar escáner en pruebas.
typedef ScannerWidgetBuilder = Widget Function(
  BuildContext context,
  void Function(String barcode) onBarcodeScanned,
);

/// Pantalla para escanear código QR de invitación a una frecu.
@RoutePage()
class ScanQrPage extends ConsumerStatefulWidget {
  /// Constructor constante con escáner inyectable para pruebas.
  const ScanQrPage({super.key, this.scannerBuilder});

  /// Constructor opcional para construir el widget del escáner en pruebas.
  final ScannerWidgetBuilder? scannerBuilder;

  @override
  ConsumerState<ScanQrPage> createState() => _ScanQrPageState();
}

class _ScanQrPageState extends ConsumerState<ScanQrPage> {
  bool _isProcessing = false;
  final _parser = const ParseInviteFromQr();

  Future<void> _handleBarcode(String rawValue) async {
    if (_isProcessing) return;

    final parseResult = _parser.parse(rawValue);
    if (parseResult.isFailure) {
      _showError('Código QR de invitación no válido');
      return;
    }

    final invite = parseResult.dataOrNull!;
    await _connectToRoom(invite);
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _connectToRoom(RoomInvite invite) async {
    setState(() => _isProcessing = true);

    final result = await ref
        .read(roomNotifierProvider.notifier)
        .joinRoom(
          hostAddress: invite.host,
          port: invite.port,
          accessCode: invite.accessCode,
          displayName: 'Participante',
          note: invite.note,
        );

    if (!mounted) return;
    setState(() => _isProcessing = false);

    switch (result) {
      case Success(:final data):
        try {
          unawaited(context.router.replace(RoomRoute(roomId: data.id)));
        } on Object catch (_) {}
      case FailureResult(:final failure):
        _showError(failure.toLocalizedMessage());
    }
  }

  Widget _buildScanner() {
    if (widget.scannerBuilder != null) {
      return widget.scannerBuilder!(context, _handleBarcode);
    }

    return MobileScanner(
      onDetect: (capture) {
        final barcode = capture.barcodes.firstOrNull;
        final raw = barcode?.rawValue;
        if (raw != null) {
          unawaited(_handleBarcode(raw));
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(t.lobby.scanQr)),
      body: Stack(
        children: [
          _buildScanner(),
          if (_isProcessing) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
