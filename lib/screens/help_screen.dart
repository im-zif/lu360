import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Help & Support")),
      body: const Padding(
        padding: EdgeInsets.all(20),
        child: Text(
          "For assistance contact:\n\nsupport@lu360.com\n\nOr visit admin office.",
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
