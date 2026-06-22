import 'mood_record.dart';

/// Provides reusable statistics calculations for mood records.
/// This keeps the statistics logic independent from the StatsScreen UI.
class StatisticsService {

  /// Calculates the average confidence signal for each emotion across all records.
  static Map<String, double> calculateAverageSignals(List<MoodRecord> records) {
    final Map<String, double> weights = {};

    for (final record in records) {

      // First case: use all 7 stored emotion scores.
      if (record.allEmotionScores != null &&
          record.allEmotionScores!.isNotEmpty) {
        record.allEmotionScores!.forEach((emotion, score) {
          weights[emotion] = (weights[emotion] ?? 0) + score;
        });

        // Second case: Fallback for older records (Top-3 only)
      } else {
        weights[record.primaryEmotion] =
            (weights[record.primaryEmotion] ?? 0) + record.confidence;

        if (record.secondEmotion != null && record.secondConfidence != null) {
          weights[record.secondEmotion!] =
              (weights[record.secondEmotion!] ?? 0) + record.secondConfidence!;
        }

        if (record.thirdEmotion != null && record.thirdConfidence != null) {
          weights[record.thirdEmotion!] =
              (weights[record.thirdEmotion!] ?? 0) + record.thirdConfidence!;
        }
      }
    }

    // Convert accumulated emotion scores into average values
    final averagedWeights = weights.map(
          (emotion, value) => MapEntry(emotion, value / records.length),
    );

    // Sort emotions in descending order such that dominant emotions appear first
    final sortedEntries = averagedWeights.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Map.fromEntries(sortedEntries);
  }

  /// Counts how many times each emotion appears as the primary predicted emotion.
  static Map<String, double> calculateTopPredictionStats(
      List<MoodRecord> records,
      ) {
    final Map<String, double> counts = {};

    for (final record in records) {
      if (counts[record.primaryEmotion] == null) {
        counts[record.primaryEmotion] = 0;
      }
      counts[record.primaryEmotion] = counts[record.primaryEmotion]! + 1.0;
    }

    return counts;
  }

  /// Compares the user's selected emotion with the model's top-3 predictions.
  static Map<String, double> calculateAgreementStats(List<MoodRecord> records) {
    double agreement = 0;
    double partialAgreement = 0;
    double disagreement = 0;

    for (final record in records) {
      final userEmotion = record.userDominantEmotion;

      if (userEmotion != null && userEmotion.isNotEmpty) {
        final user = userEmotion.toLowerCase().trim();

        final top1 = record.primaryEmotion.toLowerCase().trim();
        final top2 = record.secondEmotion?.toLowerCase().trim();
        final top3 = record.thirdEmotion?.toLowerCase().trim();

        if (user == top1) {
          agreement += 1.0;
        } else if (user == top2 || user == top3) {
          partialAgreement += 1.0;
        } else {
          disagreement += 1.0;
        }
      }
    }

    return {
      'Agree:': agreement,
      'Partial agree:': partialAgreement,
      'Disagree:': disagreement,
    };
  }
}