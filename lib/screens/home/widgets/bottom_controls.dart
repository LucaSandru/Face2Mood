import 'package:flutter/material.dart';

class BottomControls extends StatelessWidget {
  final bool modelReady;
  final bool hasCapturedPreview;
  final VoidCallback onShowTips;
  final VoidCallback onCapture;
  final VoidCallback onRetry;

  const BottomControls({
    super.key,
    required this.modelReady,
    required this.hasCapturedPreview,
    required this.onShowTips,
    required this.onCapture,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: onShowTips,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF1B1828),
                border: Border.all(color: Colors.white12),
              ),
              child: const Icon(
                Icons.info_outline,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),

          Column(
            children: [
              GestureDetector(
                onTap: (modelReady && !hasCapturedPreview) ? onCapture : null,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (modelReady && !hasCapturedPreview)
                        ? Colors.white
                        : Colors.grey,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.12),
                        blurRadius: 18,
                        spreadRadius: 2,
                      ),
                    ],
                    border: Border.all(
                      color: Colors.white30,
                      width: 4,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                !modelReady
                    ? 'Model loading...'
                    : hasCapturedPreview
                    ? 'Press retry to analyze again'
                    : 'Tap to analyze',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          GestureDetector(
            onTap: onRetry,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF1B1828),
                border: Border.all(color: Colors.white12),
              ),
              child: const Icon(
                Icons.refresh_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
        ],
      ),
    );
  }
}