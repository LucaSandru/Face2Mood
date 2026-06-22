import 'package:flutter_test/flutter_test.dart';

import 'package:Face2Mood/services/mood_record.dart';
import 'package:Face2Mood/services/statistics_service.dart';

/// Unit tests for mood statistics calculations.
/// Verifies average signals, top prediction counts, and user-model agreement.
void main() {
  group('StatisticsService', () {

    // Test 1. Verifies that average emotion signals are calculated correctly.
    test('calculates average emotion signals using all emotion scores', () {
      final records = [
        _createRecord(
          primaryEmotion: 'happy',
          confidence: 0.8,
          allEmotionScores: {
            'happy': 0.8,
            'sad': 0.1,
            'neutral': 0.1,
          },
        ),
        _createRecord(
          primaryEmotion: 'sad',
          confidence: 0.6,
          allEmotionScores: {
            'happy': 0.2,
            'sad': 0.6,
            'neutral': 0.2,
          },
        ),
      ];

      final result = StatisticsService.calculateAverageSignals(records);

      // Verify if stored information is correct.
      expect(result['happy'], closeTo(0.5, 0.0001));
      expect(result['sad'], closeTo(0.35, 0.0001));
      expect(result['neutral'], closeTo(0.15, 0.0001));
    });

    // Test 2. Verifies that the primary emotion is counted correctly, across multiple mood records.
    test('counts top predicted emotions correctly', () {
      final records = [
        _createRecord(primaryEmotion: 'happy'),
        _createRecord(primaryEmotion: 'happy'),
        _createRecord(primaryEmotion: 'sad'),
      ];

      final result = StatisticsService.calculateTopPredictionStats(records);

      // Verify if stored information is correct.
      expect(result['happy'], 2.0);
      expect(result['sad'], 1.0);
    });

    // Test 3. Verifies agreement, partial agreement, and disagreement between user's selected emotion and the model predictions.
    test('calculates user versus model agreement correctly', () {
      final records = [
        _createRecord(
          primaryEmotion: 'happy',
          secondEmotion: 'neutral',
          thirdEmotion: 'sad',
          userDominantEmotion: 'happy',
        ),
        _createRecord(
          primaryEmotion: 'angry',
          secondEmotion: 'sad',
          thirdEmotion: 'neutral',
          userDominantEmotion: 'sad',
        ),
        _createRecord(
          primaryEmotion: 'fear',
          secondEmotion: 'angry',
          thirdEmotion: 'disgust',
          userDominantEmotion: 'happy',
        ),
      ];

      final result = StatisticsService.calculateAgreementStats(records);

      // Verify if stored information is correct.
      expect(result['Agree:'], 1.0);
      expect(result['Partial agree:'], 1.0);
      expect(result['Disagree:'], 1.0);
    });
  });
}


MoodRecord _createRecord({
  required String primaryEmotion,
  double confidence = 0.9,
  String? secondEmotion,
  String? thirdEmotion,
  String? userDominantEmotion,
  Map<String, double>? allEmotionScores,
}) {
  return MoodRecord(
    timestamp: DateTime(2026, 6, 22),
    primaryEmotion: primaryEmotion,
    confidence: confidence,
    secondEmotion: secondEmotion,
    secondConfidence: secondEmotion == null ? null : 0.05,
    thirdEmotion: thirdEmotion,
    thirdConfidence: thirdEmotion == null ? null : 0.05,
    blendedColorHex: '#808080',
    userDominantEmotion: userDominantEmotion,
    allEmotionScores: allEmotionScores,
  );
}