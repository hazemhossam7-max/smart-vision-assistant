import 'package:flutter/material.dart';

class AccessibleMicrophoneButton extends StatelessWidget {
  const AccessibleMicrophoneButton({
    super.key,
    required this.isBusy,
    required this.isListening,
    required this.onHoldStart,
    required this.onHoldEnd,
  });

  final bool isBusy;
  final bool isListening;
  final VoidCallback? onHoldStart;
  final VoidCallback? onHoldEnd;

  @override
  Widget build(BuildContext context) {
    final enabled = !isBusy || isListening;
    final backgroundColor = isListening
        ? const Color(0xFFB3261E)
        : isBusy
            ? Colors.grey.shade500
            : const Color(0xFF0B6E69);

    return Semantics(
      button: true,
      enabled: enabled,
      label: isListening
          ? 'Release to send command'
          : isBusy
              ? 'Processing command'
              : 'Hold microphone to speak',
      hint: 'Hold while speaking, then release to send the command',
      child: SizedBox(
        width: 176,
        height: 176,
        child: GestureDetector(
          onTapDown: isBusy ? null : (_) => onHoldStart?.call(),
          onTapUp: (_) => onHoldEnd?.call(),
          onTapCancel: () => onHoldEnd?.call(),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: backgroundColor,
              boxShadow: [
                BoxShadow(
                  color: backgroundColor.withValues(alpha: 0.35),
                  blurRadius: isListening ? 26 : 14,
                  spreadRadius: isListening ? 8 : 2,
                ),
              ],
            ),
            child: Icon(
              isListening
                  ? Icons.mic_external_on_rounded
                  : isBusy
                      ? Icons.hourglass_top_rounded
                      : Icons.mic_rounded,
              color: Colors.white,
              size: 76,
            ),
          ),
        ),
      ),
    );
  }
}
