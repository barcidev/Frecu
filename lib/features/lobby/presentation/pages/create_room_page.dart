import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frecu/app/router/app_router.gr.dart';
import 'package:frecu/core/result/result.dart';
import 'package:frecu/features/lobby/presentation/providers/discovery_provider.dart';
import 'package:frecu/features/room/presentation/providers/room_provider.dart';
import 'package:frecu/i18n/strings.g.dart';

/// Pantalla para crear una nueva frecu como anfitrión.
@RoutePage()
class CreateRoomPage extends ConsumerStatefulWidget {
  /// Constructor constante.
  const CreateRoomPage({super.key});

  @override
  ConsumerState<CreateRoomPage> createState() => _CreateRoomPageState();
}

class _CreateRoomPageState extends ConsumerState<CreateRoomPage> {
  final _nameController = TextEditingController(text: 'Frecu');
  final _codeController = TextEditingController(text: '1234');
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _handleCreate() async {
    if (_nameController.text.trim().isEmpty) return;
    setState(() => _isLoading = true);

    final result = await ref
        .read(roomNotifierProvider.notifier)
        .createRoom(
          name: _nameController.text.trim(),
          accessCode: _codeController.text.trim(),
        );

    if (!mounted) return;
    setState(() => _isLoading = false);

    switch (result) {
      case Success(:final data):
        unawaited(
          ref
              .read(discoveryRepositoryProvider)
              .publishRoom(roomId: data.id, name: data.name, port: data.port),
        );
        unawaited(context.router.replace(RoomRoute(roomId: data.id)));
      case FailureResult(:final failure):
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(failure.toString())));
    }
  }

  Widget _buildIpBadge(AsyncValue<String?> localIpAsync) {
    return localIpAsync.when(
      data: (ip) => Text(
        'IP local: ${ip ?? "Desconocida"}',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localIpAsync = ref.watch(localIpProvider);

    return Scaffold(
      appBar: AppBar(title: Text(t.lobby.createRoom)),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildIpBadge(localIpAsync),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: t.lobby.roomName,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _codeController,
                decoration: InputDecoration(
                  labelText: t.lobby.accessCode,
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                maxLength: 4,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _isLoading ? null : _handleCreate,
                icon: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add_circle_outline),
                label: Text(t.lobby.createRoom),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
