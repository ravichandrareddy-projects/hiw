//lib/screens/scanner_screen.dart
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:io';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../widgets/glass_card.dart';
import '../widgets/hiw_loading_overlay.dart';
import '../widgets/non_food_modal.dart';
import '../services/food_recognition_service.dart';

class ScannerScreen extends StatefulWidget {
  final void Function({
    required ImageProvider image,
    required String label,
    required double healthyScore,
  }) onFoodAnalyzed;
  final bool isActive; // 🔑 Only initialize camera if active

  const ScannerScreen({
    super.key,
    required this.onFoodAnalyzed,
    required this.isActive,
  });

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  CameraController? _controller;
  bool _ready = false;
  XFile? _image;
  bool _isAnalyzing = false;
  String _loadingStatus = 'Analyzing with HIW T AI...';

  // Pulse animation for the scan ring
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    if (widget.isActive) {
      _initCamera();
    }
  }

  @override
  void didUpdateWidget(covariant ScannerScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _initCamera();
    } else if (!widget.isActive && oldWidget.isActive) {
      _controller?.dispose();
      _controller = null;
      setState(() => _ready = false);
    }
  }

  Future<void> _initCamera() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Camera permission is required! 📸'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    try {
      final cams = await availableCameras();
      if (cams.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No camera found on device')),
        );
        return;
      }
      _controller = CameraController(
        cams.first,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await _controller!.initialize();
      if (!mounted) return;
      setState(() => _ready = true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Camera error: $e')),
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pulseController.dispose();
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final ctrl = _controller;
    if (ctrl == null || !ctrl.value.isInitialized) return;

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      ctrl.dispose();
      _controller = null;
      if (mounted) setState(() => _ready = false);
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  /// Take picture and perform background food analysis
  Future<void> _captureAndAnalyze() async {
    if (_controller == null || !_controller!.value.isInitialized || _isAnalyzing) return;

    try {
      final img = await _controller!.takePicture();
      if (!mounted) return;

      setState(() {
        _image = img;
        _isAnalyzing = true;
        _loadingStatus = 'Scanning image...';
      });

      // Stage 1: brief scanning pause
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) setState(() => _loadingStatus = 'Running HIW Vision AI...');

      // Stage 2: send to Google Cloud Vision API in background
      final result = await FoodRecognitionService.analyzeImage(File(img.path));
      if (!mounted) return;

      if (mounted) setState(() => _loadingStatus = 'Matching food database...');
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;

      setState(() => _isAnalyzing = false);

      if (result.isNotFood) {
        // ❌ NOT A FOOD → Glassmorphic non-food popup
        _showNonFoodDialog(result.itemName);
      } else if (result.isFood && result.isInDataset) {
        // ✅ FOOD FOUND IN DATASET → clear camera image & show food screen
        final imgFile = _image;
        setState(() => _image = null);
        widget.onFoodAnalyzed(
          image: FileImage(File(imgFile!.path)),
          label: result.itemName,
          healthyScore: result.healthyScore,
        );
      } else {
        // 🔄 FOOD DETECTED BUT NOT IN OUR DATASET YET
        _showComingSoonDialog(result.itemName);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAnalyzing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Camera analysis failed: $e')),
        );
      }
    }
  }

  void _showNonFoodDialog(String itemName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => NonFoodModal(
        detectedItemName: itemName,
        onScanAgain: () {
          if (mounted) setState(() => _image = null);
        },
      ),
    );
  }

  void _showComingSoonDialog(String itemName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: 24.w),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20.r),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              padding: EdgeInsets.all(28.w),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.all(14.w),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF00E676).withOpacity(0.15),
                      border: Border.all(color: const Color(0xFF00E676), width: 1.5),
                    ),
                    child: Icon(Icons.hourglass_top_rounded, color: const Color(0xFF00E676), size: 40.r),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'Food Recognized! 🌿',
                    style: TextStyle(color: Colors.white, fontSize: 20.sp, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    itemName,
                    style: TextStyle(color: const Color(0xFF00E676), fontSize: 16.sp, fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    'Sorry! This item is not yet in our food database.\nComing soon! 🚀',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: const Color(0xFFCBD5E1), fontSize: 14.sp, height: 1.5),
                  ),
                  SizedBox(height: 24.h),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00E676),
                        foregroundColor: Colors.black,
                        padding: EdgeInsets.symmetric(vertical: 13.h),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                      ),
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        if (mounted) setState(() => _image = null);
                      },
                      icon: const Icon(Icons.camera_alt_rounded),
                      label: Text('Scan Again', style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready || _controller == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Color(0xFF00E676)),
              SizedBox(height: 16.h),
              Text(
                'Starting HIW Camera...',
                style: TextStyle(color: Colors.white70, fontSize: 14.sp),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── CAMERA PREVIEW OR CAPTURED IMAGE ──
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

          // ── CLEAR / RETAKE PHOTO (X BUTTON) ──
          if (_image != null && !_isAnalyzing)
            Positioned(
              top: 40.h,
              right: 20.w,
              child: GestureDetector(
                onTap: () {
                  setState(() => _image = null);
                },
                child: Container(
                  padding: EdgeInsets.all(12.r),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.75),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.w),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 10.r,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 28.sp,
                  ),
                ),
              ),
            ),

          // ── BOTTOM SHUTTER BUTTON ──
          if (!_isAnalyzing && _image == null)
            Positioned(
              bottom: 48.h,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: _captureAndAnalyze,
                  child: Container(
                    width: 80.w,
                    height: 80.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00E676), Color(0xFF00B0FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(color: Colors.white, width: 3.5.w),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00E676).withOpacity(0.5),
                          blurRadius: 24.r,
                          spreadRadius: 4.r,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.camera_alt_rounded,
                      size: 36.sp,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),

          // ── HIW CUSTOM LOADING OVERLAY ──
          if (_isAnalyzing)
            Positioned.fill(
              child: HIWLoadingOverlay(
                statusText: _loadingStatus,
              ),
            ),
        ],
      ),
    );
  }

}
