import 'package:flutter/material.dart';

import '../core/duration_formatter.dart';
import '../models/workout_plan.dart';
import '../models/workout_snapshot.dart';
import '../theme/app_theme.dart';

class WorkoutProgressCard extends StatelessWidget {
  const WorkoutProgressCard({
    required this.plan,
    required this.snapshot,
    super.key,
  });

  final WorkoutPlan plan;
  final WorkoutSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final accent = snapshot.phase == WorkoutPhase.walk
        ? AppTheme.walkColor
        : AppTheme.runColor;
    final nextPhase = snapshot.phase == WorkoutPhase.walk
        ? WorkoutPhase.run
        : WorkoutPhase.walk;
    final willFinishThisPhase =
        plan.limitMode == WorkoutLimitMode.time &&
        snapshot.totalRemaining <= snapshot.phaseRemaining;

    final goalLabel = plan.limitMode == WorkoutLimitMode.intervals
        ? 'Cycle ${snapshot.cycleIndex + 1} of ${plan.intervalCount}'
        : '${formatDuration(snapshot.totalRemaining, alwaysShowHours: true)} '
              'total remaining';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    goalLabel,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  willFinishThisPhase
                      ? 'Finish'
                      : 'Next: ${nextPhase.actionLabel}',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _ProgressLine(
              label: 'Current ${snapshot.phase.actionLabel.toLowerCase()}',
              value: snapshot.phaseProgress,
              color: accent,
            ),
            const SizedBox(height: 14),
            _ProgressLine(
              label: 'Workout',
              value: snapshot.overallProgress,
              color: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressLine extends StatelessWidget {
  const _ProgressLine({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final normalizedValue = value.clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(label, style: Theme.of(context).textTheme.bodySmall),
            ),
            Text(
              '${(normalizedValue * 100).round()}%',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: normalizedValue,
          color: color,
          minHeight: 8,
          borderRadius: BorderRadius.circular(999),
        ),
      ],
    );
  }
}
