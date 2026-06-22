import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:flutter/foundation.dart';


/// Stores a predicted emotion label together with its confidence score.
class EmotionScore {
  final String label;
  final double confidence;

  EmotionScore(this.label, this.confidence);
}


/// Handles loading and running the TensorFlow Lite emotion recognition model.
class EmotionModelService {
  Interpreter? _interpreter;

  // Stores the latest TFLite-only inference time - performance evaluation.
  int? lastInferenceTimeMs;

  // Emotion labels - follow the same order as the model output layer.
  static const List<String> labels = [
    'angry',
    'disgust',
    'fear',
    'happy',
    'neutral',
    'sad',
    'surprise',
  ];


  /// Loads the optimized TensorFlow Lite model from the 'assets' folder.
  Future<void> loadModel() async {
    final options = InterpreterOptions()..threads = 2;

    final data = await rootBundle.load('assets/models/RSX_V2_mobile_safe.tflite');
    final bytes = data.buffer.asUint8List();

    _interpreter = Interpreter.fromBuffer(bytes, options: options);
  }

  bool get isLoaded => _interpreter != null;


  /// Converts the cropped face to the same format used during training: grayscale, 48x48 pixels, with a small contrast adjustment.
  img.Image preprocessPreview(img.Image image) {
    final gray = img.grayscale(image);
    final resized = img.copyResize(gray, width: 48, height: 48);

    img.adjustColor(resized, contrast: 1.1);  // contrast to help stabilize low-contrast face crops
    return resized;
  }

  /// Converts the preprocessed image into the 4D tensor expected by the model: [batch, height, width, channels].
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


  /// Runs emotion prediction on an already decoded image and returns the predicted emotions sorted by confidence.
  List<EmotionScore> predictFromImage(img.Image image) {
    if (_interpreter == null) {
      throw Exception('Model not loaded');
    }


    // Measure only the TFLite model execution time, excluding preprocessing.
    final input = _preprocess(image);
    final output = List.generate(1, (_) => List.filled(labels.length, 0.0));

    final inferenceStopwatch = Stopwatch()..start();

    _interpreter!.run(input, output);

    inferenceStopwatch.stop();
    lastInferenceTimeMs = inferenceStopwatch.elapsedMilliseconds;

    debugPrint('TFLite inference time: $lastInferenceTimeMs ms');

    final probs = output[0];
    final results = <EmotionScore>[];

    for (int i = 0; i < labels.length; i++) {
      results.add(EmotionScore(labels[i], probs[i]));
    }

    // Sort predictions so the most confident emotions appear first.
    results.sort((a, b) => b.confidence.compareTo(a.confidence));
    return results;
  }


  /// Decodes raw image bytes before running emotion prediction.
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


  /// Releases the TensorFlow Lite interpreter resources.
  void close() {
    _interpreter?.close();
    _interpreter = null;
  }
}