import 'package:flutter/material.dart';
import 'package:couldai_user_app/lobby_screen.dart';
import 'package:couldai_user_app/socket_service.dart';

void main() {
  // Initialize and connect the socket service when the app starts.
  SocketService().connect();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Socket.IO Game',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      // The LobbyScreen is set as the initial route of the application.
      home: const LobbyScreen(),
    );
  }
}
