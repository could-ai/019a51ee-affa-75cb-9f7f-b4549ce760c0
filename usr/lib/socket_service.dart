import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  // Singleton pattern to ensure only one instance of SocketService is created.
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;

  // Getter for the socket instance. Throws an exception if not initialized.
  IO.Socket get socket {
    if (_socket == null) {
      throw Exception("Socket not initialized. Call connect() first.");
    }
    return _socket!;
  }

  // Connects to the Socket.IO server.
  void connect() {
    // The server address is hardcoded here. 
    // For Android emulator, use 'http://10.0.2.2:3000'.
    // For web and other platforms, 'http://localhost:3000' should work if the server is on the same machine.
    _socket = IO.io('http://localhost:3000', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    _socket!.connect();

    _socket!.onConnect((_) {
      print('Connected to socket server');
    });

    _socket!.onDisconnect((_) => print('Disconnected from socket server'));
  }

  // Disposes of the socket connection.
  void dispose() {
    _socket?.dispose();
    _socket = null;
  }
}
