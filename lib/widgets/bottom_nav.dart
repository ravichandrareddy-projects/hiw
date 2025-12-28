//bottom nav screen
import 'package:flutter/material.dart';

class BottomNav extends StatelessWidget {
  final int currentIndex;
  final void Function(int) onTap;
  const BottomNav({super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.92),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(22),
          topRight: Radius.circular(22),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.tealAccent.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(_items.length, (i) {
          final item = _items[i];
          final active = currentIndex == i;
          return GestureDetector(
            onTap: () => onTap(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: active ? Colors.tealAccent.withOpacity(0.18) : Colors.transparent,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(item.icon, color: active ? Colors.tealAccent : Colors.white70, size: active ? 26 : 22),
                  const SizedBox(height: 4),
                  Text(item.label, style: TextStyle(fontSize: 11, color: active ? Colors.tealAccent : Colors.white54)),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem(this.icon, this.label);
}

const _items = [
  _NavItem(Icons.smart_toy_outlined, 'Chatbot'),
  _NavItem(Icons.shopping_bag_outlined, 'Food'),
  _NavItem(Icons.camera_alt_outlined, 'HIW'),
  _NavItem(Icons.history, 'History'),
  _NavItem(Icons.person_outline, 'Avatar'),
];
