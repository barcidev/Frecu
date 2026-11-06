import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:frecu/i18n/strings.g.dart';

/// Pantalla para crear una nueva frecu como anfitrión.
@RoutePage()
class CreateRoomPage extends StatelessWidget {
  /// Constructor constante.
  const CreateRoomPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(t.lobby.createRoom)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                decoration: InputDecoration(labelText: t.lobby.roomName),
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(labelText: t.lobby.accessCode),
                keyboardType: TextInputType.number,
                maxLength: 4,
              ),
              const SizedBox(height: 24),
              FilledButton(onPressed: () {}, child: Text(t.lobby.createRoom)),
            ],
          ),
        ),
      ),
    );
  }
}
