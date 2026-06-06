import 'package:flutter/material.dart';

import '../../vision/frame_metadata.dart';

class FrameScoreTile extends StatelessWidget {
  const FrameScoreTile({
    super.key,
    required this.frame,
  });

  final FrameMetadata frame;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rejected = frame.isRejected;

    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      leading: CircleAvatar(
        backgroundColor: rejected ? Colors.red.shade100 : Colors.green.shade100,
        foregroundColor: rejected ? Colors.red.shade800 : Colors.green.shade800,
        child: Text('${frame.index + 1}'),
      ),
      title: Text(
        'Score ${frame.finalScore.toStringAsFixed(2)}',
        style: theme.textTheme.titleSmall,
      ),
      subtitle: Text(
        rejected
            ? 'Rejected: ${frame.rejectionReasons.join(', ')}'
            : 'C ${frame.clarityScore.toStringAsFixed(2)} | B ${frame.brightnessScore.toStringAsFixed(2)} | U ${frame.uniquenessScore.toStringAsFixed(2)} | O ${frame.objectScore.toStringAsFixed(2)} | M ${frame.motionScore.toStringAsFixed(2)}',
      ),
    );
  }
}
