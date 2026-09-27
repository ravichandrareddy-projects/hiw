import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../core/theme_manager.dart';

class DevThemeTools extends StatefulWidget {
  const DevThemeTools({super.key});

  @override
  State<DevThemeTools> createState() => _DevThemeToolsState();
}

class _DevThemeToolsState extends State<DevThemeTools> {
  final ThemeManager _themeManager = ThemeManager();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color:
            const Color(0xFF1E293B), // Dark slate background for tool feeling
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10.r)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "🎨 Theme Customizer",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.orangeAccent),
                tooltip: "Reset to Default",
                onPressed: () {
                  _themeManager.reset();
                  setState(() {});
                },
              )
            ],
          ),
          SizedBox(height: 20.h),

          // ---------------------------
          // COLOR PICKERS
          // ---------------------------
          ListenableBuilder(
            listenable: _themeManager,
            builder: (context, _) {
              return Column(
                children: [
                  _buildColorRow(
                      context,
                      "Background Color",
                      _themeManager.backgroundColorOverride ??
                          Colors.transparent,
                      (c) => _themeManager.setBackgroundColor(c)),
                  const Divider(color: Colors.white10),
                  _buildColorRow(
                      context,
                      "Glass Card Color",
                      _themeManager.cardColorOverride ??
                          Colors.white.withValues(alpha: 0.1),
                      (c) => _themeManager.setCardColor(c)),
                  const Divider(color: Colors.white10),
                  _buildColorRow(
                      context,
                      "Primary / Nav Color",
                      _themeManager.primaryColorOverride ?? Colors.blueAccent,
                      (c) => _themeManager.setPrimaryColor(c)),
                ],
              );
            },
          ),

          SizedBox(height: 20.h),

          // ---------------------------
          // OPACITY SLIDER
          // ---------------------------
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Glass Opacity",
                  style: TextStyle(color: Colors.white70)),
              ListenableBuilder(
                listenable: _themeManager,
                builder: (context, _) => Text(
                  "${(_themeManager.opacityOverride * 100).toInt()}%",
                  style: const TextStyle(
                      color: Colors.blueAccent, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          ListenableBuilder(
            listenable: _themeManager,
            builder: (context, _) {
              return Slider(
                value: _themeManager.opacityOverride,
                min: 0.0,
                max: 1.0,
                activeColor: Colors.blueAccent,
                thumbColor: Colors.white,
                onChanged: (val) => _themeManager.setOpacity(val),
              );
            },
          ),
          SizedBox(height: 30.h),
        ],
      ),
    );
  }

  Widget _buildColorRow(BuildContext context, String title, Color currentColor,
      Function(Color) onColorChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      color: Colors.white70, fontWeight: FontWeight.w600)),
              SizedBox(height: 4.h),
              // Hex Code Display
              Text(
                '#${_colorToHex(currentColor)}',
                style: TextStyle(
                    color: Colors.white38,
                    fontSize: 12.sp,
                    fontFamily: 'monospace'),
              ),
            ],
          ),
          GestureDetector(
            onTap: () =>
                _showColorPickerDialog(context, currentColor, onColorChanged),
            child: Container(
              width: 50.w,
              height: 30.h,
              decoration: BoxDecoration(
                color: currentColor,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: Colors.white30, width: 1.5.w),
                boxShadow: [
                  BoxShadow(
                      color: currentColor.withValues(alpha: 0.4),
                      blurRadius: 8.r,
                      spreadRadius: 1.r),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showColorPickerDialog(
      BuildContext context, Color startColor, Function(Color) onColorChanged) {
    Color pickerColor = startColor;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title:
              const Text('Pick a Color', style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: pickerColor,
              onColorChanged: (c) {
                pickerColor = c;
                // Live update (Optional: can move this to onActions if simpler, but live is request)
                onColorChanged(c);
              },
              // ⚙️ CONFIGURATION TO MATCH "LIKE THIS" (Chrome/Figma Style)
              colorPickerWidth: 300,
              pickerAreaHeightPercent: 0.7,
              enableAlpha: true, // Alpha slider included
              displayThumbColor: true,
              paletteType: PaletteType.hsvWithHue,
              labelTypes: const [], // Hide default labels to keep it clean, uses built-in hex input if enabled below
              hexInputBar: true, // Shows Hex input like the image
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Done',
                  style: TextStyle(color: Colors.blueAccent)),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  String _colorToHex(Color c) {
    return c
        .toARGB32()
        .toRadixString(16)
        .padLeft(8, '0')
        .toUpperCase()
        .substring(2);
  }
}

void showDevThemeTools(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true, // Allow taller sheet
    backgroundColor: Colors.transparent,
    builder: (context) => const DevThemeTools(),
  );
}
