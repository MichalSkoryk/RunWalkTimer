import 'package:flutter/material.dart';

import '../models/workout_plan.dart';

class TimerControls extends StatelessWidget {
  const TimerControls({
    required this.status,
    required this.canStart,
    required this.onStart,
    required this.onPause,
    required this.onStop,
    super.key,
  });

  final WorkoutStatus status;
  final bool canStart;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final startLabel = switch (status) {
      WorkoutStatus.paused => 'Resume',
      WorkoutStatus.complete => 'Restart',
      _ => 'Start',
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    key: const ValueKey('start-button'),
                    onPressed: status == WorkoutStatus.running || !canStart
                        ? null
                        : onStart,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: Text(startLabel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.tonalIcon(
                    key: const ValueKey('pause-button'),
                    onPressed: status == WorkoutStatus.running ? onPause : null,
                    icon: const Icon(Icons.pause_rounded),
                    label: const Text('Pause'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                key: const ValueKey('stop-button'),
                onPressed: status == WorkoutStatus.idle ? null : onStop,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
                icon: const Icon(Icons.stop_rounded),
                label: const Text('Stop'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
