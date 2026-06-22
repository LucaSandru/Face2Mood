import 'package:flutter/material.dart';


/// Action buttons displayed below the emotion results.
/// Allows the user to view additional details and save the analysis to statistics.
class ActionButtons extends StatelessWidget {
  final bool showMoreInfo;
  final bool isSaved;

  final VoidCallback onToggleInfo;
  final VoidCallback onSave;
  final VoidCallback onUnsave;

  const ActionButtons({
    super.key,
    required this.showMoreInfo,
    required this.isSaved,
    required this.onToggleInfo,
    required this.onSave,
    required this.onUnsave,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // Toggle additional information about the current prediction.
          Expanded(
            child: OutlinedButton(
              onPressed: onToggleInfo,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFD4BEFF)),
                backgroundColor: const Color(0xFF292545),
                foregroundColor: const Color(0xFFD4BEFF),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                showMoreInfo ? 'Hide info' : 'More info',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),


          // 'Save to stats' or 'Unsave' the mood record from the local statistics database.
          Expanded(
            child: OutlinedButton(
              onPressed: isSaved ? onUnsave : onSave,
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: isSaved
                      ? Colors.redAccent
                      : Colors.greenAccent,
                ),
                backgroundColor: isSaved
                    ? Colors.redAccent.withOpacity(0.15)
                    : Colors.greenAccent.withOpacity(0.15),
                foregroundColor:
                isSaved ? Colors.redAccent : Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                isSaved ? 'Unsave' : 'Save to stats',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}