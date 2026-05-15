import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class EmotionScore {
  final String label;
  final double confidence;

  EmotionScore(this.label, this.confidence);
}

class EmotionModelService {
  Interpreter? _interpreter;

  static const List<String> labels = [
    'angry',
    'disgust',
    'fear',
    'happy',
    'neutral',
    'sad',
    'surprise',
  ];

  Future<void> loadModel() async {
    final options = InterpreterOptions()..threads = 2;

    final data = await rootBundle.load('assets/models/RSX_V2_mobile_safe.tflite');
    final bytes = data.buffer.asUint8List();

    _interpreter = Interpreter.fromBuffer(bytes, options: options);
  }

  bool get isLoaded => _interpreter != null;

  img.Image preprocessPreview(img.Image image) {
    final gray = img.grayscale(image);
    final resized = img.copyResize(gray, width: 48, height: 48);

    img.adjustColor(resized, contrast: 1.1); // optional
    return resized;
  }

  List<List<List<List<double>>>> _preprocess(img.Image image) {
    final processed = preprocessPreview(image);

    return [
      List.generate(48, (y) {
        return List.generate(48, (x) {
          final pixel = processed.getPixel(x, y);
          final value = pixel.r / 255.0;
          return [value];
        });
      })
    ];
  }

  List<EmotionScore> predictFromImage(img.Image image) {
    if (_interpreter == null) {
      throw Exception('Model not loaded');
    }

    final input = _preprocess(image);
    final output = List.generate(1, (_) => List.filled(labels.length, 0.0));

    _interpreter!.run(input, output);

    final probs = output[0];
    final results = <EmotionScore>[];

    for (int i = 0; i < labels.length; i++) {
      results.add(EmotionScore(labels[i], probs[i]));
    }

    results.sort((a, b) => b.confidence.compareTo(a.confidence));
    return results;
  }

  List<EmotionScore> predictFromBytes(Uint8List bytes) {
    if (_interpreter == null) {
      throw Exception('Model not loaded');
    }

    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw Exception('Could not decode image');
    }

    return predictFromImage(decoded);
  }

  void close() {
    _interpreter?.close();
    _interpreter = null;
  }
}