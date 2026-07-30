import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/duration_input_format.dart';
import '../models/workout_plan.dart';
import 'compact_duration_field.dart';

class CompactGoalInput extends StatelessWidget {
  const CompactGoalInput({
    required this.mode,
    required this.totalDurationController,
    required this.intervalCountController,
    required this.enabled,
    required this.errorText,
    required this.onModeChanged,
    required this.onChanged,
    super.key,
  });

  final WorkoutLimitMode mode;
  final TextEditingController totalDurationController;
  final TextEditingController intervalCountController;
  final bool enabled;
  final String? errorText;
  final ValueChanged<WorkoutLimitMode> onModeChanged;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: errorText == null
              ? Theme.of(context).colorScheme.outlineVariant
              : Theme.of(context).colorScheme.error,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final textScale = MediaQuery.textScalerOf(context).scale(16) / 16;
              final selector = SegmentedButton<WorkoutLimitMode>(
                key: const ValueKey('goal-mode-selector'),
                segments: const [
                  ButtonSegment(
                    value: WorkoutLimitMode.time,
                    label: Text('Time'),
                  ),
                  ButtonSegment(
                    value: WorkoutLimitMode.intervals,
                    label: Text('Intervals'),
                  ),
                ],
                selected: <WorkoutLimitMode>{mode},
                onSelectionChanged: enabled
                    ? (selection) => onModeChanged(selection.first)
                    : null,
                showSelectedIcon: false,
                expandedInsets: EdgeInsets.zero,
                style: const ButtonStyle(visualDensity: VisualDensity.compact),
              );
              final title = Text(
                'Stop after',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              );
              if (constraints.maxWidth < 340 || textScale > 1.3) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [title, const SizedBox(height: 8), selector],
                );
              }
              return Row(
                children: [
                  title,
                  const SizedBox(width: 12),
                  Expanded(child: selector),
                ],
              );
            },
          ),
          const SizedBox(height: 10),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: mode == WorkoutLimitMode.time
                ? Container(
                    key: const ValueKey('total'),
                    child: CompactDurationField(
                      fieldKey: const ValueKey('total-duration'),
                      controller: totalDurationController,
                      format: DurationInputFormat.hoursMinutesSeconds,
                      semanticLabel: 'Total workout time',
                      enabled: enabled,
                      errorText: errorText,
                      onChanged: onChanged,
                    ),
                  )
                : Container(
                    key: const ValueKey('interval-count-input'),
                    child: TextField(
                      key: const ValueKey('interval-count'),
                      controller: intervalCountController,
                      enabled: enabled,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      onChanged: (_) => onChanged(),
                      decoration: InputDecoration(
                        labelText: 'Number of cycles',
                        isDense: true,
                        errorText: errorText,
                        errorMaxLines: 2,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
