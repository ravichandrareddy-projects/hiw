//purchase screen
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class PurchasesScreen extends StatelessWidget {
  const PurchasesScreen({super.key});

  Future<void> _openYt() async {
    final url = Uri.parse('https://www.youtube.com/results?search_query=easy+vegetable+recipe+healthy');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final veggies = ['Tomato', 'Potato', 'Carrot', 'Cucumber', 'Coriander'];
    final fruits = ['Apple', 'Banana', 'Pomegranate'];
    final others = ['Rice', 'Oil', 'Curd'];

    return Scaffold(
      appBar: AppBar(title: const Text('My Purchases Today'), backgroundColor: const Color(0xFF020617)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Veggies', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Wrap(spacing: 8, children: veggies.map((e) => Chip(label: Text(e), backgroundColor: Colors.white.withOpacity(0.03))).toList()),
          const SizedBox(height: 12),
          const Text('Fruits', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Wrap(spacing: 8, children: fruits.map((e) => Chip(label: Text(e), backgroundColor: Colors.white.withOpacity(0.03))).toList()),
          const SizedBox(height: 12),
          const Text('Others', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Wrap(spacing: 8, children: others.map((e) => Chip(label: Text(e), backgroundColor: Colors.white.withOpacity(0.03))).toList()),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.02), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white12)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('IGRIS Suggests (demo)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text('• Tomato + potato + beans → veg curry\n• Use curd for simple raita\n• Keep fried items low'),
                    const SizedBox(height: 12),
                    Align(alignment: Alignment.centerRight, child: ElevatedButton.icon(onPressed: _openYt, icon: const Icon(Icons.play_circle_outline), label: const Text('Open related recipes on YouTube'))),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
