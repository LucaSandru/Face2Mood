import 'package:flutter/material.dart';

/// A utility class containing metadata and helper methods for emotion processing.
class EmotionUtils {
  /// Maps emotion labels to their designated UI theme colors.
  static Color getEmotionColor(String emotion) {
    switch (emotion.toLowerCase().trim()) {
      case 'happy': return const Color(0xFF4CAF50);
      case 'neutral': return const Color(0xFFF1C40F);
      case 'sad': return const Color(0xFF3498DB);
      case 'angry': return const Color(0xFFE74C3C);
      case 'fear': return const Color(0xFF8E44AD);
      case 'disgust': return const Color(0xFF6B8E23);
      case 'surprise': return const Color(0xFFE67E22);
      case 'agree:': return const Color(0xFF4CAF50);
      case 'disagree:': return const Color(0xFFE74C3C);
      case 'partial agree:': return const Color(0xFF3498DB);
      default: return Colors.grey;
    }
  }

  /// Returns a brief interpretation of the emotional signal.
  static String getEmotionMeaning(String emotion) {
    switch (emotion.toLowerCase().trim()) {
      case 'angry': return 'High intensity, tension, and emotional heat.';
      case 'disgust': return 'Physical aversion, discomfort, or rejection.';
      case 'fear': return 'High alert, uncertainty, and inner unease.';
      case 'happy': return 'Joy, optimism, and high positive energy.';
      case 'neutral': return 'A state of balance, stability, and calm focus.';
      case 'sad': return 'Low energy, quiet reflection, and stillness.';
      case 'surprise': return 'Sudden novelty, wonder, and sharp attention.';
      default: return 'No description available.';
    }
  }

  /// Capitalizes the first letter of an emotion label for display.
  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }
}
