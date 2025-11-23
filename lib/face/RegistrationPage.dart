import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:image/image.dart' as imglib;
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../models/face_embedding.dart';
import '../services/face_embedder.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RegistrationPage extends StatefulWidget {
  final String? initialEmail;
  const RegistrationPage({super.key, this.initialEmail});
  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final _emailCtrl = TextEditingController();
  CameraController? _cameraController;
  bool _busy = false;
  bool _reinitializing = false;
  bool _useBackCamera = true;
  int _cameraGen = 0;
  late final FaceDetector _faceDetector;
  final _embedder = FaceEmbedder();
  bool get _emailLocked =>
      widget.initialEmail != null && widget.initialEmail!.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(performanceMode: FaceDetectorMode.accurate),
    );
    if (_emailLocked) {
      _emailCtrl.text = widget.initialEmail!.toLowerCase();
    }
    _initCamera();
  }

  Future<void> _initCamera() async {
    await _createControllerForCurrentPref();
    if (mounted) setState(() {});
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
      await controller.dispose();
      return;
    }
    _cameraController = controller;
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _emailCtrl.dispose();
    _faceDetector.close();
    super.dispose();
  }

  Future<void> _swapCamera() async {
    if (_reinitializing) return;
    setState(() => _reinitializing = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      _useBackCamera = !(_useBackCamera);
      await prefs.setBool('useBackCamera', _useBackCamera);
      final old = _cameraController;
      _cameraController = null;
      await old?.dispose();
      await _createControllerForCurrentPref();
    } catch (_) {
    } finally {
      if (mounted) setState(() => _reinitializing = false);
    }
  }

  Future<imglib.Image?> _detectAndCropFace(XFile file) async {
    final bytes = await file.readAsBytes();
    final input = InputImage.fromFilePath(file.path);
    final faces = await _faceDetector.processImage(input);
    if (faces.isEmpty) return null;
    final img = imglib.decodeImage(bytes);
    if (img == null) return null;
    final face = faces.first;
    final rect = face.boundingBox;
    final x = rect.left.clamp(0, img.width.toDouble()).toInt();
    final y = rect.top.clamp(0, img.height.toDouble()).toInt();
    final w = rect.width.clamp(1, (img.width - x).toDouble()).toInt();
    final h = rect.height.clamp(1, (img.height - y).toDouble()).toInt();
    return imglib.copyCrop(img, x: x, y: y, width: w, height: h);
  }

  Future<void> _onCapture() async {
    final controller = _cameraController;
    if (_busy || controller == null || !controller.value.isInitialized) return;
    final email = (_emailLocked ? widget.initialEmail! : _emailCtrl.text)
        .trim()
        .toLowerCase();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Enter a valid email'),
          duration: const Duration(seconds: 1),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      await _embedder.loadModel(context: context);
      final shots = <List<double>>[];
      for (int i = 0; i < 3; i++) {
        final file = await controller.takePicture();
        final cropped = await _detectAndCropFace(file);
        if (cropped == null) continue;
        final emb = await _embedder.embedImage(cropped);
        shots.add(emb);
        await Future.delayed(const Duration(milliseconds: 150));
      }
      if (shots.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('No face detected.'),
            duration: const Duration(seconds: 1),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
        return;
      }
      // Average embeddings
      final avg = List<double>.filled(shots.first.length, 0);
      for (final v in shots) {
        for (int i = 0; i < v.length; i++) {
          avg[i] += v[i];
        }
      }
      for (int i = 0; i < avg.length; i++) avg[i] /= shots.length;

      // Get user data from users collection (email as doc id)
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(email)
          .get();

      String? userName;
      if (userDoc.exists) {
        final userData = userDoc.data();
        userName = userData?['name'] as String?;
      }

      // Update or create user document with email as doc id and store embedding
      await FirebaseFirestore.instance
          .collection('users')
          .doc(email)
          .set({
            'name': userName ?? email,
            'embedding': avg,
            'face_updated_at': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      // Save to Hive for offline access
      final box = await Hive.openBox<FaceEmbedding>('face_embeddings_box');
      final key = userName != null && userName.isNotEmpty ? userName : email;
      await box.put(key, FaceEmbedding(email: email, embedding: avg));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Registered successfully'),
          duration: const Duration(seconds: 1),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      Navigator.pop(context);
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          duration: const Duration(seconds: 1),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Register Face',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 2),
            Text(
              widget.initialEmail ?? '',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Swap Camera',
            onPressed: _swapCamera,
            icon: const Icon(Icons.cameraswitch),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (_cameraController == null ||
                    !_cameraController!.value.isInitialized)
                  const Center(child: CircularProgressIndicator())
                else
                  CameraPreview(_cameraController!),
                // Green guide grid overlay
                if (_cameraController != null &&
                    _cameraController!.value.isInitialized)
                  IgnorePointer(
                    child: CustomPaint(
                      painter: _GuideOverlayPainter(),
                      child: Container(),
                    ),
                  ),
                if (_reinitializing)
                  Container(
                    color: Colors.black26,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
          ),
          SafeArea(
            child: Container(
              color: Theme.of(context).appBarTheme.backgroundColor,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _busy ? null : _onCapture,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  backgroundColor: Colors.green,
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  shadowColor: Theme.of(context).focusColor,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _busy ? 'Processing...' : 'Capture & Register',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (!_busy)
                      const Icon(
                        Icons.person_add_alt,
                        color: Colors.white,
                        size: 20,
                      ),
                    if (_busy)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.green.withOpacity(0.8)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Draw a 3x3 grid
    final dx = size.width / 3;
    final dy = size.height / 3;
    for (int i = 1; i < 3; i++) {
      canvas.drawLine(Offset(dx * i, 0), Offset(dx * i, size.height), paint);
      canvas.drawLine(Offset(0, dy * i), Offset(size.width, dy * i), paint);
    }

    // Draw a centered square guide (face box)
    final boxSize = size.shortestSide * 0.6;
    final left = (size.width - boxSize) / 2;
    final top = (size.height - boxSize) / 2;
    final rect = Rect.fromLTWH(left, top, boxSize, boxSize);
    canvas.drawRect(rect, paint);

    // Corner accents
    final corner = 18.0;
    // top-left
    canvas.drawLine(rect.topLeft, rect.topLeft + Offset(corner, 0), paint);
    canvas.drawLine(rect.topLeft, rect.topLeft + Offset(0, corner), paint);
    // top-right
    canvas.drawLine(rect.topRight, rect.topRight + Offset(-corner, 0), paint);
    canvas.drawLine(rect.topRight, rect.topRight + Offset(0, corner), paint);
    // bottom-left
    canvas.drawLine(
      rect.bottomLeft,
      rect.bottomLeft + Offset(corner, 0),
      paint,
    );
    canvas.drawLine(
      rect.bottomLeft,
      rect.bottomLeft + Offset(0, -corner),
      paint,
    );
    // bottom-right
    canvas.drawLine(
      rect.bottomRight,
      rect.bottomRight + Offset(-corner, 0),
      paint,
    );
    canvas.drawLine(
      rect.bottomRight,
      rect.bottomRight + Offset(0, -corner),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
