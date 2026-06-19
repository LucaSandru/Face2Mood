import 'dart:convert';


class MoodRecord {
  final int? id;
  final DateTime timestamp;
  final String primaryEmotion;
  final double confidence;
  
  // New fields for the other 2 percentages
  final String? secondEmotion;
  final double? secondConfidence;
  final String? thirdEmotion;
  final double? thirdConfidence;
  
  final String blendedColorHex;

  final String? personName;
  final String? userDescription;
  final String? userDominantEmotion;

  final Map<String, double>? allEmotionScores;

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
    this.userDescription,     // not needed 'required' since the user maybe not press 'Save to Stats' button
    this.userDominantEmotion,

    this.allEmotionScores,
  });

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
