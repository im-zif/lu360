import 'package:flutter/material.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Map"),
      ),
      body: const Center(
        child: Text(
          "This is the MaP screen",
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}