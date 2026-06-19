import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    final List<PieChartSectionData> sections = [];

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

    final double total = chartData.values.fold<double>(
      0.0,
          (a, b) => a + b,
    );

    return SizedBox(
      height: 220,
      child: Row(
        children: [
          Expanded(
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 35,
                sections: sections,
              ),
            ),
          ),
          const SizedBox(width: 20),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...chartData.entries.map((entry) {
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