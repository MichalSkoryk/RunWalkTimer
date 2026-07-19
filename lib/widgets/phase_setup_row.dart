import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/duration_input_format.dart';
import '../models/metronome_config.dart';
import 'compact_duration_field.dart';

class PhaseSetupRow extends StatelessWidget {
  const PhaseSetupRow({
    required this.phaseKey,
    required this.title,
    required this.icon,
    required this.accentColor,
    required this.durationController,
    required this.durationError,
    required this.metronomeEnabled,
    required this.bpmController,
    required this.bpmError,
    required this.enabled,
    required this.onMetronomeChanged,
    required this.onChanged,
    super.key,
  });

  final String phaseKey;
  final String title;
  final IconData icon;
  final Color accentColor;
  final TextEditingController durationController;
  final String? durationError;
  final bool metronomeEnabled;
  final TextEditingController bpmController;
  final String? bpmError;
  final bool enabled;
  final ValueChanged<bool> onMetronomeChanged;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final hasError = durationError != null || bpmError != null;
    return Container(
      key: ValueKey(phaseKey),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasError
              ? Theme.of(context).colorScheme.error
              : Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 500) {
            return Row(
              children: [
                _PhaseLabel(title: title, icon: icon, color: accentColor),
                const SizedBox(width: 14),
                SizedBox(width: 132, child: _durationField()),
                const SizedBox(width: 12),
                _MetronomeToggle(
                  phaseKey: phaseKey,
                  checked: metronomeEnabled,
                  enabled: enabled,
                  onChanged: onMetronomeChanged,
                ),
                if (metronomeEnabled) ...[
                  const SizedBox(width: 10),
                  SizedBox(width: 132, child: _bpmField()),
                ],
              ],
            );
          }

          return Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _PhaseLabel(
                      title: title,
                      icon: icon,
                      color: accentColor,
                    ),
                  ),
                  _MetronomeToggle(
                    phaseKey: phaseKey,
                    checked: metronomeEnabled,
                    enabled: enabled,
                    onChanged: onMetronomeChanged,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _durationField()),
                  if (metronomeEnabled) ...[
                    const SizedBox(width: 8),
                    Expanded(child: _bpmField()),
                  ],
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _durationField() {
    return CompactDurationField(
      fieldKey: ValueKey('$phaseKey-duration'),
      controller: durationController,
      format: DurationInputFormat.minutesSeconds,
      semanticLabel: '$title duration',
      enabled: enabled,
      errorText: durationError,
      onChanged: onChanged,
    );
  }

  Widget _bpmField() {
    final bpm = int.tryParse(bpmController.text);
    final canDecrease = enabled && bpm != null && bpm > MetronomeConfig.minBpm;
    final canIncrease = enabled && bpm != null && bpm < MetronomeConfig.maxBpm;

    return TextField(
      key: ValueKey('$phaseKey-metronome-bpm'),
      controller: bpmController,
      enabled: enabled,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.next,
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(3),
      ],
      onChanged: (_) => onChanged(),
      decoration: InputDecoration(
        labelText: 'BPM',
        isDense: true,
        errorText: bpmError,
        errorMaxLines: 2,
        prefixIcon: _BpmStepButton(
          buttonKey: ValueKey('$phaseKey-bpm-decrease'),
          tooltip: 'Decrease $title BPM',
          icon: Icons.remove_rounded,
          onPressed: canDecrease ? () => _changeBpm(-1) : null,
        ),
        prefixIconConstraints: const BoxConstraints(
          minWidth: 36,
          minHeight: 40,
        ),
        suffixIcon: _BpmStepButton(
          buttonKey: ValueKey('$phaseKey-bpm-increase'),
          tooltip: 'Increase $title BPM',
          icon: Icons.add_rounded,
          onPressed: canIncrease ? () => _changeBpm(1) : null,
        ),
        suffixIconConstraints: const BoxConstraints(
          minWidth: 36,
          minHeight: 40,
        ),
      ),
    );
  }

  void _changeBpm(int delta) {
    final current = int.tryParse(bpmController.text);
    if (current == null) {
      return;
    }
    final next = (current + delta).clamp(
      MetronomeConfig.minBpm,
      MetronomeConfig.maxBpm,
    );
    bpmController.value = TextEditingValue(
      text: '$next',
      selection: TextSelection.collapsed(offset: '$next'.length),
    );
    onChanged();
  }
}

class _BpmStepButton extends StatelessWidget {
  const _BpmStepButton({
    required this.buttonKey,
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final Key buttonKey;
  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      key: buttonKey,
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, size: 19),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 40),
    );
  }
}

class _PhaseLabel extends StatelessWidget {
  const _PhaseLabel({
    required this.title,
    required this.icon,
    required this.color,
  });

  final String title;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _MetronomeToggle extends StatelessWidget {
  const _MetronomeToggle({
    required this.phaseKey,
    required this.checked,
    required this.enabled,
    required this.onChanged,
  });

  final String phaseKey;
  final bool checked;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Metronome',
      child: Semantics(
        label: 'Metronome',
        checked: checked,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: enabled ? () => onChanged(!checked) : null,
          child: Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.speed_rounded, size: 20),
                const SizedBox(width: 4),
                const Text(
                  'BPM',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                Checkbox(
                  key: ValueKey('$phaseKey-metronome-checkbox'),
                  value: checked,
                  onChanged: enabled
                      ? (value) => onChanged(value ?? false)
                      : null,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
