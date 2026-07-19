import 'package:flutter/material.dart';

import '../core/duration_input_format.dart';
import '../models/workout_plan.dart';
import '../theme/app_theme.dart';
import 'duration_input.dart';
import 'goal_mode_selector.dart';
import 'numeric_field.dart';

class WorkoutSetupCard extends StatelessWidget {
  const WorkoutSetupCard({
    required this.walkDurationController,
    required this.runDurationController,
    required this.totalDurationController,
    required this.intervalCountController,
    required this.limitMode,
    required this.enabled,
    required this.walkError,
    required this.runError,
    required this.goalError,
    required this.soundEnabled,
    required this.onChanged,
    required this.onModeChanged,
    required this.onSoundChanged,
    super.key,
  });

  final TextEditingController walkDurationController;
  final TextEditingController runDurationController;
  final TextEditingController totalDurationController;
  final TextEditingController intervalCountController;
  final WorkoutLimitMode limitMode;
  final bool enabled;
  final String? walkError;
  final String? runError;
  final String? goalError;
  final bool soundEnabled;
  final VoidCallback onChanged;
  final ValueChanged<WorkoutLimitMode> onModeChanged;
  final ValueChanged<bool> onSoundChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Workout setup',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              'The workout starts with walking, then alternates with running.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            DurationInput(
              inputKey: const ValueKey('walk'),
              title: 'Walk duration',
              icon: Icons.directions_walk_rounded,
              accentColor: AppTheme.walkColor,
              controller: walkDurationController,
              format: DurationInputFormat.minutesSeconds,
              enabled: enabled,
              errorText: walkError,
              onChanged: onChanged,
            ),
            const SizedBox(height: 14),
            DurationInput(
              inputKey: const ValueKey('run'),
              title: 'Run duration',
              icon: Icons.directions_run_rounded,
              accentColor: AppTheme.runColor,
              controller: runDurationController,
              format: DurationInputFormat.minutesSeconds,
              enabled: enabled,
              errorText: runError,
              onChanged: onChanged,
            ),
            const SizedBox(height: 22),
            GoalModeSelector(
              value: limitMode,
              enabled: enabled,
              onChanged: onModeChanged,
            ),
            const SizedBox(height: 14),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: limitMode == WorkoutLimitMode.time
                  ? DurationInput(
                      key: const ValueKey('time-goal'),
                      inputKey: const ValueKey('total'),
                      title: 'Total workout time',
                      icon: Icons.timer_outlined,
                      accentColor: Theme.of(context).colorScheme.primary,
                      controller: totalDurationController,
                      format: DurationInputFormat.hoursMinutesSeconds,
                      enabled: enabled,
                      errorText: goalError,
                      onChanged: onChanged,
                    )
                  : _IntervalCountInput(
                      key: const ValueKey('interval-goal'),
                      controller: intervalCountController,
                      enabled: enabled,
                      errorText: goalError,
                      onChanged: onChanged,
                    ),
            ),
            const SizedBox(height: 20),
            _SoundCueSwitch(value: soundEnabled, onChanged: onSoundChanged),
          ],
        ),
      ),
    );
  }
}

class _SoundCueSwitch extends StatelessWidget {
  const _SoundCueSwitch({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: SwitchListTile.adaptive(
        key: const ValueKey('sound-cues-switch'),
        value: value,
        onChanged: onChanged,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        secondary: Icon(
          value ? Icons.volume_up_rounded : Icons.volume_off_rounded,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: const Text(
          'Sound cues',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: const Text(
          'Play tones for Walk, Run, and completion. '
          'Vibration remains active.',
        ),
      ),
    );
  }
}

class _IntervalCountInput extends StatelessWidget {
  const _IntervalCountInput({
    required this.controller,
    required this.enabled,
    required this.errorText,
    required this.onChanged,
    super.key,
  });

  final TextEditingController controller;
  final bool enabled;
  final String? errorText;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('interval-count-input'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: errorText == null
              ? Theme.of(context).colorScheme.outlineVariant
              : Theme.of(context).colorScheme.error,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.loop_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Number of cycles',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          NumericField(
            fieldKey: const ValueKey('interval-count'),
            controller: controller,
            label: 'Cycles',
            semanticLabel: 'Number of walk and run cycles',
            enabled: enabled,
            onChanged: (_) => onChanged(),
          ),
          const SizedBox(height: 8),
          Text(
            errorText ?? '1 cycle = one walk followed by one run.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: errorText == null
                  ? Theme.of(context).colorScheme.onSurfaceVariant
                  : Theme.of(context).colorScheme.error,
            ),
          ),
        ],
      ),
    );
  }
}
