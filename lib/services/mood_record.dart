import 'dart:convert';


/// Data model representing a single emotion analysis record.
/// Stores prediction results, user feedback, and detailed emotion scores.
class MoodRecord {
  final int? id;
  final DateTime timestamp;
  final String primaryEmotion;
  final double confidence;
  final String? secondEmotion;
  final double? secondConfidence;
  final String? thirdEmotion;
  final double? thirdConfidence;
  
  final String blendedColorHex;

  final String? personName;
  final String? userDescription;
  final String? userDominantEmotion;

  final Map<String, double>? allEmotionScores;

  /// Creates a mood record that can be stored in the local database.
  MoodRecord({
    this.id,
    required this.timestamp,
    required this.primaryEmotion,
    required this.confidence,
    required this.secondEmotion,
    required this.secondConfidence,
    required this.thirdEmotion,
    required this.thirdConfidence,
    required this.blendedColorHex,
    this.personName,
    this.userDescription,
    this.userDominantEmotion,

    this.allEmotionScores,
  });


  // Store the complete emotion distribution as JSON text.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'primaryEmotion': primaryEmotion,
      'confidence': confidence,
      'secondEmotion': secondEmotion,
      'secondConfidence': secondConfidence,
      'thirdEmotion': thirdEmotion,
      'thirdConfidence': thirdConfidence,
      'blendedColorHex': blendedColorHex,
      'personName': personName,
      'userDescription': userDescription,
      'userDominantEmotion': userDominantEmotion,
      'allEmotionScores': allEmotionScores == null
          ? null
          : jsonEncode(allEmotionScores),
    };
  }


  /// Reconstructs a MoodRecord() object from a database row.
  factory MoodRecord.fromMap(Map<String, dynamic> map) {
    return MoodRecord(
      id: map['id'],
      timestamp: DateTime.parse(map['timestamp']),
      primaryEmotion: map['primaryEmotion'],
      confidence: map['confidence'] ?? 0.0,
      secondEmotion: map['secondEmotion'],
      secondConfidence: map['secondConfidence'],
      thirdEmotion: map['thirdEmotion'],
      thirdConfidence: map['thirdConfidence'],
      blendedColorHex: map['blendedColorHex'] ?? '#808080',
      personName: map['personName'],
      userDescription: map['userDescription'],
      userDominantEmotion: map ['userDominantEmotion'],

      // Restore the stored JSON string back into emotion-score values.
      allEmotionScores: map['allEmotionScores'] == null
          ? null
          : Map<String, double>.from(
        jsonDecode(map['allEmotionScores']).map(
              (key, value) => MapEntry(key, (value as num).toDouble()),
        ),
      ),
    );
  }
}
