import 'dart:io';
import 'dart:typed_data';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';


/// Result object returned after face detection.
/// Contains either the cropped face image or an error message.
class FaceDetectionResult {
  final img.Image? image;
  final String? error;

  FaceDetectionResult({this.image, this.error});
}


/// Handles face detection, validation, cropping, and brightness checking
/// before the image is sent to the TensorFlow Lite emotion model.
class FaceDetectionService {
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: false,      // Disabled to save processing power (not needed for cropping)
      enableLandmarks: true,     // Enabled, verify if the whole face is in the Frame
      enableClassification: false, // Disabled (don't need MLKit to detect smiles/eyes open)
      performanceMode: FaceDetectorMode.fast, // Prioritize speed over extreme accuracy
      minFaceSize: 0.15,           // Ignore faces that take up less than 15% of the image
    ),
  );


  /// Handles face detection, validation, cropping, and brightness checking, before the image is sent to the TFLite emotion model.
  Future<FaceDetectionResult> detectAndCropLargestFace(Uint8List imageBytes) async {
    final tempDir = await getTemporaryDirectory();
    final tempPath = p.join(
      tempDir.path,
      'face2mood_temp_${DateTime
          .now()
          .millisecondsSinceEpoch}.jpg',
    );

    final tempFile = File(tempPath);
    await tempFile.writeAsBytes(imageBytes, flush: true);

    final inputImage = InputImage.fromFilePath(tempPath);

    final faces = await _faceDetector.processImage(inputImage);

    if (faces.isEmpty) {
      try {
        await tempFile.delete();
      } catch (_) {}
      return FaceDetectionResult(error: "No face detected. Please try again.");
    }

    if (faces.length > 1) {
      try {
        await tempFile.delete();
      } catch (_) {}
      return FaceDetectionResult(error: "Multiple faces detected. Please ensure only one person is in the frame.");
    }

    final decoded = img.decodeImage(imageBytes);
    if (decoded == null) {
      try {
        await tempFile.delete();
      } catch (_) {}
      return FaceDetectionResult(error: "Failed to process image.");
    }

    final face = faces.first;
    final box = face.boundingBox;

    // Landmarks are used to reject faces that are partially outside the frame.
    final leftEye = face.landmarks[FaceLandmarkType.leftEye];
    final rightEye = face.landmarks[FaceLandmarkType.rightEye];
    final leftEar = face.landmarks[FaceLandmarkType.leftEar];
    final rightEar = face.landmarks[FaceLandmarkType.rightEar];
    final bottomMouth = face.landmarks[FaceLandmarkType.bottomMouth];


    // Logic: If any of these are null, the face is definitely cut off.
    if (leftEye == null || rightEye == null || leftEar == null || rightEar == null || bottomMouth == null) {
      await _cleanup(tempFile);
      debugPrint("Rejecting: Face extremities are out of frame.");
      return FaceDetectionResult(error: "Face extremities out of frame. Show your whole face.");
    }


    // Reject faces that are too close to image borders to avoid incomplete crops.
    const double edgeThreshold = 15.0;

    bool isTooCloseToEdge =
        box.left < edgeThreshold ||
            box.top < edgeThreshold ||
            box.right > (decoded.width - edgeThreshold) ||
            box.bottom > (decoded.height - edgeThreshold);

    if (isTooCloseToEdge) {
      await _cleanup(tempFile);
      return FaceDetectionResult(error: "Face too close to edge. Please center your face.");
    }


    // Add padding to include also useful FER context such as forehead and chin.
    final leftPadding = box.width * 0.12;
    final rightPadding = box.width * 0.12;
    final topPadding = box.height * 0.18;
    final bottomPadding = box.height * 0.10;

    final paddedLeft = box.left - leftPadding;
    final paddedTop = box.top - topPadding;
    final paddedRight = box.right + rightPadding;
    final paddedBottom = box.bottom + bottomPadding;


    final paddedWidth = paddedRight - paddedLeft;
    final paddedHeight = paddedBottom - paddedTop;


    // Force a square crop because the FER model expects a consistent face region.
    final squareSize = max(paddedWidth, paddedHeight);

    final centerX = (paddedLeft + paddedRight) / 2;
    final centerY = (paddedTop + paddedBottom) / 2;

    int x = (centerX - squareSize / 2).round();
    int y = (centerY - squareSize / 2).round();
    int size = squareSize.round();

    // Clamp crop coordinates to remain inside the original image boundaries.
    if (x < 0) x = 0;
    if (y < 0) y = 0;

    if (x + size > decoded.width) {
      size = decoded.width - x;
    }
    if (y + size > decoded.height) {
      size = decoded.height - y;
    }

    final finalSize = size.clamp(
      1,
      decoded.width - x < decoded.height - y
          ? decoded.width - x
          : decoded.height - y,
    );

    final cropped = img.copyCrop(
      decoded,
      x: x,
      y: y,
      width: finalSize,
      height: finalSize,
    );


    // Reject very dark images because low illumination reduces FER reliability.
    final brightness = _calculateMeanIntensity(cropped);
    debugPrint('DEBUG: Mean Pixel Intensity: $brightness');
    if (brightness < 50) {
      await _cleanup(tempFile);
      return FaceDetectionResult(error: "It's too dark for an accurate prediction.");
    }

    try {
      await tempFile.delete();
    } catch (_) {}

    return FaceDetectionResult(image: cropped);
  }


  /// Calculates average image brightness using the standard luminance formula.
  double _calculateMeanIntensity(img.Image image) {
    double totalIntensity = 0;
    for (final pixel in image) {
      totalIntensity += (0.299 * pixel.r + 0.587 * pixel.g + 0.114 * pixel.b);
    }
    return totalIntensity / (image.width * image.height);
  }


  /// Deletes temporary image files used by ML Kit processing.
  Future<void> _cleanup(File file) async {
    try {
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }


  /// Releases the ML Kit face detector resources.
  void close() {
    _faceDetector.close();
  }
}
