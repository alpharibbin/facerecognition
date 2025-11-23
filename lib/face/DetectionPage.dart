import 'dart:async';
import 'dart:ui';
import 'package:camera/camera.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:image/image.dart' as imglib;
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../services/face_embedder.dart';
import '../services/detection_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DetectionPage extends StatefulWidget {
  const DetectionPage({super.key});
  @override
  State<DetectionPage> createState() => _DetectionPageState();
}

class _DetectionPageState extends State<DetectionPage> {
  CameraController? _cameraController;
  bool _busy = false;
  bool _reinitializing = false;
  bool _useBackCamera = true; // default back cam
  late final FaceDetector _faceDetector;
  final _embedder = FaceEmbedder();
  final _detectionService = DetectionService();
  String _result = '';
  Timer? _loop;
  final List<_Detection> _detections = [];
  int _cameraGen = 0;

  @override
  void initState() {
    super.initState();
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(performanceMode: FaceDetectorMode.accurate),
    );
    _init();
  }

  Future<void> _init() async {
    setState(() => _reinitializing = true);
    await _detectionService.init();
    await _createControllerForCurrentPref();
    setState(() => _reinitializing = false);
    _startAutoDetect();
  }

  Future<void> _createControllerForCurrentPref() async {
    final prefs = await SharedPreferences.getInstance();
    _useBackCamera = prefs.getBool('useBackCamera') ?? true;
    final cams = await availableCameras();
    final desired = _useBackCamera
        ? CameraLensDirection.back
        : CameraLensDirection.front;
    final cam = cams.firstWhere(
      (c) => c.lensDirection == desired,
      orElse: () => cams.first,
    );
    final gen = ++_cameraGen;
    final controller = CameraController(
      cam,
      ResolutionPreset.medium,
      enableAudio: false,
    );
    await controller.initialize();
    if (!mounted || gen != _cameraGen) {
      // stale init; dispose and exit
      await controller.dispose();
      return;
    }
    _cameraController = controller;
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _faceDetector.close();
    _loop?.cancel();
    super.dispose();
  }

  Future<void> _swapCamera() async {
    if (_reinitializing) return;
    setState(() => _reinitializing = true);
    try {
      _loop?.cancel();
      _loop = null;
      _busy = false;
      final prefs = await SharedPreferences.getInstance();
      _useBackCamera = !(_useBackCamera);
      await prefs.setBool('useBackCamera', _useBackCamera);
      final old = _cameraController;
      _cameraController = null;
      await old?.dispose();
      await _createControllerForCurrentPref();
      _startAutoDetect();
    } catch (_) {
    } finally {
      if (mounted) setState(() => _reinitializing = false);
    }
  }

  Future<void> _onDetect() async {
    if (_busy || _reinitializing) return;
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;
    setState(() => _busy = true);
    try {
      await _embedder.loadModel(context: context);
      final file = await controller.takePicture();
      final bytes = await file.readAsBytes();
      final input = InputImage.fromFilePath(file.path);
      final faces = await _faceDetector.processImage(input);
      if (faces.isEmpty) {
        setState(() => _result = 'No face detected');
        return;
      }
      final img = imglib.decodeImage(bytes);
      if (img == null) {
        setState(() => _result = 'Decode error');
        return;
      }

      _detections.clear();
      for (final face in faces) {
        final rect = face.boundingBox;
        final safeLeft = rect.left.isFinite ? rect.left : 0.0;
        final safeTop = rect.top.isFinite ? rect.top : 0.0;
        final x = safeLeft
            .clamp(0.0, math.max(0, img.width - 1).toDouble())
            .toInt();
        final y = safeTop
            .clamp(0.0, math.max(0, img.height - 1).toDouble())
            .toInt();
        final remainingW = img.width - x;
        final remainingH = img.height - y;
        if (remainingW <= 1 || remainingH <= 1) {
          continue;
        }
        final w = math.min(
          rect.width.isFinite ? rect.width.ceil() : remainingW,
          remainingW,
        );
        final h = math.min(
          rect.height.isFinite ? rect.height.ceil() : remainingH,
          remainingH,
        );
        if (w <= 1 || h <= 1) continue;
        final crop = imglib.copyCrop(img, x: x, y: y, width: w, height: h);
        final emb = await _embedder.embedImage(crop);
        final match = _detectionService.findBestMatch(emb, threshold: 0.7);
        _detections.add(
          _Detection(
            imageWidth: img.width,
            imageHeight: img.height,
            bbox: rect,
            label: match?.key ?? 'Unknown',
            score: match?.value ?? 0.0,
          ),
        );
      }
      setState(() {
        if (_detections.isEmpty) {
          _result = 'No face detected';
        } else {
          _result = _detections
              .map((d) => '${d.label} (${d.score.toStringAsFixed(2)})')
              .join(', ');
        }
      });
    } catch (e) {
      setState(() => _result = 'Error: $e');
    } finally {
      setState(() => _busy = false);
    }
  }

  void _startAutoDetect({
    Duration interval = const Duration(milliseconds: 1500),
  }) {
    _loop?.cancel();
    _loop = Timer.periodic(interval, (_) => _onDetect());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detect Face'),
        actions: [
          IconButton(
            tooltip: 'Swap Camera',
            onPressed: _swapCamera,
            icon: const Icon(Icons.cameraswitch),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Full-screen Camera Preview
          if (_cameraController != null && _cameraController!.value.isInitialized)
            SizedBox.expand(
              child: CameraPreview(_cameraController!),
            )
          else
            const Center(child: CircularProgressIndicator(color: Colors.white)),

          // Detections overlay (bounding boxes, labels, etc.)
          SizedBox.expand(
            child: CustomPaint(
              painter: _DetectionsPainter(
                detections: _detections,
                previewWidth: MediaQuery.of(context).size.width,
                previewHeight: MediaQuery.of(context).size.height,
                isFrontCamera: !_useBackCamera,
              ),
            ),
          ),

          // Reinitializing overlay
          if (_reinitializing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),

          SafeArea(child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 10), // safe area friendly
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12), // glass blur
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.35), // semi-transparent black
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      _result.isEmpty ? 'Scanning...' : _result,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
          ),),
        ],
      ),
    );
  }
}

class _Detection {
  final Rect bbox;
  final int imageWidth;
  final int imageHeight;
  final String label;
  final double score;
  _Detection({
    required this.bbox,
    required this.imageWidth,
    required this.imageHeight,
    required this.label,
    required this.score,
  });
}

class _DetectionsPainter extends CustomPainter {
  final List<_Detection> detections;
  final double previewWidth;
  final double previewHeight;
  final bool isFrontCamera;
  _DetectionsPainter({
    required this.detections,
    required this.previewWidth,
    required this.previewHeight,
    this.isFrontCamera = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final boxPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (final d in detections) {
      final sx = previewWidth / d.imageWidth;
      final sy = previewHeight / d.imageHeight;
      // Mirror horizontally if using front camera
      final left = isFrontCamera
          ? (d.imageWidth - (d.bbox.left + d.bbox.width)) * sx
          : d.bbox.left * sx;
      final top = d.bbox.top * sy;
      final right = isFrontCamera
          ? (d.imageWidth - d.bbox.left) * sx
          : (d.bbox.left + d.bbox.width) * sx;
      final bottom = (d.bbox.top + d.bbox.height) * sy;
      final rect = Rect.fromLTRB(left, top, right, bottom);

      final color = d.score >= 0.9
          ? Colors.green
          : d.score >= 0.8
          ? Colors.orange
          : d.score >= 0.7
          ? Colors.red
          : Colors.grey;
      boxPaint.color = color;
      canvas.drawRect(rect, boxPaint);

      final tp = TextPainter(
        text: TextSpan(
          text:
              '${d.label} ${d.score > 0 ? (d.score * 100).toStringAsFixed(0) + '%' : ''}',
          style: TextStyle(
            color: Colors.white,
            backgroundColor: color.withOpacity(0.6),
            fontSize: 12,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: previewWidth);
      tp.paint(canvas, Offset(rect.left, rect.top - tp.height - 2));
    }
  }

  @override
  bool shouldRepaint(covariant _DetectionsPainter oldDelegate) {
    return oldDelegate.detections != detections ||
        oldDelegate.previewWidth != previewWidth ||
        oldDelegate.previewHeight != previewHeight;
  }
}
