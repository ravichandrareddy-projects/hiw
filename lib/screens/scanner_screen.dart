//lib/screens/scanner_screen.dart
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:io';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import '../widgets/glass_card.dart';

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
  bool _launching = false;

  // Pulse animation for the scan ring
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // 🔑 lifecycle observer
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

  /// Pause camera when app goes to background, resume when returning
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

  /// CAPTURE → immediately send to Google Lens
  Future<void> _captureAndLaunchLens() async {
    if (_controller == null || !_controller!.value.isInitialized || _launching) return;
    setState(() => _launching = true);

    try {
      final img = await _controller!.takePicture();
      setState(() => _image = img);

      await _openGoogleLensWithImage(img.path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Capture failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _launching = false);
    }
  }

  /// Open Google Lens natively with the captured image
  Future<void> _openGoogleLensWithImage(String imagePath) async {
    const platform = MethodChannel('com.valtooy.hiw/lens');

    try {
      // Try native Android intent: share image to Google Lens directly
      await platform.invokeMethod('openWithGoogleLens', {'path': imagePath});
    } on MissingPluginException {
      // Fallback: use Android share intent via platform channel not available,
      // use url_launcher share workaround
      await _fallbackShareToLens(imagePath);
    } on PlatformException catch (e) {
      debugPrint('Lens intent failed: $e');
      await _fallbackShareToLens(imagePath);
    }
  }

  Future<void> _fallbackShareToLens(String imagePath) async {
    // Show instructions overlay if Lens intent isn't available
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          margin: EdgeInsets.all(16.r),
          padding: EdgeInsets.all(24.r),
          decoration: BoxDecoration(
            color: const Color(0xFF14141E).withOpacity(0.95),
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(color: Colors.white.withOpacity(0.15)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.image_search_rounded, color: Colors.cyanAccent, size: 48.sp),
              SizedBox(height: 16.h),
              Text(
                'Image Captured!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10.h),
              Text(
                'Your photo is saved. Open Google Lens and select this image to identify the food.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white60, fontSize: 13.sp, height: 1.5),
              ),
              SizedBox(height: 20.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.search_rounded),
                  label: Text('Retake Photo', style: TextStyle(fontSize: 14.sp)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyanAccent.withOpacity(0.15),
                    foregroundColor: Colors.cyanAccent,
                    side: const BorderSide(color: Colors.cyanAccent),
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() => _image = null);
                  },
                ),
              ),
            ],
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
              const CircularProgressIndicator(color: Colors.cyanAccent),
              SizedBox(height: 16.h),
              Text(
                'Starting Camera...',
                style: TextStyle(color: Colors.white70, fontSize: 14.sp),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: _cameraBody(),
    );
  }

  Widget _cameraBody() {
    return Stack(
      children: [
        // ── CAMERA PREVIEW ──
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

        // ── DARK VIGNETTE OVERLAY ──
        Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 0.75,
              colors: [
                Colors.transparent,
                Colors.black.withOpacity(0.55),
              ],
            ),
          ),
        ),

        // ── SCAN FRAME (pulsing ring in center) ──
        if (_image == null)
          Center(
            child: AnimatedBuilder(
              animation: _pulseAnim,
              builder: (_, __) => Transform.scale(
                scale: _pulseAnim.value,
                child: Container(
                  width: 240.w,
                  height: 240.w,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24.r),
                    border: Border.all(
                      color: Colors.cyanAccent.withOpacity(0.75),
                      width: 2.5.w,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Corner accents
                      ..._cornerAccents(),
                    ],
                  ),
                ),
              ),
            ),
          ),

        // ── TOP HEADER ──
        SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            child: Row(
              children: [
                // Back / retake button
                if (_image != null)
                  GestureDetector(
                    onTap: () => setState(() => _image = null),
                    child: Container(
                      padding: EdgeInsets.all(10.r),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white30),
                      ),
                      child: Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20.sp),
                    ),
                  ),
                const Spacer(),
                // Title badge
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.55),
                    borderRadius: BorderRadius.circular(22.r),
                    border: Border.all(color: Colors.cyanAccent.withOpacity(0.4), width: 1.w),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.center_focus_strong_rounded, color: Colors.cyanAccent, size: 16.sp),
                      SizedBox(width: 7.w),
                      Text(
                        'Point & Shoot → Google Lens',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),

        // ── HINT TEXT ──
        if (_image == null)
          Positioned(
            bottom: 170.h,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Icon(Icons.lens_blur_rounded, color: Colors.white38, size: 22.sp),
                SizedBox(height: 6.h),
                Text(
                  'Aim at food & tap the button',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 13.sp,
                    letterSpacing: 0.3,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Google Lens will instantly identify it ⚡',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.cyanAccent.withOpacity(0.7),
                    fontSize: 11.sp,
                  ),
                ),
              ],
            ),
          ),

        // ── BOTTOM CAPTURE BUTTON ──
        Positioned(
          bottom: 48.h,
          left: 0,
          right: 0,
          child: Center(
            child: _image == null
                ? GestureDetector(
                    onTap: _launching ? null : _captureAndLaunchLens,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 80.w,
                      height: 80.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00E5FF), Color(0xFF3A86FF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border.all(color: Colors.white, width: 3.5.w),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.cyanAccent.withOpacity(_launching ? 0.2 : 0.5),
                            blurRadius: 24.r,
                            spreadRadius: 4.r,
                          ),
                        ],
                      ),
                      child: _launching
                          ? const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            )
                          : Icon(
                              Icons.camera_alt_rounded,
                              size: 36.sp,
                              color: Colors.white,
                            ),
                    ),
                  )
                // After capture — show "Open in Lens" button
                : GestureDetector(
                    onTap: () => _openGoogleLensWithImage(_image!.path),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 16.h),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00E5FF), Color(0xFF3A86FF)],
                        ),
                        borderRadius: BorderRadius.circular(30.r),
                        border: Border.all(color: Colors.white, width: 2.w),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.cyanAccent.withOpacity(0.4),
                            blurRadius: 16.r,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.image_search_rounded, color: Colors.white, size: 22.sp),
                          SizedBox(width: 10.w),
                          Text(
                            'Open in Google Lens',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  /// Corner accent decorations for the scan frame
  List<Widget> _cornerAccents() {
    const c = Colors.cyanAccent;
    const size = 24.0;
    const thick = 3.0;
    return [
      // TL
      Positioned(top: 0, left: 0, child: _corner(c, size, thick, top: true, left: true)),
      // TR
      Positioned(top: 0, right: 0, child: _corner(c, size, thick, top: true, left: false)),
      // BL
      Positioned(bottom: 0, left: 0, child: _corner(c, size, thick, top: false, left: true)),
      // BR
      Positioned(bottom: 0, right: 0, child: _corner(c, size, thick, top: false, left: false)),
    ];
  }

  Widget _corner(Color color, double size, double thick,
      {required bool top, required bool left}) {
    return CustomPaint(
      size: Size(size, size),
      painter: _CornerPainter(color: color, thick: thick, top: top, left: left),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final Color color;
  final double thick;
  final bool top;
  final bool left;

  _CornerPainter({required this.color, required this.thick, required this.top, required this.left});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thick
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final x = left ? 0.0 : size.width;
    final y = top ? 0.0 : size.height;
    final dx = left ? size.width : -size.width;
    final dy = top ? size.height : -size.height;

    canvas.drawLine(Offset(x, y), Offset(x + dx, y), paint);
    canvas.drawLine(Offset(x, y), Offset(x, y + dy), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
