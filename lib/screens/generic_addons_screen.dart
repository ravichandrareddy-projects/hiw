import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';
import '../core/food_addons_config.dart';
import '../widgets/glass_card.dart';
import '../widgets/glass_button.dart';
import '../themes/hiw_theme.dart';

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
    final ink = HiwTheme.of(context).inkColor;
    return Scaffold(
      appBar: AppBar(
        title: Text('Customize ${widget.foodLabel.toUpperCase()}'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.r),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children:
                    widget.addons.map((a) => _buildAddon(a, ink)).toList(),
              ),
            ),
            SizedBox(height: 12.h),
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
  Widget _buildAddon(FoodAddon addon, Color ink) {
    switch (addon.type) {
      case AddonType.counter:
        return _counterAddon(addon, ink);
      case AddonType.singleChoice:
        return _singleChoiceAddon(addon, ink);
      case AddonType.multiChoice:
        return _multiChoiceAddon(addon, ink);
      case AddonType.toggle:
        return _toggleAddon(addon, ink);
    }
  }

  // -------------------------
  // COUNTER
  // -------------------------
  Widget _counterAddon(FoodAddon addon, Color ink) {
    int value = _values[addon.id];

    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              addon.title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: ink,
              ),
            ),
            SizedBox(height: 8.h),
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
                  style: TextStyle(
                    fontSize: 18.sp,
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
  Widget _singleChoiceAddon(FoodAddon addon, Color ink) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              addon.title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: ink,
              ),
            ),
            SizedBox(height: 8.h),
            ...addon.options.map((opt) {
              return RadioListTile<String>(
                value: opt.id,
                groupValue: _values[addon.id],
                onChanged: (v) => setState(() => _values[addon.id] = v),
                title: Text(
                  opt.label,
                  style: TextStyle(color: ink),
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
  Widget _multiChoiceAddon(FoodAddon addon, Color ink) {
    final Set<String> selected = _values[addon.id];

    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              addon.title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: ink,
              ),
            ),
            SizedBox(height: 8.h),
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
                  style: TextStyle(color: ink),
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
  Widget _toggleAddon(FoodAddon addon, Color ink) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: GlassCard(
        child: SwitchListTile(
          title: Text(
            addon.title,
            style: TextStyle(color: ink),
          ),
          value: _values[addon.id],
          onChanged: (v) => setState(() => _values[addon.id] = v),
        ),
      ),
    );
  }
}
