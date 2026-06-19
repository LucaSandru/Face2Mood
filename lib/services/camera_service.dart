import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

class CameraService {
  static Future<CameraController?> initializeCamera() async {
    try {
      final cameras = await availableCameras();

      final frontCamera = cameras.firstWhere(
            (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await controller.initialize();
      return controller;
    } catch (e) {
      debugPrint('Error initializing camera: $e');
      return null;
    }
  }
}
