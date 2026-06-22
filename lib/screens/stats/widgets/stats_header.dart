import 'package:flutter/material.dart';


/// Displays the title and description associated with the currently selected statistics visualization.
class StatsHeader extends StatelessWidget {
  final String selectedStatisticType;

  const StatsHeader({
    super.key,
    required this.selectedStatisticType,
  });


  /// Updates the header text according to the selected statistic type.
  @override
  Widget build(BuildContext context) {

    // Default header used for the Average Emotion Signals chart.
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