import 'package:flutter/material.dart';

import '../models/workout_plan.dart';

class GoalModeSelector extends StatelessWidget {
  const GoalModeSelector({
    required this.value,
    required this.enabled,
    required this.onChanged,
    super.key,
  });

  final WorkoutLimitMode value;
  final bool enabled;
  final ValueChanged<WorkoutLimitMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Stop after',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<WorkoutLimitMode>(
            key: const ValueKey('goal-mode-selector'),
            segments: const [
              ButtonSegment(
                value: WorkoutLimitMode.time,
                icon: Icon(Icons.schedule_rounded),
                label: Text('Time'),
              ),
              ButtonSegment(
                value: WorkoutLimitMode.intervals,
                icon: Icon(Icons.repeat_rounded),
                label: Text('Intervals'),
              ),
            ],
            selected: <WorkoutLimitMode>{value},
            onSelectionChanged: enabled
                ? (selection) => onChanged(selection.first)
                : null,
            showSelectedIcon: false,
            expandedInsets: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }
}
