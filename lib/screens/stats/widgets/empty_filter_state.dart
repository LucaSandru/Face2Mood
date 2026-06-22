import 'package:flutter/material.dart';


/// Displayed when the selected filters return no mood records.
class EmptyFilterState extends StatelessWidget {
  const EmptyFilterState({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF171522),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.filter_alt_off,
            size: 42,
            color: Colors.white24,
          ),
          const SizedBox(height: 14),
          const Text(
            'No matching mood records',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          // Suggests adjusting the active filters to find matching records.
          RichText(
            textAlign: TextAlign.center,
            text: const TextSpan(
              style: TextStyle(
                color: Colors.white54,
                fontSize: 13,
                height: 1.4,
              ),
              children: [
                TextSpan(text: 'Try changing the '),
                TextSpan(
                  text: 'Person',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextSpan(text: ', '),
                TextSpan(
                  text: 'Time',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextSpan(text: ', or '),
                TextSpan(
                  text: 'Type',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextSpan(text: ' filters.'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}