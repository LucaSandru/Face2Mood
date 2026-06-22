import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:Face2Mood/services/database_service.dart';
import 'package:Face2Mood/services/mood_record.dart';

/// Unit tests for the local database layer.
/// Verifies that mood records can be inserted, retrieved, and deleted.
void main() {
  late DatabaseService databaseService;

  // Initialize SQLite environment for testing.
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  // Create a new database service instance before each test.
  setUp(() {
    databaseService = DatabaseService();
  });

  group('DatabaseService', () {

    // 1. Verifies that a new mood record can be inserted into the database.
    test('inserts and retrieves a mood record', () async {
      final record = MoodRecord(
        timestamp: DateTime(2026, 6, 22, 14, 30),
        primaryEmotion: 'happy',
        confidence: 0.91,
        secondEmotion: 'neutral',
        secondConfidence: 0.06,
        thirdEmotion: 'surprise',
        thirdConfidence: 0.03,
        blendedColorHex: '#4CAF50',
        personName: 'You - Main User',
        userDescription: 'Test mood record',
        userDominantEmotion: 'happy',
        allEmotionScores: {
          'happy': 0.91,
          'neutral': 0.06,
          'surprise': 0.03,
          'sad': 0.0,
          'angry': 0.0,
          'fear': 0.0,
          'disgust': 0.0,
        },
      );

      // Ensure the database starts empty.
      await databaseService.clearAllMoods();

      // Insert a new mood record.
      await databaseService.insertMood(record);

      // Retrieve all stored records.
      final moods = await databaseService.getAllMoods();

      // Verify that the stored information matches the inserted record.
      expect(moods.length, 1);
      expect(moods.first.primaryEmotion, 'happy');
      expect(moods.first.confidence, 0.91);
      expect(moods.first.personName, 'You - Main User');
      expect(moods.first.allEmotionScores?['happy'], 0.91);
    });

    // 2. Verifies that a mood record can be deleted from the database.
    test('deletes a mood record', () async {
      await databaseService.clearAllMoods();

      final record = MoodRecord(
        timestamp: DateTime(2026, 6, 22, 15, 00),
        primaryEmotion: 'sad',
        confidence: 0.74,

        secondEmotion: null,
        secondConfidence: null,
        thirdEmotion: null,
        thirdConfidence: null,

        blendedColorHex: '#3498DB',
        personName: 'You - Main User',
      );

      // Insert the test record and store its ID.
      final insertedId = await databaseService.insertMood(record);

      var moods = await databaseService.getAllMoods();
      expect(moods.length, 1);

      // Delete the record and verify if database becomes empty.
      await databaseService.deleteMood(insertedId);

      moods = await databaseService.getAllMoods();
      expect(moods.length, 0);
    });
  });
}