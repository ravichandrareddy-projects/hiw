//lib/screens/scanner_screen.dart
import 'dart:convert';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ScannerScreen extends StatefulWidget {
  final void Function({
    required ImageProvider image,
    required String label,
    required double healthyScore,
  }) onFoodAnalyzed;

  const ScannerScreen({super.key, required this.onFoodAnalyzed});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  CameraController? _controller;
  bool _ready = false;
  bool _loading = false;
  XFile? _image;

  /// 🔥 Hugging Face API
/// 🔥 Hugging Face API (UPDATED SPACE)
static const String apiUrl =
    'https://valtoy-hiw-food-api.hf.space/predict';


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

  /// -----------------------------
  /// 🧠 SEND IMAGE TO ML API
  /// -----------------------------
  Future<void> _analyzeAndSend() async {
    if (_image == null) return;

    setState(() => _loading = true);

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(apiUrl),
      );

      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          _image!.path,
        ),
      );

      final response = await request.send();
      final body = await response.stream.bytesToString();
      final data = jsonDecode(body);

      final label = data['label'] as String;
      final confidence = (data['confidence'] as num).toDouble();

      /// 🔁 SEND ONLY DATA TO FOOD SCREEN
      widget.onFoodAnalyzed(
        image: FileImage(File(_image!.path)),
        label: label,
        healthyScore: confidence,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Detected: $label')),
      );

      setState(() {
        _image = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to analyze image')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _ready
          ? _cameraBody()
          : const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _cameraBody() {
    return Stack(
      children: [
        /// CAMERA / PREVIEW
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

        /// LOADING
        if (_loading)
          const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),

        /// BOTTOM BUTTON
        Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          child: Center(
            child: GestureDetector(
              onTap: _loading
                  ? null
                  : _image == null
                      ? _capture
                      : _analyzeAndSend,
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
