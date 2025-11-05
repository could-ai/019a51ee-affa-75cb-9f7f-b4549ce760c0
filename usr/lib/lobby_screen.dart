import 'package:flutter/material.dart';
import 'package:couldai_user_app/game_screen.dart';
import 'package:couldai_user_app/socket_service.dart';

class LobbyScreen extends StatefulWidget {
  const LobbyScreen({super.key});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  final TextEditingController _nameController = TextEditingController();
  final SocketService _socketService = SocketService();

  @override
  void initState() {
    super.initState();
    // Pre-fill the name field with a default value.
    _nameController.text = "Player${DateTime.now().millisecond}";
  }

  void _joinLobby() {
    if (_nameController.text.isNotEmpty) {
      // Emit the 'join_lobby' event with the player's name.
      _socketService.socket.emit('join_lobby', {'name': _nameController.text});

      // Listen for the 'init' event from the server, which contains the initial game state.
      _socketService.socket.on('init', (data) {
        // Important: remove the listener after use to prevent multiple navigations.
        _socketService.socket.off('init');
        // Navigate to the GameScreen with the initial data.
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GameScreen(initialData: data),
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Game Lobby'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Enter your name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _joinLobby,
                child: const Text('Join Game'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
