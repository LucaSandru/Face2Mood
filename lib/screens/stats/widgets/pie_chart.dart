import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';


/// Visualizes emotion statistics using a pie chart and percentage legend.
class StatsPieChart extends StatelessWidget {
  final Map<String, double> chartData;
  final Color Function(String emotion) getEmotionColor;
  final String Function(String text) capitalize;

  const StatsPieChart({
    super.key,
    required this.chartData,
    required this.getEmotionColor,
    required this.capitalize,
  });


  /// Builds the emotion distribution chart and its corresponding legend.
  @override
  Widget build(BuildContext context) {

    // Pie chart slices generated from the provided statistics.
    final List<PieChartSectionData> sections = [];

    // Create one chart section for each emotion with a non-zero value.
    chartData.forEach((key, value) {
      if (value > 0) {
        sections.add(
          PieChartSectionData(
            color: getEmotionColor(key),
            value: value,
            title: '',
            radius: 55,
          ),
        );
      }
    });

    // Total value used for percentage calculations in the legend.
    final double total = chartData.values.fold<double>(
      0.0,
          (a, b) => a + b,
    );

    return SizedBox(
      height: 220,
      child: Row(
        children: [
          Expanded(
            // Graphical representation of the emotion distribution.
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 35,
                sections: sections,
              ),
            ),
          ),
          const SizedBox(width: 20),

          // Legend displaying emotion names and their corresponding percentages.
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...chartData.entries.map((entry) {

                // Convert raw values into percentages for display.
                final double percentage =
                total > 0 ? (entry.value / total) * 100 : 0;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: getEmotionColor(entry.key),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: capitalize(entry.key),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextSpan(
                              text: ' ${percentage.toStringAsFixed(1)}%',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }
}