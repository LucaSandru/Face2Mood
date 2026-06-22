import 'package:flutter/material.dart';

import '../../../services/mood_record.dart';
import 'mood_recent_history_card.dart';

class MoodHistoryList extends StatelessWidget {
  final List<MoodRecord> history;
  final Set<int> expandedItems;
  final ValueChanged<int> onToggleExpanded;
  final ValueChanged<MoodRecord> onDeleteRecord;
  final Color Function(String emotion) getEmotionColor;
  final Color Function(String? hex) getSafeColor;
  final String Function(String text) capitalize;


  /// Displays the filtered mood history as a list of expandable mood cards.
  const MoodHistoryList({
    super.key,
    required this.history,
    required this.expandedItems,
    required this.onToggleExpanded,
    required this.onDeleteRecord,
    required this.getEmotionColor,
    required this.getSafeColor,
    required this.capitalize,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: history.length,
      itemBuilder: (context, index) {

        // Retrieve the mood record associated with the current list item.
        final record = history[index];

        return MoodHistoryCard(
          record: record,
          isExpanded: expandedItems.contains(index),
          onTap: () => onToggleExpanded(index),
          onDelete: () => onDeleteRecord(record),
          getEmotionColor: getEmotionColor,
          getSafeColor: getSafeColor,
          capitalize: capitalize,
        );
      },
    );
  }
}