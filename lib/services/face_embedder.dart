import 'dart:io';
import 'dart:math' as math;
import 'package:image/image.dart' as imglib;
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/material.dart';

class FaceEmbedder {
  static final FaceEmbedder _instance = FaceEmbedder._internal();
  factory FaceEmbedder() => _instance;
  FaceEmbedder._internal();

  tfl.Interpreter? _interpreter;
  late final List<int> _inputShape; // [1, H, W, 3]
  late final int _outputDim; // 512

  Future<bool> loadModel({
    required BuildContext context,
    String modelName = 'facenet.tflite',
  }) async {
    if (_interpreter != null) return true;

    try {
      // Load model from local assets
      final modelPath = await _getLocalModelPath(modelName);
      _interpreter = await tfl.Interpreter.fromFile(
        File(modelPath),
        options: tfl.InterpreterOptions()..threads = 2,
      );
      final inputT = _interpreter!.getInputTensor(0);
      _inputShape = inputT.shape;
      final outT = _interpreter!.getOutputTensor(0);
      _outputDim = outT.shape.last;
      return true;
    } catch (e) {
      debugPrint('Error loading FaceNet model: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load face recognition model: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
  }

  Future<String> _getLocalModelPath(String modelName) async {
    // Get application documents directory
    final appDir = await getApplicationDocumentsDirectory();
    final modelPath = path.join(appDir.path, modelName);

    // Check if model file already exists
    if (await File(modelPath).exists()) {
      return modelPath;
    }

    // Load from assets and save to local directory
    final assetPath = 'assets/models/$modelName';
    final byteData = await rootBundle.load(assetPath);
    final file = File(modelPath);
    await file.create(recursive: true);
    await file.writeAsBytes(byteData.buffer.asUint8List());

    return modelPath;
  }

  Future<List<double>> embedImage(
    imglib.Image faceRgb, {
    bool normalizeToMinusOneToOne = true,
  }) async {
    final h = _inputShape[1];
    final w = _inputShape[2];
    final resized = imglib.copyResize(
      faceRgb,
      width: w,
      height: h,
      interpolation: imglib.Interpolation.average,
    );

    final input = List.generate(
      1,
      (_) =>
          List.generate(h, (_) => List.generate(w, (_) => List.filled(3, 0.0))),
    );
    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        final px = resized.getPixel(x, y);
        double r = px.r.toDouble();
        double g = px.g.toDouble();
        double b = px.b.toDouble();
        if (normalizeToMinusOneToOne) {
          r = (r - 127.5) / 128.0;
          g = (g - 127.5) / 128.0;
          b = (b - 127.5) / 128.0;
        } else {
          r = r / 255.0;
          g = g / 255.0;
          b = b / 255.0;
        }
        input[0][y][x][0] = r;
        input[0][y][x][1] = g;
        input[0][y][x][2] = b;
      }
    }

    final output = List.generate(1, (_) => List.filled(_outputDim, 0.0));
    _interpreter!.run(input, output);
    return _l2Normalize(output[0]);
  }

  List<double> _l2Normalize(List<double> v) {
    double sum = 0;
    for (final x in v) sum += x * x;
    final norm = sum == 0 ? 1.0 : math.sqrt(sum);
    return v.map((x) => x / norm).toList(growable: false);
  }
}
