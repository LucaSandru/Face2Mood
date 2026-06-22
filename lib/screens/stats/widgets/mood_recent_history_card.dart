import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../services/mood_record.dart';


/// Expandable card displaying a single mood history record, including user info, emotion predictions, and deletion options.
class MoodHistoryCard extends StatelessWidget {
  final MoodRecord record;
  final bool isExpanded;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final Color Function(String emotion) getEmotionColor;
  final Color Function(String? hex) getSafeColor;
  final String Function(String text) capitalize;

  const MoodHistoryCard({
    super.key,
    required this.record,
    required this.isExpanded,
    required this.onTap,
    required this.onDelete,
    required this.getEmotionColor,
    required this.getSafeColor,
    required this.capitalize,
  });


  /// Builds the visual representation of a stored mood record.
  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('MMM dd, HH:mm').format(record.timestamp);
    final contextName = record.personName;
    final description = record.userDescription;
    final userEmotion = record.userDominantEmotion;

    // Use the selected person name when available.
    final displayName =
    contextName != null && contextName.isNotEmpty ? contextName : 'Mood entry';

    // Prioritize the user's self-reported emotion over the model prediction.
    final feltEmotion =
    userEmotion != null && userEmotion.isNotEmpty
        ? userEmotion
        : record.primaryEmotion;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF171522),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildEmotionAvatar(),
            const SizedBox(width: 14),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 5,
                    child: _buildLeftContent(
                      displayName: displayName,
                      dateStr: dateStr,
                      feltEmotion: feltEmotion,
                      description: description,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 4,
                    child: _buildRightContent(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmotionAvatar() {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: getSafeColor(record.blendedColorHex),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(
        Icons.face,
        color: Colors.white70,
      ),
    );
  }


  /// Displays contextual information such as person name,
  /// timestamp, user emotion, and optional description.
  Widget _buildLeftContent({
    required String displayName,
    required String dateStr,
    required String feltEmotion,
    required String? description,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          displayName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          dateStr,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        RichText(
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          text: TextSpan(
            children: [
              const TextSpan(
                text: 'You felt: ',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              TextSpan(
                text: capitalize(feltEmotion),
                style: TextStyle(
                  color: getEmotionColor(feltEmotion),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),

        // Show the user-provided context description when available.
        if (description != null && description.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            description,
            maxLines: isExpanded ? null : 2,
            overflow: isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 12,
              height: 1.3,
            ),
          ),
        ],
      ],
    );
  }


  /// Displays the model predictions and record management actions.
  Widget _buildRightContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _buildDeleteButton(context),
        const SizedBox(height: 10),
        const Text(
          'Results:',
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 3),
        _buildPrimaryPrediction(),
        _buildSecondaryPrediction(),
        _buildThirdPrediction(),
      ],
    );
  }


  /// Opens a confirmation dialog before deleting the mood record.
  Widget _buildDeleteButton(BuildContext context) {
    return InkWell(
      onTap: () => _showDeleteDialog(context),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: Colors.redAccent.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.redAccent.withOpacity(0.55),
          ),
        ),
        child: const Icon(
          Icons.delete_outline,
          color: Colors.redAccent,
          size: 16,
        ),
      ),
    );
  }


  /// Displays the most probable emotion predicted by the model.
  Widget _buildPrimaryPrediction() {
    return Text(
      '${capitalize(record.primaryEmotion)} ${(record.confidence * 100).toStringAsFixed(0)}%',
      textAlign: TextAlign.right,
      style: TextStyle(
        color: getEmotionColor(record.primaryEmotion),
        fontSize: 13,
        fontWeight: FontWeight.bold,
      ),
    );
  }


  /// Displays the second most probable predicted emotion.
  Widget _buildSecondaryPrediction() {
    if (record.secondEmotion == null || record.secondConfidence == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Text(
        '${capitalize(record.secondEmotion!)} ${(record.secondConfidence! * 100).toStringAsFixed(0)}%',
        textAlign: TextAlign.right,
        style: TextStyle(
          color: getEmotionColor(record.secondEmotion!).withOpacity(0.85),
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }


  /// Displays the third most probable predicted emotion.
  Widget _buildThirdPrediction() {
    if (record.thirdEmotion == null || record.thirdConfidence == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Text(
        '${capitalize(record.thirdEmotion!)} ${(record.thirdConfidence! * 100).toStringAsFixed(0)}%',
        textAlign: TextAlign.right,
        style: TextStyle(
          color: getEmotionColor(record.thirdEmotion!).withOpacity(0.85),
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }


  /// Requests user confirmation before permanently removing a mood record.
  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF171522),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Delete this mood record?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
            ),
          ),
          content: const Text(
            'This record will be permanently removed from your mood history.',
            style: TextStyle(
              color: Colors.white70,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.white60,
                ),
              ),
            ),
            TextButton(
              onPressed: onDelete,
              child: const Text(
                'Delete',
                style: TextStyle(
                  color: Colors.redAccent,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}