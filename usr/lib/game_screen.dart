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

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  final SocketService _socketService = SocketService();
  Map<String, Player> _players = {};
  String _myId = '';

  // For camera follow
  late AnimationController _animationController;
  Matrix4 _viewMatrix = Matrix4.identity();

  @override
  void initState() {
    super.initState();
    _myId = _socketService.socket.id!;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200), // Controls camera smoothness
    );

    _initializeGame(widget.initialData);
    _setupSocketListeners();

    // Center camera after the first frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final constraints =
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width, maxHeight: MediaQuery.of(context).size.height);
        _centerOnPlayer(constraints);
      }
    });
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

  // Animate the view matrix to smoothly center on the player.
  void _centerOnPlayer(BoxConstraints constraints) {
    if (!_players.containsKey(_myId)) return;

    final player = _players[_myId]!;
    final screenWidth = constraints.maxWidth;
    final screenHeight = constraints.maxHeight;

    // Target matrix to center the player
    final targetMatrix = Matrix4.identity()
      ..translate(screenWidth / 2 - player.x, screenHeight / 2 - player.y);

    // Animate from current matrix to target matrix
    final animation = Matrix4Tween(
      begin: _viewMatrix,
      end: targetMatrix,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    animation.addListener(() {
      if (mounted) {
        setState(() {
          _viewMatrix = animation.value;
        });
      }
    });

    _animationController.forward(from: 0.0);
  }

  // Handle player movement via drag gestures and emit updates to the server.
  void _onDragUpdate(DragUpdateDetails details, BoxConstraints constraints) {
    if (_players.containsKey(_myId)) {
      final player = _players[_myId]!;
      final newX = player.x + details.delta.dx;
      final newY = player.y + details.delta.dy;

      // Clamp position to an assumed 1000x600 map area.
      final clampedX = newX.clamp(0.0, 950.0); // 1000 - 50 (player width)
      final clampedY = newY.clamp(0.0, 550.0); // 600 - 50 (player height)

      if (player.x != clampedX || player.y != clampedY) {
        setState(() {
          player.x = clampedX;
          player.y = clampedY;
        });
        _socketService.socket.emit('move', {'x': player.x, 'y': player.y});
        _centerOnPlayer(constraints); // Update camera on move
      }
    }
  }

  @override
  void dispose() {
    // Clean up listeners and inform the server that the player is leaving.
    _animationController.dispose();
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          return GestureDetector(
            onPanUpdate: (details) => _onDragUpdate(details, constraints),
            child: ClipRect(
              child: Transform(
                transform: _viewMatrix,
                child: Container(
                  width: 1000,
                  height: 600,
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
            ),
          );
        },
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
