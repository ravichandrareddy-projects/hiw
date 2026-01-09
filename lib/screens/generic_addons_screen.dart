import 'package:flutter/material.dart';
import '../core/food_addons_config.dart';
import '../widgets/glass_card.dart';
import '../widgets/glass_button.dart';

class GenericAddonsScreen extends StatefulWidget {
  final String foodLabel;
  final List<FoodAddon> addons;

  const GenericAddonsScreen({
    super.key,
    required this.foodLabel,
    required this.addons,
  });

  @override
  State<GenericAddonsScreen> createState() => _GenericAddonsScreenState();
}

class _GenericAddonsScreenState extends State<GenericAddonsScreen> {
  final Map<String, dynamic> _values = {};

  @override
  void initState() {
    super.initState();

    // initialize defaults
    for (final addon in widget.addons) {
      switch (addon.type) {
        case AddonType.counter:
          _values[addon.id] = addon.min > 0 ? addon.min : 1;
          break;
        case AddonType.singleChoice:
          _values[addon.id] =
              addon.options.isNotEmpty ? addon.options.first.id : null;
          break;
        case AddonType.multiChoice:
          _values[addon.id] = <String>{};
          break;
        case AddonType.toggle:
          _values[addon.id] = false;
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Customize ${widget.foodLabel.toUpperCase()}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: widget.addons.map(_buildAddon).toList(),
              ),
            ),

            const SizedBox(height: 12),

            GlassButton(
              text: 'Apply',
              icon: Icons.check,
              onTap: () {
                Navigator.pop(context, _values);
              },
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------
  // BUILD EACH ADDON
  // -------------------------
  Widget _buildAddon(FoodAddon addon) {
    switch (addon.type) {
      case AddonType.counter:
        return _counterAddon(addon);
      case AddonType.singleChoice:
        return _singleChoiceAddon(addon);
      case AddonType.multiChoice:
        return _multiChoiceAddon(addon);
      case AddonType.toggle:
        return _toggleAddon(addon);
    }
  }

  // -------------------------
  // COUNTER
  // -------------------------
  Widget _counterAddon(FoodAddon addon) {
    int value = _values[addon.id];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              addon.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: value > addon.min
                      ? () => setState(() => _values[addon.id] = value - 1)
                      : null,
                ),
                Text(
                  value.toString(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: value < addon.max
                      ? () => setState(() => _values[addon.id] = value + 1)
                      : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------
  // SINGLE CHOICE
  // -------------------------
  Widget _singleChoiceAddon(FoodAddon addon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              addon.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),

            ...addon.options.map((opt) {
              return RadioListTile<String>(
                value: opt.id,
                groupValue: _values[addon.id],
                onChanged: (v) => setState(() => _values[addon.id] = v),
                title: Text(
                  opt.label,
                  style: const TextStyle(color: Colors.white),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // -------------------------
  // MULTI CHOICE
  // -------------------------
  Widget _multiChoiceAddon(FoodAddon addon) {
    final Set<String> selected = _values[addon.id];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              addon.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),

            ...addon.options.map((opt) {
              return CheckboxListTile(
                value: selected.contains(opt.id),
                onChanged: (v) {
                  setState(() {
                    if (v == true) {
                      selected.add(opt.id);
                    } else {
                      selected.remove(opt.id);
                    }
                  });
                },
                title: Text(
                  opt.label,
                  style: const TextStyle(color: Colors.white),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // -------------------------
  // TOGGLE
  // -------------------------
  Widget _toggleAddon(FoodAddon addon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        child: SwitchListTile(
          title: Text(
            addon.title,
            style: const TextStyle(color: Colors.white),
          ),
          value: _values[addon.id],
          onChanged: (v) => setState(() => _values[addon.id] = v),
        ),
      ),
    );
  }
}
