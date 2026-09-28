//lib/screens/scanner_screen.dart
// HIW Food Scanner — Camera + Text modes, shared FoodResult pipeline.
// Glassmorphism via HiwTheme tokens only (cards/text/borders match theme).
import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image/image.dart' as img;
import 'package:permission_handler/permission_handler.dart';

import '../core/food_item.dart';
import '../core/food_nutrition_database.dart';
import '../core/food_result.dart';
import '../core/food_search_service.dart';
import '../services/food_recognition_service.dart';
import '../themes/hiw_theme.dart';
import '../widgets/detection_result_modal.dart';
import '../widgets/rainbow_scan_overlay.dart';
import 'food_result_screen.dart';
import 'food_text_search_screen.dart';

/// Capture metrics in ONE isolate pass (dimensions + blur score).
/// Keeps shutter-to-preview instant — no full-res decode on the UI thread.
Map<String, double> _captureMetrics(Uint8List bytes) {
  try {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      return {'w': 0, 'h': 0, 'blur': double.infinity};
    }
    final small = img.copyResize(decoded, width: 320);
    final gray = img.grayscale(small);
    final w = gray.width, h = gray.height;
    double sum = 0, sumSq = 0;
    int n = 0;
    double lum(int x, int y) =>
        gray.getPixel(x, y).r.toDouble();
    for (var y = 1; y < h - 1; y++) {
      for (var x = 1; x < w - 1; x++) {
        final lap = 4 * lum(x, y) -
            lum(x - 1, y) -
            lum(x + 1, y) -
            lum(x, y - 1) -
            lum(x, y + 1);
        sum += lap;
        sumSq += lap * lap;
        n++;
      }
    }
    double variance;
    if (n == 0) {
      variance = double.infinity;
    } else {
      final mean = sum / n;
      variance = sumSq / n - mean * mean;
    }
    return {
      'w': decoded.width.toDouble(),
      'h': decoded.height.toDouble(),
      'blur': variance,
    };
  } catch (_) {
    return {'w': 0, 'h': 0, 'blur': double.infinity};
  }
}

/// Conservative severe-blur threshold (tuned to avoid flagging moderate blur).
const double kSevereBlurThreshold = 20.0;

class ScannerScreen extends StatefulWidget {
  final void Function({
    required ImageProvider image,
    required String label,
    required double healthyScore,
    required double quantity,
    FoodNutritionRecord? nutritionRecord,
    required List<ScannedItem> items,
  }) onFoodAnalyzed;
  final bool isActive;

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
  bool _initializing = false;
  int _autoRetry = 0;
  XFile? _image;
  Offset? _focusPoint;
  // Exact tap pixel (relative to the preview area) for the indicator,
  // so the box appears precisely where the finger landed.
  Offset? _focusTapPx;
  Timer? _focusHideTimer;
  bool _isAnalyzing = false;
  String _loadingStatus = 'Analyzing food...';
  int _statusStep = 0;
  Timer? _statusTimer;

  // Top mode: Scan | Text. Bottom kind: Food | Barcode (both kept).
  bool _isTextMode = false;
  bool _isBarcode = false;

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
      if (mounted) setState(() => _ready = false);
    }
  }

  Future<void> _initCamera() async {
    if (_initializing || _controller != null) return;
    _initializing = true;
    try {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        if (!mounted) return;
        final permanentlyDenied = status.isPermanentlyDenied;
        final t = HiwTheme.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(permanentlyDenied
                ? 'Camera blocked. Tap ALLOW to open settings.'
                : 'Camera permission is required!'),
            backgroundColor: t.accentColor,
            duration: const Duration(seconds: 5),
            action: permanentlyDenied
                ? const SnackBarAction(
                    label: 'ALLOW',
                    textColor: Colors.white,
                    onPressed: openAppSettings,
                  )
                : null,
          ),
        );
        return;
      }

      final cams = await availableCameras();
      if (cams.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No camera found on device')),
        );
        return;
      }
      final backCams = cams
          .where((c) => c.lensDirection == CameraLensDirection.back)
          .toList();
      final selected = backCams.isNotEmpty ? backCams.first : cams.first;

      final controller = CameraController(
        selected,
        ResolutionPreset.max,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      try {
        await controller.initialize().timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            throw TimeoutException('camera init timed out');
          },
        );
      } catch (_) {
        try {
          await controller.dispose().timeout(const Duration(seconds: 5));
        } catch (_) {}
        rethrow;
      }
      try {
        await controller.setFlashMode(FlashMode.auto);
      } catch (_) {}
      try {
        await controller.setFocusMode(FocusMode.auto);
      } catch (_) {}
      if (!mounted) {
        await controller.dispose();
        return;
      }
      _controller = controller;
      final ps = controller.value.previewSize;
      debugPrint(
          'HIW PREVIEW: ${ps?.width}x${ps?.height} (max preset, back lens, jpeg)');
      _autoRetry = 0;
      setState(() => _ready = true);
    } catch (e) {
      if (!mounted) return;
      final t = HiwTheme.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Camera error. Tap RETRY below.'),
          backgroundColor: t.accentColor,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'RETRY',
            textColor: Colors.white,
            onPressed: _retryCamera,
          ),
        ),
      );
    } finally {
      _initializing = false;
    }
  }

  Future<void> _retryCamera() async {
    if (_initializing) return;
    try {
      await _controller?.dispose();
    } catch (_) {}
    _controller = null;
    if (mounted) setState(() => _ready = false);
    await _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _focusHideTimer?.cancel();
    _statusTimer?.cancel();
    _pulseController.dispose();
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final ctrl = _controller;
    if (state == AppLifecycleState.inactive) {
      // Notification shade / control panel: only pause the preview frame.
      // Controller stays alive so resume is instant — no reload screen.
      ctrl?.pausePreview().ignore();
      return;
    }
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _statusTimer?.cancel();
      ctrl?.dispose().ignore();
      _controller = null;
      if (mounted) setState(() => _ready = false);
      return;
    }
    if (state == AppLifecycleState.resumed) {
      // Silent auto-recovery: re-init only if disposed, else resume feed.
      // User never taps anything.
      if (_controller == null) {
        _initCamera();
      } else {
        _controller?.resumePreview().ignore();
        if (mounted && !_ready) setState(() => _ready = true);
      }
      return;
    }
    if (state == AppLifecycleState.detached) {
      ctrl?.dispose().ignore();
      _controller = null;
    }
  }

  Future<void> _setFocusPoint(Offset point) async {
    final ctrl = _controller;
    if (ctrl == null || !ctrl.value.isInitialized) return;
    try {
      await ctrl.setFocusPoint(point);
    } catch (_) {}
    try {
      await ctrl.setExposurePoint(point);
    } catch (_) {}
    if (!mounted) return;
    _focusHideTimer?.cancel();
    setState(() => _focusPoint = point);
    // Indicator hides automatically shortly after the tap.
    _focusHideTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _focusPoint = null;
          _focusTapPx = null;
        });
      }
    });
  }

  void _cycleStatus() {
    const steps = [
      'Analyzing food...',
      'Identifying...',
      'Matching nutrition...',
      'Preparing your meal...',
    ];
    _statusTimer?.cancel();
    _statusStep = 0;
    setState(() => _loadingStatus = steps[0]);
    _statusTimer =
        Timer.periodic(const Duration(milliseconds: 1800), (t) {
      if (!mounted || !_isAnalyzing) {
        t.cancel();
        return;
      }
      _statusStep = (_statusStep + 1) % steps.length;
      setState(() => _loadingStatus = steps[_statusStep]);
    });
  }

  MealType _mealHint() => mealTypeFromTime(DateTime.now());

  Future<void> _captureAndAnalyze() async {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _controller!.value.isTakingPicture ||
        _isAnalyzing) {
      return;
    }
    if (_isBarcode) {
      final t = HiwTheme.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
              'Barcode mode kept — Food scan runs in Food tab.'),
          backgroundColor: t.accentColor,
        ),
      );
      return;
    }

    try {
      // Fast shutter: continuous AF/AE (auto) is already tracking, so when
      // the user hasn't tapped to focus, shoot immediately with no
      // focus-point dance and no settle delay. Only when a tap point
      // exists do we nudge focus there with a brief settle.
      if (_focusPoint != null) {
        try {
          await _controller!.setFocusPoint(_focusPoint!);
        } catch (_) {}
        try {
          await _controller!.setExposurePoint(_focusPoint!);
        } catch (_) {}
        await Future.delayed(const Duration(milliseconds: 200));
      }

      final shot = await _controller!.takePicture();
      if (!mounted) return;

      // SHOW CAPTURED PHOTO IMMEDIATELY — nothing (blur check, resize,
      // API, ML) runs before this. Photo visible in well under 1 second.
      setState(() => _image = shot);

      // AFTER the photo is visible: diagnostics + blur score in ONE
      // isolate pass on the ORIGINAL (never resized/overwritten).
      Uint8List? rawBytes;
      try {
        rawBytes = await File(shot.path).readAsBytes();
      } catch (_) {}

      // Severe-blur advisory only, over the already-visible photo.
      // Moderate blur NEVER blocks the user.
      if (rawBytes != null && mounted) {
        final m = await compute(_captureMetrics, rawBytes);
        final variance = m['blur'] ?? double.infinity;
        debugPrint(
            'HIW CAPTURE: ${m['w']?.round()}x${m['h']?.round()} (${rawBytes.length ~/ 1024}KB, jpeg, max preset, blur=$variance)');
        if (variance < kSevereBlurThreshold && mounted) {
          final useAnyway = await _askBlurry();
          if (!mounted) return;
          if (!useAnyway) {
            _controller?.resumePreview().ignore();
            setState(() => _image = null);
            return;
          }
        }
      }
      if (!mounted) return;

      // Async food-recognition pipeline starts only now (photo visible).
      await _analyzeShot(File(shot.path));
    } catch (e) {
      _statusTimer?.cancel();
      debugPrint('HIW ANALYZE FAILED: $e');
      if (mounted) {
        setState(() => _isAnalyzing = false);
        final t = HiwTheme.of(context);
        final msg = e.toString().replaceFirst('Exception: ', '');
        // Photo is kept — RETRY re-runs offline recognition on same shot.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not recognize — photo kept. Tap RETRY. $msg'),
            backgroundColor: t.accentColor,
            duration: const Duration(seconds: 8),
            action: _image == null
                ? null
                : SnackBarAction(
                    label: 'RETRY',
                    textColor: Colors.white,
                    onPressed: () {
                      final p = _image?.path;
                      if (p != null) _analyzeShot(File(p));
                    },
                  ),
          ),
        );
      }
    }
  }

  /// Recognition + result flow for an already-captured photo.
  /// Photo stays visible the whole time; safe to RETRY on network errors.
  Future<void> _analyzeShot(File shotFile) async {
    if (!mounted || _isAnalyzing) return;
    setState(() => _isAnalyzing = true);
    _cycleStatus();

    final stopwatch = Stopwatch()..start();
    RecognitionResult result;
    try {
      // Gemini vision sees the photo and names the foods; every calorie
      // then comes from OUR local database.
      result = await FoodRecognitionService.analyzeImage(
        shotFile,
      ).timeout(
          kMaxScanDuration + const Duration(seconds: 90));
    } finally {
      // Anti-flicker only (500ms); result shows the moment AI returns.
      final elapsed = stopwatch.elapsed;
      if (elapsed < kMinScanDuration) {
        await Future.delayed(kMinScanDuration - elapsed);
      }
    }
    if (!mounted) return;
    setState(() => _isAnalyzing = false);
    _statusTimer?.cancel();

    final imgProvider = FileImage(shotFile);
    final normalized = FoodRecognitionResult.fromRecognition(
      result,
      image: imgProvider,
      imagePath: shotFile.path,
      mealType: _mealHint(),
      alternatives: _buildAlternatives(result),
    );

    if (normalized.status == FoodMatchStatus.notFood) {
      _showUnclearSheet(shotFile, result.itemName);
      return;
    }
    if (normalized.status == FoodMatchStatus.noMatch) {
      _showResultDialog(result, shotFile);
      return;
    }

    // Matched or low-confidence → shared result screen.
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => FoodResultScreen(
          initial: normalized,
          onReplaceImage: () {
            Navigator.of(context).pop(false);
            _controller?.resumePreview().ignore();
            if (mounted) setState(() => _image = null);
          },
        ),
      ),
    );
    if (!mounted) return;
    _controller?.resumePreview().ignore();
    setState(() => _image = null);
    if (saved == true) {
      // Saved via shared pipeline (Nutrition/History/Health).
      // Keep legacy callback for existing Food tab listeners
      // without double-saving: forward as activity ping only
      // when the food exists in dataset.
      if (result.isFood && result.isInDataset) {
        widget.onFoodAnalyzed(
          image: imgProvider,
          label: '__already_saved__',
          healthyScore: result.healthyScore,
          quantity: 0,
          nutritionRecord: null,
          items: const [],
        );
      }
    }
  }

  List<FoodCandidate> _buildAlternatives(RecognitionResult r) {
    // Candidate choices for low-confidence: DB fuzzy hits around itemName.
    try {
      final hits = FoodSearchService().search(r.itemName, limit: 4);
      return hits
          .map((h) => FoodCandidate(
                displayName: h.record.name,
                confidence: (h.score / 100).clamp(0.0, 1.0),
                record: h.record,
              ))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  /// Advisory gate for severely blurred captures.
  /// Returns true => Use Anyway (continue pipeline), false => Retake.
  Future<bool> _askBlurry() async {
    final t = HiwTheme.of(context);
    final res = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ClipRRect(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        child: BackdropFilter(
          filter: ImageFilter.blur(
              sigmaX: t.blurSigma, sigmaY: t.blurSigma),
          child: Container(
            padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 28.h),
            decoration: BoxDecoration(
              color: t.cardBackground,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(24.r)),
              border: Border.all(color: t.cardStroke),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: t.mutedColor.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
                SizedBox(height: 14.h),
                Text(
                  'Photo looks blurry',
                  style: TextStyle(
                    color: t.inkColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16.sp,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  'Hold steady and try again for sharper food details.',
                  style: TextStyle(
                      color: t.mutedColor, fontSize: 13.sp),
                ),
                SizedBox(height: 16.h),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: t.inkColor,
                          side: BorderSide(color: t.cardStroke),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(14.r)),
                          padding:
                              EdgeInsets.symmetric(vertical: 14.h),
                        ),
                        onPressed: () =>
                            Navigator.pop(ctx, false),
                        child: const Text('Retake Photo'),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: t.accentColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(14.r)),
                          padding:
                              EdgeInsets.symmetric(vertical: 14.h),
                        ),
                        onPressed: () =>
                            Navigator.pop(ctx, true),
                        child: const Text('Use Anyway'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    return res ?? false;
  }

  void _showUnclearSheet(File? imgFile, String detected) {
    final t = HiwTheme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ClipRRect(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        child: BackdropFilter(
          filter: ImageFilter.blur(
              sigmaX: t.blurSigma, sigmaY: t.blurSigma),
          child: Container(
            padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 28.h),
            decoration: BoxDecoration(
              color: t.cardBackground,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(24.r)),
              border: Border.all(color: t.cardStroke),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: t.mutedColor.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
                SizedBox(height: 14.h),
                Text(
                  'Food is difficult to recognize.',
                  style: TextStyle(
                    color: t.inkColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16.sp,
                  ),
                ),
                if (detected.isNotEmpty) ...[
                  SizedBox(height: 6.h),
                  Text('Saw: $detected',
                      style: TextStyle(
                          color: t.mutedColor, fontSize: 13.sp)),
                ],
                SizedBox(height: 16.h),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: t.inkColor,
                          side: BorderSide(color: t.cardStroke),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(14.r)),
                          padding:
                              EdgeInsets.symmetric(vertical: 14.h),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _controller?.resumePreview().ignore();
                          if (mounted) {
                            setState(() => _image = null);
                          }
                        },
                        child: const Text('Retake Photo'),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: t.accentColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(14.r)),
                          padding:
                              EdgeInsets.symmetric(vertical: 14.h),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  const FoodTextSearchScreen(),
                            ),
                          );
                        },
                        child: const Text('Search Food Instead'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showResultDialog(RecognitionResult result, File? imgFile) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => DetectionResultModal(
        imageFile: imgFile,
        itemName: result.itemName,
        isFood: result.isFood,
        isInDatabase: result.isInDataset,
        quantity: result.estimatedQuantity,
        servingUnit: result.servingUnit,
        items: result.items,
        onScanAgain: () {
          _controller?.resumePreview().ignore();
          if (mounted) setState(() => _image = null);
        },
        caloriesPreview: result.nutritionRecord
            ?.toFoodItem(
                    quantityMultiplier: result.estimatedQuantity)
                .calories,
        onViewDetails: (result.isFood && result.isInDataset)
            ? () {
                if (!mounted) return;
                setState(() => _image = null);
                widget.onFoodAnalyzed(
                  image: FileImage(imgFile!),
                  label: result.itemName,
                  healthyScore: result.healthyScore,
                  quantity: result.estimatedQuantity,
                  nutritionRecord: result.nutritionRecord,
                  items: result.items,
                );
              }
            : null,
      ),
    );
  }

  void _openTextMode() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            FoodTextSearchScreen(initialMeal: _mealHint()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = HiwTheme.of(context);

    if (!_ready || _controller == null) {
      // No reload screen: camera heals itself silently up to 3 times.
      // User never taps anything.
      if (widget.isActive &&
          _controller == null &&
          !_initializing &&
          _autoRetry < 3) {
        _autoRetry++;
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) _retryCamera();
        });
      }
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: t.accentColor),
              SizedBox(height: 16.h),
              Text(
                'Starting HIW Camera...',
                style: TextStyle(
                    color: Colors.white70, fontSize: 14.sp),
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
          if (_image == null)
            Positioned.fill(
              child: LayoutBuilder(
                builder: (ctx, constraints) {
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapDown: (d) {
                      final x = (d.localPosition.dx /
                              constraints.maxWidth)
                          .clamp(0.0, 1.0);
                      final y = (d.localPosition.dy /
                              constraints.maxHeight)
                          .clamp(0.0, 1.0);
                      // Record the exact tap pixel for the indicator.
                      if (mounted) {
                        setState(
                            () => _focusTapPx = d.localPosition);
                      }
                      _setFocusPoint(Offset(x, y));
                    },
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Builder(
                          builder: (_) {
                            // Null-safe: fall back to direct preview
                            // (keeps aspect, never stretches) if the
                            // plugin hasn't reported a size yet.
                            final ps =
                                _controller!.value.previewSize;
                            if (ps == null) {
                              return CameraPreview(
                                  _controller!);
                            }
                            return FittedBox(
                              fit: BoxFit.cover,
                              child: SizedBox(
                                width: ps.height,
                                height: ps.width,
                                child: CameraPreview(
                                    _controller!),
                              ),
                            );
                          },
                        ),
                        // Focus box pinned to the exact tap pixel;
                        // only visible briefly after a tap.
                        if (_focusTapPx != null)
                          Positioned(
                            left: (_focusTapPx!.dx - 40.w)
                                .clamp(0.0, double.infinity),
                            top: (_focusTapPx!.dy - 40.h)
                                .clamp(0.0, double.infinity),
                            child: Container(
                              width: 80.w,
                              height: 80.h,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: const Color(0xFFFF9800),
                                  width: 2.5.w,
                                ),
                                borderRadius:
                                    BorderRadius.circular(8.r),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            )
          else if (!_isAnalyzing)
            // Captured photo at rest (sharp, full-bleed). While
            // analyzing, the overlay shows it as a square card instead.
            SizedBox.expand(
              child: Image.file(
                File(_image!.path),
                fit: BoxFit.cover,
              ),
            ),

  // ── TOP BAR: back + Scan/Text + flash (reference style) ──
          Positioned(
            top: 52.h,
            left: 16.w,
            right: 16.w,
            child: Row(
              children: [
                _camCircleBtn(Icons.arrow_back_rounded, () {
                  _controller?.resumePreview().ignore();
                  if (_image != null && mounted) {
                    setState(() => _image = null);
                  }
                }),
                const Spacer(),
                ClipRRect(
                  borderRadius: BorderRadius.circular(24.r),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                        sigmaX: 14, sigmaY: 14),
                    child: Container(
                      padding: EdgeInsets.all(4.r),
                      decoration: BoxDecoration(
                        color: Colors.black
                            .withValues(alpha: 0.45),
                        borderRadius:
                            BorderRadius.circular(24.r),
                        border: Border.all(
                          color: Colors.white
                              .withValues(alpha: 0.22),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _segPill('Scan', !_isTextMode, t,
                              () {
                            setState(
                                () => _isTextMode = false);
                          }),
                          _segPill('Text', _isTextMode, t, () {
                            setState(
                                () => _isTextMode = true);
                            _openTextMode();
                            Future.delayed(
                                const Duration(
                                    milliseconds: 400),
                                () {
                              if (mounted) {
                                setState(() =>
                                    _isTextMode = false);
                              }
                            });
                          }),
                        ],
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                _camCircleBtn(Icons.flash_auto_rounded, () {}),
              ],
            ),
          ),

          // ── VIEWFINDER CORNERS (reference: bold white brackets) ──
          if (_image == null && !_isAnalyzing)
            Positioned.fill(
              child: IgnorePointer(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                      30.w, 150.h, 30.w, 250.h),
                  child: const CustomPaint(
                    painter: _CornerPainter(
                        color: Colors.white),
                  ),
                ),
              ),
            ),

          // ── CLEAR / RETAKE (glass) ──
          if (_image != null && !_isAnalyzing)
            Positioned(
              top: 110.h,
              right: 20.w,
              child: GestureDetector(
                onTap: () {
                  _controller?.resumePreview().ignore();
                  setState(() => _image = null);
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20.r),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                        sigmaX: 12, sigmaY: 12),
                    child: Container(
                      padding: EdgeInsets.all(12.r),
                      decoration: BoxDecoration(
                        color: Colors.black
                            .withValues(alpha: 0.4),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white
                                .withValues(alpha: 0.4),
                            width: 1.5),
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: 24.sp,
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // ── ANALYZING STATE: square photo over rainbow smoke ──
          if (_isAnalyzing && _image != null)
            Positioned.fill(
              child: RainbowScanOverlay(
                statusText: _loadingStatus,
                image: FileImage(File(_image!.path)),
              ),
            ),

          // ── BOTTOM CONTROLS — grouped stack anchored above the
          // bottom nav via SafeArea (no hardcoded screen coordinates):
          // shutter row, then Food|Barcode directly below it.
          if (!_isAnalyzing && _image == null)
            Positioned(
              left: 20.w,
              right: 20.w,
              bottom: 0,
              child: SafeArea(
                top: false,
                minimum: EdgeInsets.only(bottom: 82.h),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceEvenly,
                    children: [
                      _camCircleBtn(
                        Icons.photo_library_outlined,
                        () {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(
                            SnackBar(
                              content: const Text(
                                  'Gallery pick uses the same scan flow — capture for now.'),
                              backgroundColor:
                                  t.accentColor,
                            ),
                          );
                        },
                        pad: 14,
                      ),
                      // Shutter — reference style: bold white button
                      GestureDetector(
                        onTap: _captureAndAnalyze,
                        child: AnimatedBuilder(
                          animation: _pulseAnim,
                          builder: (ctx, child) =>
                              Transform.scale(
                            scale: _pulseAnim.value,
                            child: child,
                          ),
                          child: Container(
                            width: 80.w,
                            height: 80.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              border: Border.all(
                                  color: Colors.white
                                      .withValues(alpha: 0.55),
                                  width: 4.w),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black
                                      .withValues(alpha: 0.45),
                                  blurRadius: 20.r,
                                  spreadRadius: 1.r,
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.camera_alt_rounded,
                              size: 34.sp,
                              color: const Color(0xFF2A211A),
                            ),
                          ),
                        ),
                      ),
                      _camCircleBtn(
                        Icons.cameraswitch_outlined,
                        () {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(
                            SnackBar(
                              content: const Text(
                                  'Back camera is used for sharp food shots.'),
                              backgroundColor:
                                  t.accentColor,
                            ),
                          );
                        },
                        pad: 14,
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  // Food | Barcode toggle — reference style, both kept.
                  // Selected = peach pill, unselected = soft white text.
                  ClipRRect(
                    borderRadius:
                        BorderRadius.circular(24.r),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(
                          sigmaX: 14, sigmaY: 14),
                      child: Container(
                        padding: EdgeInsets.all(4.r),
                        decoration: BoxDecoration(
                          color: Colors.black
                              .withValues(alpha: 0.45),
                          borderRadius:
                              BorderRadius.circular(24.r),
                          border: Border.all(
                              color: Colors.white
                                  .withValues(alpha: 0.22)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _modePill('🍽  Food', !_isBarcode,
                                () {
                              setState(
                                  () => _isBarcode = false);
                            }),
                            _modePill('Barcode', _isBarcode,
                                () {
                              setState(
                                  () => _isBarcode = true);
                            }),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (_isBarcode) ...[
                    SizedBox(height: 8.h),
                    Text(
                      'Barcode mode kept — reliable packaged lookup.',
                      style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11.sp),
                    ),
                  ],
                ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Dark glass circle button for camera chrome (reference style).
  Widget _camCircleBtn(IconData icon, VoidCallback onTap,
      {double pad = 10}) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: EdgeInsets.all(pad.r),
            decoration: BoxDecoration(
              color:
                  Colors.black.withValues(alpha: 0.45),
              shape: BoxShape.circle,
              border: Border.all(
                  color:
                      Colors.white.withValues(alpha: 0.28)),
            ),
            child: Icon(icon,
                color: Colors.white, size: 20.sp),
          ),
        ),
      ),
    );
  }

  /// Peach selected pill for the Food | Barcode toggle (reference style).
  Widget _modePill(
      String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: 20.w, vertical: 9.h),
        decoration: BoxDecoration(
          color: selected ? _peach : Colors.transparent,
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Text(
          label,
          style: TextStyle(
            color:
                selected ? _creamInk : Colors.white70,
            fontWeight: selected
                ? FontWeight.bold
                : FontWeight.w500,
            fontSize: 13.sp,
          ),
        ),
      ),
    );
  }

  /// Reference-style segment: cream selected pill + dark text,
  /// unselected transparent + soft white text. Camera chrome sits over
  /// the live preview (always dark), so neutral cream/white is used.
  static const _cream = Color(0xFFF5EDE0);
  static const _creamInk = Color(0xFF2A211A);
  static const _peach = Color(0xFFE8A06C);

  Widget _segPill(
      String label, bool selected, HiwTheme t, VoidCallback onTap) {
    final bg = selected ? _cream : Colors.transparent;
    final fg = selected ? _creamInk : Colors.white70;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: 18.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(18.r),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: fg,
            fontWeight:
                selected ? FontWeight.bold : FontWeight.w500,
            fontSize: 13.sp,
          ),
        ),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final Color color;
  const _CornerPainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 4.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    const l = 48.0;
    // TL
    canvas.drawPath(
        Path()
          ..moveTo(0, l)
          ..lineTo(0, 0)
          ..lineTo(l, 0),
        p);
    // TR
    canvas.drawPath(
        Path()
          ..moveTo(size.width - l, 0)
          ..lineTo(size.width, 0)
          ..lineTo(size.width, l),
        p);
    // BL
    canvas.drawPath(
        Path()
          ..moveTo(0, size.height - l)
          ..lineTo(0, size.height)
          ..lineTo(l, size.height),
        p);
    // BR
    canvas.drawPath(
        Path()
          ..moveTo(size.width - l, size.height)
          ..lineTo(size.width, size.height)
          ..lineTo(size.width, size.height - l),
        p);
  }

  @override
  bool shouldRepaint(_CornerPainter old) => old.color != color;
}
