import 'package:flutter/material.dart';

class ResetFiltersButton extends StatelessWidget {
  final VoidCallback onReset;

  const ResetFiltersButton({
    super.key,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onReset,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white10),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restart_alt,
              color: Colors.white54,
              size: 14,
            ),
            SizedBox(width: 5),
            Text(
              'Reset Filters',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}