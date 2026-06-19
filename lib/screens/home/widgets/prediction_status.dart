import 'package:flutter/material.dart';

class StatusText extends StatelessWidget {
  final String message;
  final bool hasError;
  final GlobalKey? statusKey;

  const StatusText({
    super.key,
    required this.message,
    required this.hasError,
    this.statusKey,
  });

  @override
  Widget build(BuildContext context) {
    final isSuccess = message == 'Prediction completed';

    return Padding(
      key: statusKey,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: hasError
              ? Colors.redAccent
              : (isSuccess ? Colors.greenAccent : Colors.white70),
          fontSize: 14,
          fontWeight: (hasError || isSuccess)
              ? FontWeight.bold
              : FontWeight.normal,
        ),
      ),
    );
  }
}