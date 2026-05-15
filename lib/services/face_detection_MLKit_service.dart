import 'dart:io';
import 'dart:typed_data';
import 'dart:math';

// Importing Google's ML Kit Face Detection package
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
// Importing the 'image' package to handle pixel-level manipulation (cropping/decoding)
import 'package:image/image.dart' as img;
// Utilities for handling file system paths
import 'package:path/path.dart' as p;
// Utilities to find temporary directories on Android/iOS
import 'package:path_provider/path_provider.dart';


/// A simple class to return either the cropped image or an error message
class FaceDetectionResult {
  final img.Image? image;
  final String? error;

  FaceDetectionResult({this.image, this.error});
}


class FaceDetectionService {
  /// Initialize the Face Detector with specific configurations
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: false,      // Disabled to save processing power (not needed for cropping)
      enableLandmarks: true,     // Enabled, we need this to verify if the whole face is in the Frame
      enableClassification: false, // Disabled (we don't need MLKit to detect smiles/eyes open)
      performanceMode: FaceDetectorMode.fast, // Prioritize speed over extreme accuracy
      minFaceSize: 0.15,           // Ignore faces that take up less than 15% of the image
    ),
  );

  /// Main function to detect a face, calculate a square crop, and return the cropped image
  Future<FaceDetectionResult> detectAndCropLargestFace(Uint8List imageBytes) async {
    // 1. MLKit requires a File path or a UI Image; it cannot process raw bytes directly easily.
    // We get the system's temporary directory to save the image briefly.
    final tempDir = await getTemporaryDirectory();
    final tempPath = p.join(
      tempDir.path,
      'face2mood_temp_${DateTime
          .now()
          .millisecondsSinceEpoch}.jpg',
    );

    // 2. Write the incoming bytes (from the camera) to a physical file on the disk
    final tempFile = File(tempPath);
    await tempFile.writeAsBytes(imageBytes, flush: true);

    // 3. Convert the file into an 'InputImage' format that MLKit understands
    final inputImage = InputImage.fromFilePath(tempPath);

    // 4. Run the MLKit detection algorithm to find all faces in the image
    final faces = await _faceDetector.processImage(inputImage);

    // 5. If no faces are found, clean up the temporary file and exit
    if (faces.isEmpty) {
      try {
        await tempFile.delete();
      } catch (_) {}
      return FaceDetectionResult(error: "No face detected. Please try again.");
    }

    // NEW: Check for multiple faces to ensure single-user analysis
    if (faces.length > 1) {
      try {
        await tempFile.delete();
      } catch (_) {}
      return FaceDetectionResult(error: "Multiple faces detected. Please ensure only one person is in the frame.");
    }

    // 6. Decode the raw bytes into an 'img.Image' object so we can perform the crop later
    final decoded = img.decodeImage(imageBytes);
    if (decoded == null) {
      try {
        await tempFile.delete();
      } catch (_) {}
      return FaceDetectionResult(error: "Failed to process image.");
    }


    // 7. Pick the largest face detected
    final face = faces.first;
    final box = face.boundingBox;


    // 8. THE "WHOLE FACE" CHECK
    // ML Kit doesn't have a 'forehead' landmark, so we check the highest points (eyes/ears)
    // and the lowest point (bottom mouth) to ensure vertical coverage.
    final leftEye = face.landmarks[FaceLandmarkType.leftEye];
    final rightEye = face.landmarks[FaceLandmarkType.rightEye];
    final leftEar = face.landmarks[FaceLandmarkType.leftEar];
    final rightEar = face.landmarks[FaceLandmarkType.rightEar];
    final bottomMouth = face.landmarks[FaceLandmarkType.bottomMouth];


    // Logic: If any of these are null, the face is definitely cut off.
    if (leftEye == null || rightEye == null || leftEar == null || rightEar == null || bottomMouth == null) {
      await _cleanup(tempFile);
      print("Rejecting: Face extremities are out of frame.");
      return FaceDetectionResult(error: "Face extremities out of frame. Show your whole face.");
    }

    // We define a safety margin (threshold). If the box is within 15 pixels
    // of any edge, we assume the face is partially cut off.
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



    // 9. CALCULATE ASYMMETRIC PADDING:
    // Facial Expression Recognition (FER) models usually need some context (hair, chin).
    // We add more padding to the top (forehead) than the bottom (chin).
    final leftPadding = box.width * 0.12;
    final rightPadding = box.width * 0.12;
    final topPadding = box.height * 0.18;
    final bottomPadding = box.height * 0.10;

    // 10. Apply the padding to the initial MLKit bounding box
    final paddedLeft = box.left - leftPadding;
    final paddedTop = box.top - topPadding;
    final paddedRight = box.right + rightPadding;
    final paddedBottom = box.bottom + bottomPadding;

    // 11. Calculate dimensions of the new padded area
    final paddedWidth = paddedRight - paddedLeft;
    final paddedHeight = paddedBottom - paddedTop;

    // 12. FORCE SQUARE SHAPE:
    // Determine the larger dimension to ensure the final crop is a perfect square
    final squareSize = max(paddedWidth, paddedHeight);

    // 13. Find the center point of our padded face area
    final centerX = (paddedLeft + paddedRight) / 2;
    final centerY = (paddedTop + paddedBottom) / 2;

    // 14. Calculate the Top-Left (x, y) coordinates for the square crop
    int x = (centerX - squareSize / 2).round();
    int y = (centerY - squareSize / 2).round();
    int size = squareSize.round();

    // 15. BOUNDARY CHECK: Ensure we don't try to crop outside the image pixels (negative values)
    if (x < 0) x = 0;
    if (y < 0) y = 0;

    // 16. BOUNDARY CHECK: Ensure the square doesn't exceed the image width or height
    if (x + size > decoded.width) {
      size = decoded.width - x;
    }
    if (y + size > decoded.height) {
      size = decoded.height - y;
    }

    // 17. FINAL CLAMP: Make sure size is at least 1 pixel and fits within both constraints
    final finalSize = size.clamp(
      1,
      decoded.width - x < decoded.height - y
          ? decoded.width - x
          : decoded.height - y,
    );

    // 18. Execute the actual crop using the 'image' library
    final cropped = img.copyCrop(
      decoded,
      x: x,
      y: y,
      width: finalSize,
      height: finalSize,
    );

    // --- Lighting Robustness Module ---
    // 19. Calculate the mean pixel intensity (brightness) of the cropped face
    final brightness = _calculateMeanIntensity(cropped);
    print('DEBUG: Mean Pixel Intensity: $brightness');

    if (brightness < 50) {
      await _cleanup(tempFile);
      return FaceDetectionResult(error: "It's too dark for an accurate prediction.");
    }
    // -----------------------------------

    // 20. Clean up: Delete the temporary file from the device storage
    try {
      await tempFile.delete();
    } catch (_) {}

    // 21. Return the cropped face image to be sent to the Mood AI model
    return FaceDetectionResult(image: cropped);
  }

  /// Calculates the mean intensity (brightness) of an image using the luminance formula
  double _calculateMeanIntensity(img.Image image) {
    double totalIntensity = 0;
    for (final pixel in image) {
      // Standard luminance formula: 0.299*R + 0.587*G + 0.114*B
      totalIntensity += (0.299 * pixel.r + 0.587 * pixel.g + 0.114 * pixel.b);
    }
    return totalIntensity / (image.width * image.height);
  }

  Future<void> _cleanup(File file) async {
    try {
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }

  /// Properly dispose of the MLKit detector to free up memory
  void close() {
    _faceDetector.close();
  }
}
