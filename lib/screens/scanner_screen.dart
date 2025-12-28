import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

// 🧠 CORE LOGIC
import '../core/food_item.dart';
import '../core/nutrition_store.dart';
import '../core/history_store.dart';
import '../core/health_engine.dart';

class ScannerScreen extends StatefulWidget {
  final void Function({
    required ImageProvider image,
    required int calories,
    required double healthyScore,
  }) onFoodAnalyzed;

  const ScannerScreen({super.key, required this.onFoodAnalyzed});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  CameraController? _controller;
  bool _ready = false;
  XFile? _image;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final cams = await availableCameras();
    _controller = CameraController(
      cams.first,
      ResolutionPreset.high,
      enableAudio: false,
    );
    await _controller!.initialize();
    if (!mounted) return;
    setState(() => _ready = true);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _capture() async {
    final img = await _controller!.takePicture();
    setState(() => _image = img);
  }

  void _analyzeAndSend() {
    // -----------------------------
    // 🧠 CREATE FOOD ITEM (DEMO)
    // -----------------------------
    final food = FoodItem(
      name: "Dosa", // later from ML
      mealType: MealType.breakfast, // later dynamic
      calories: 320,
      protein: 12,
      carbs: 45,
      fats: 10,
    );

    // -----------------------------
    // 🧠 PUSH INTO CORE STORES
    // -----------------------------
    NutritionStore().addFood(food);
    HistoryStore().addFood(food);
    HealthEngine().applyFood(food);

    // -----------------------------
    // 🔁 EXISTING FLOW (UNCHANGED)
    // -----------------------------
    widget.onFoodAnalyzed(
      image: FileImage(File(_image!.path)),
      calories: food.calories,
      healthyScore: 0.25,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Food analyzed')),
    );

    setState(() => _image = null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body:
          _ready ? _cameraBody() : const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _cameraBody() {
    return Stack(
      children: [
        /// 🔥 FULL SCREEN CAMERA (NO LEFT SHIFT)
        if (_image == null)
          SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _controller!.value.previewSize!.height,
                height: _controller!.value.previewSize!.width,
                child: CameraPreview(_controller!),
              ),
            ),
          )
        else
          SizedBox.expand(
            child: Image.file(
              File(_image!.path),
              fit: BoxFit.cover,
            ),
          ),

        /// TOP TITLE
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'HIW Scanner',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),

        /// BOTTOM BUTTON
        Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          child: Center(
            child: GestureDetector(
              onTap: _image == null ? _capture : _analyzeAndSend,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  color: Colors.black.withOpacity(0.3),
                ),
                child: Icon(
                  _image == null ? Icons.camera_alt : Icons.check,
                  size: 36,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
