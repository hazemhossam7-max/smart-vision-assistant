import 'package:flutter/material.dart';

class AccessibleMicrophoneButton extends StatelessWidget {
  const AccessibleMicrophoneButton({
    super.key,
    required this.isBusy,
    required this.onPressed,
  });

  final bool isBusy;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: isBusy ? 'Processing command' : 'Start voice command',
      hint: 'Double tap to speak a command to the assistant',
      child: SizedBox(
        width: 176,
        height: 176,
        child: FilledButton(
          onPressed: isBusy ? null : onPressed,
          style: FilledButton.styleFrom(
            shape: const CircleBorder(),
            backgroundColor: const Color(0xFF0B6E69),
            disabledBackgroundColor: Colors.grey.shade500,
          ),
          child: Icon(
            isBusy ? Icons.hourglass_top_rounded : Icons.mic_rounded,
            size: 76,
          ),
        ),
      ),
    );
  }
}
