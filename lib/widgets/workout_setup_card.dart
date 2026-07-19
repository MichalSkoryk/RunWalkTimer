import 'package:flutter/material.dart';

import '../models/workout_plan.dart';
import '../theme/app_theme.dart';
import 'compact_goal_input.dart';
import 'phase_setup_row.dart';

class WorkoutSetupCard extends StatelessWidget {
  const WorkoutSetupCard({
    required this.walkDurationController,
    required this.runDurationController,
    required this.totalDurationController,
    required this.intervalCountController,
    required this.walkBpmController,
    required this.runBpmController,
    required this.walkMetronomeEnabled,
    required this.runMetronomeEnabled,
    required this.limitMode,
    required this.enabled,
    required this.walkError,
    required this.runError,
    required this.goalError,
    required this.walkMetronomeError,
    required this.runMetronomeError,
    required this.soundEnabled,
    required this.onChanged,
    required this.onModeChanged,
    required this.onSoundChanged,
    required this.onWalkMetronomeChanged,
    required this.onRunMetronomeChanged,
    required this.onOpenSoundSettings,
    super.key,
  });

  final TextEditingController walkDurationController;
  final TextEditingController runDurationController;
  final TextEditingController totalDurationController;
  final TextEditingController intervalCountController;
  final TextEditingController walkBpmController;
  final TextEditingController runBpmController;
  final bool walkMetronomeEnabled;
  final bool runMetronomeEnabled;
  final WorkoutLimitMode limitMode;
  final bool enabled;
  final String? walkError;
  final String? runError;
  final String? goalError;
  final String? walkMetronomeError;
  final String? runMetronomeError;
  final bool soundEnabled;
  final VoidCallback onChanged;
  final ValueChanged<WorkoutLimitMode> onModeChanged;
  final ValueChanged<bool> onSoundChanged;
  final ValueChanged<bool> onWalkMetronomeChanged;
  final ValueChanged<bool> onRunMetronomeChanged;
  final VoidCallback onOpenSoundSettings;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: const ValueKey('workout-setup-card'),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Workout setup',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                TextButton.icon(
                  key: const ValueKey('setup-sound-settings-button'),
                  onPressed: onOpenSoundSettings,
                  icon: const Icon(Icons.graphic_eq_rounded, size: 18),
                  label: const Text('Sounds'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            PhaseSetupRow(
              phaseKey: 'walk',
              title: 'Walk',
              icon: Icons.directions_walk_rounded,
              accentColor: AppTheme.walkColor,
              durationController: walkDurationController,
              durationError: walkError,
              metronomeEnabled: walkMetronomeEnabled,
              bpmController: walkBpmController,
              bpmError: walkMetronomeError,
              enabled: enabled,
              onMetronomeChanged: onWalkMetronomeChanged,
              onChanged: onChanged,
            ),
            const SizedBox(height: 8),
            PhaseSetupRow(
              phaseKey: 'run',
              title: 'Run',
              icon: Icons.directions_run_rounded,
              accentColor: AppTheme.runColor,
              durationController: runDurationController,
              durationError: runError,
              metronomeEnabled: runMetronomeEnabled,
              bpmController: runBpmController,
              bpmError: runMetronomeError,
              enabled: enabled,
              onMetronomeChanged: onRunMetronomeChanged,
              onChanged: onChanged,
            ),
            const SizedBox(height: 8),
            CompactGoalInput(
              mode: limitMode,
              totalDurationController: totalDurationController,
              intervalCountController: intervalCountController,
              enabled: enabled,
              errorText: goalError,
              onModeChanged: onModeChanged,
              onChanged: onChanged,
            ),
            const SizedBox(height: 4),
            SwitchListTile.adaptive(
              key: const ValueKey('sound-cues-switch'),
              value: soundEnabled,
              onChanged: onSoundChanged,
              contentPadding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              secondary: Icon(
                soundEnabled
                    ? Icons.volume_up_rounded
                    : Icons.volume_off_rounded,
                size: 22,
              ),
              title: const Text(
                'Sound cues',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: const Text('Walk, Run, and completion tones'),
            ),
          ],
        ),
      ),
    );
  }
}
