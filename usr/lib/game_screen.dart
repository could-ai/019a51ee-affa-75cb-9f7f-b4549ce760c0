import 'package:flutter/material.dart';
import 'package:couldai_user_app/socket_service.dart';

// Data model for a player in the game.
class Player {
  final String id;
  String name;
  double x, y;
  int hp;

  Player({required this.id, required this.name, required this.x, required this.y, this.hp = 100});

  // Factory constructor to create a Player instance from a map (e.g., from JSON).
  factory Player.fromMap(Map<String, dynamic> map) {
    return Player(
      id: map['id'],
      name: map['name'] ?? '',
      x: (map['x'] as num).toDouble(),
      y: (map['y'] as num).toDouble(),
      hp: map['hp'] ?? 100,
    );
  }
}

class GameScreen extends StatefulWidget {
  final dynamic initialData;
  const GameScreen({super.key, required this.initialData});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final SocketService _socketService = SocketService();
  Map<String, Player> _players = {};
  String _myId = '';

  @override
  void initState() {
    super.initState();
    _myId = _socketService.socket.id!;
    _initializeGame(widget.initialData);
    _setupSocketListeners();
  }

  // Initialize the game state with data received from the server.
  void _initializeGame(dynamic data) {
    final playersMap = data['players'] as Map<String, dynamic>;
    setState(() {
      _players = playersMap.map((id, playerData) =>
          MapEntry(id, Player.fromMap(playerData as Map<String, dynamic>)));
    });
  }

  // Set up listeners for real-time game events from the server.
  void _setupSocketListeners() {
    _socketService.socket.on('player_joined', (data) {
      if (mounted) {
        setState(() {
          _players[data['id']] = Player.fromMap(data['data'] as Map<String, dynamic>);
        });
      }
    });

    _socketService.socket.on('player_left', (data) {
      if (mounted) {
        setState(() {
          _players.remove(data['id']);
        });
      }
    });

    _socketService.socket.on('player_move', (data) {
      if (mounted && _players.containsKey(data['id'])) {
        setState(() {
          _players[data['id']]!.x = (data['data']['x'] as num).toDouble();
          _players[data['id']]!.y = (data['data']['y'] as num).toDouble();
        });
      }
    });
  }

  // Handle player movement via drag gestures and emit updates to the server.
  void _onDragUpdate(DragUpdateDetails details) {
    if (_players.containsKey(_myId)) {
      final player = _players[_myId]!;
      final newX = player.x + details.delta.dx;
      final newY = player.y + details.delta.dy;

      // Clamp position to an assumed 1000x600 map area.
      final clampedX = newX.clamp(0.0, 950.0); // 1000 - 50 (player width)
      final clampedY = newY.clamp(0.0, 550.0); // 600 - 50 (player height)

      setState(() {
        player.x = clampedX;
        player.y = clampedY;
      });
      _socketService.socket.emit('move', {'x': player.x, 'y': player.y});
    }
  }

  @override
  void dispose() {
    // Clean up listeners and inform the server that the player is leaving.
    _socketService.socket.off('player_joined');
    _socketService.socket.off('player_left');
    _socketService.socket.off('player_move');
    _socketService.socket.emit('leave');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Game'),
        automaticallyImplyLeading: false, // Disable back button
      ),
      body: GestureDetector(
        onPanUpdate: _onDragUpdate,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.grey[200],
          child: Stack(
            children: _players.values.map((player) {
              return Positioned(
                left: player.x,
                top: player.y,
                child: _buildPlayer(player),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  // Widget to represent a player on the screen.
  Widget _buildPlayer(Player player) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: player.id == _myId ? Colors.blue : Colors.red,
            shape: BoxShape.circle,
          ),
        ),
        Text(player.name, style: const TextStyle(fontSize: 12, color: Colors.black, backgroundColor: Colors.white54)),
      ],
    );
  }
}
