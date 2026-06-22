import 'dart:math' as math;
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';


/// Displays either the live camera preview, the captured image, or a loading indicator while the camera is initializing.
class CameraSection extends StatelessWidget {
  final Uint8List? capturedPreviewBytes;
  final bool isCameraInitialized;
  final CameraController? controller;

  const CameraSection({
    super.key,
    required this.capturedPreviewBytes,
    required this.isCameraInitialized,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {

    // Show the captured image after a successful prediction.
    if (capturedPreviewBytes != null) {
      return Container(
        height: 480,
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [
            BoxShadow(
              color: Colors.black38,
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
          border: Border.all(color: Colors.white10),
          color: Colors.black,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Image.memory(
            capturedPreviewBytes!,
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    // Display a loading indicator until the camera becomes available.
    if (!isCameraInitialized || controller == null) {
      return Container(
        height: 360,
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: const Color(0xFF171522),
          borderRadius: BorderRadius.circular(28),
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final previewAspectRatio = 1 / controller!.value.aspectRatio;

    return Container(
      height: 470,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Colors.black38,
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
        border: Border.all(color: Colors.white10),
        color: Colors.black,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: AspectRatio(
          aspectRatio: previewAspectRatio,
          child:

          // Mirror the front-camera preview for a natural selfie experience.
          Transform(
            alignment: Alignment.center,
            transform: Matrix4.rotationY(math.pi),
            child: CameraPreview(controller!),
          ),
        ),
      ),
    );
  }
}