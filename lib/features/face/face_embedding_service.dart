import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class FaceEmbeddingException implements Exception {
  const FaceEmbeddingException(this.message);

  final String message;

  @override
  String toString() => message;
}

class FaceEmbeddingService {
  FaceEmbeddingService({
    this.modelAssetPath = 'assets/models/mobilefacenet.tflite',
    this.inputSize = 112,
    this.embeddingSize = 192,
  });

  final String modelAssetPath;
  final int inputSize;
  final int embeddingSize;

  Interpreter? _interpreter;

  Future<List<double>> generateEmbedding({
    required XFile frameFile,
    required Rect faceBounds,
  }) async {
    final bytes = await File(frameFile.path).readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) {
      throw const FaceEmbeddingException('Could not decode camera frame.');
    }

    final faceImage = _cropFace(image, faceBounds);
    if (faceImage == null) {
      throw const FaceEmbeddingException(
          'The detected face is outside the frame.');
    }

    final interpreter = await _loadInterpreter();
    final input = _imageToInput(faceImage);
    final output =
        List.generate(1, (_) => List<double>.filled(embeddingSize, 0));

    interpreter.run(input, output);
    return _l2Normalize(output.first);
  }

  Future<Interpreter> _loadInterpreter() async {
    final existing = _interpreter;
    if (existing != null) {
      return existing;
    }

    try {
      final interpreter = await Interpreter.fromAsset(modelAssetPath);
      _interpreter = interpreter;
      return interpreter;
    } catch (_) {
      throw FaceEmbeddingException(
        'Face recognition model missing. Add $modelAssetPath and run flutter pub get.',
      );
    }
  }

  img.Image? _cropFace(img.Image image, Rect bounds) {
    final paddingX = bounds.width * 0.18;
    final paddingY = bounds.height * 0.22;
    final left = max(0, (bounds.left - paddingX).floor());
    final top = max(0, (bounds.top - paddingY).floor());
    final right = min(image.width, (bounds.right + paddingX).ceil());
    final bottom = min(image.height, (bounds.bottom + paddingY).ceil());
    final width = right - left;
    final height = bottom - top;

    if (width <= 0 || height <= 0) {
      return null;
    }

    final cropped = img.copyCrop(
      image,
      x: left,
      y: top,
      width: width,
      height: height,
    );
    return img.copyResizeCropSquare(cropped, size: inputSize);
  }

  List<List<List<List<double>>>> _imageToInput(img.Image faceImage) {
    return [
      List.generate(inputSize, (y) {
        return List.generate(inputSize, (x) {
          final pixel = faceImage.getPixel(x, y);
          return [
            (pixel.r.toDouble() - 127.5) / 128.0,
            (pixel.g.toDouble() - 127.5) / 128.0,
            (pixel.b.toDouble() - 127.5) / 128.0,
          ];
        });
      }),
    ];
  }

  List<double> _l2Normalize(List<double> embedding) {
    final norm = sqrt(
      embedding.fold<double>(0, (sum, value) => sum + (value * value)),
    );
    if (norm == 0) {
      return embedding;
    }
    return embedding.map((value) => value / norm).toList();
  }

  void close() {
    _interpreter?.close();
    _interpreter = null;
  }
}
