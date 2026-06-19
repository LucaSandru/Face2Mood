import 'package:flutter/material.dart';

class StatsHeader extends StatelessWidget {
  final String selectedStatisticType;

  const StatsHeader({
    super.key,
    required this.selectedStatisticType,
  });

  @override
  Widget build(BuildContext context) {
    String title = 'Emotion Distribution';
    String subtitle = 'Percentages of your emotions over time';

    if (selectedStatisticType == 'Top Prediction Count') {
      title = 'Most Detected Emotions';
      subtitle = 'Frequency of your primary AI predictions';
    } else if (selectedStatisticType == 'User vs Model Agreement') {
      title = 'Prediction Agreement';
      subtitle = 'Agreement between your feedback and AI predictions';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.white54,
          ),
        ),
      ],
    );
  }
}