import 'package:flutter/material.dart';

class ProteinHistoryScreen extends StatelessWidget {
  ProteinHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text("Protein History")),
      body: const Center(
        child: Text(
          "Protein history coming soon",
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
