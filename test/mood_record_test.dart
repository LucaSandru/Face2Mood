import 'package:flutter_test/flutter_test.dart';
import 'package:Face2Mood/services/mood_record.dart';

/// Unit tests for the MoodRecord model.
/// Verifies correct serialization and restoration of mood data.
void main() {
  group('MoodRecord', () {

    // 1. Verifies that a MoodRecord can be converted to a map and back correctly.
    test('converts MoodRecord to map and back correctly', () {
      final timestamp = DateTime(2026, 6, 22, 12, 30);

      final record = MoodRecord(
        id: 1,
        timestamp: timestamp,
        primaryEmotion: 'happy',
        confidence: 0.85,
        secondEmotion: 'neutral',
        secondConfidence: 0.10,
        thirdEmotion: 'surprise',
        thirdConfidence: 0.05,
        blendedColorHex: '#4CAF50',
        personName: 'You - Main User',
        userDescription: 'Test the mood record',
        userDominantEmotion: 'happy',
        allEmotionScores: {
          'happy': 0.75,
          'neutral': 0.10,
          'surprise': 0.05,
          'sad': 0.4,
          'angry': 0.3,
          'fear': 0.2,
          'disgust': 0.1,
        },
      );

      // Convert the object into a database-friendly map.
      final map = record.toMap();

      // Restore the object from the generated map.
      final restoredRecord = MoodRecord.fromMap(map);

      // Verify if stored information remains unchanged.
      expect(restoredRecord.id, 1);
      expect(restoredRecord.timestamp, timestamp);
      expect(restoredRecord.primaryEmotion, 'happy');
      expect(restoredRecord.confidence, 0.85);
      expect(restoredRecord.secondEmotion, 'neutral');
      expect(restoredRecord.secondConfidence, 0.10);
      expect(restoredRecord.thirdEmotion, 'surprise');
      expect(restoredRecord.thirdConfidence, 0.05);
      expect(restoredRecord.blendedColorHex, '#4CAF50');
      expect(restoredRecord.personName, 'You - Main User');
      expect(restoredRecord.userDescription, 'Test the mood record');
      expect(restoredRecord.userDominantEmotion, 'happy');
      expect(restoredRecord.allEmotionScores?['happy'], 0.75);
      expect(restoredRecord.allEmotionScores?['neutral'], 0.10);
    });

    // 2. Verifies that default values are used when optional fields are missing.
    test('uses default values when optional map fields are missing', () {
      final map = {
        'id': 2,
        'timestamp': DateTime(2026, 6, 22).toIso8601String(),
        'primaryEmotion': 'sad',
        'confidence': null,
      };

      final record = MoodRecord.fromMap(map);

      expect(record.id, 2);
      expect(record.primaryEmotion, 'sad');
      expect(record.confidence, 0.0);
      expect(record.blendedColorHex, '#808080');
      expect(record.allEmotionScores, null);
    });
  });
}