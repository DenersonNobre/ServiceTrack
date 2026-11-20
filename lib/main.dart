import 'package:flutter/material.dart';

void main() {
  runApp(const ServiceTrackApp());
}

class ServiceTrackApp extends StatelessWidget {
  const ServiceTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ServiceTrack',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF115E59),
        ),
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: Center(
          child: Text('ServiceTrack - Inicializado'),
        ),
      ),
    );
  }
}
