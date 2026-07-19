import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MetronomeConfigInput extends StatelessWidget {
  const MetronomeConfigInput({
    required this.phaseKey,
    required this.enabled,
    required this.checked,
    required this.bpmController,
    required this.errorText,
    required this.onCheckedChanged,
    required this.onChanged,
    super.key,
  });

  final String phaseKey;
  final bool enabled;
  final bool checked;
  final TextEditingController bpmController;
  final String? errorText;
  final ValueChanged<bool> onCheckedChanged;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          CheckboxListTile(
            key: ValueKey('$phaseKey-metronome-checkbox'),
            value: checked,
            onChanged: enabled
                ? (value) => onCheckedChanged(value ?? false)
                : null,
            secondary: const Icon(Icons.speed_rounded),
            title: const Text(
              'Metronome',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: const Text('Play a steady beat during this phase.'),
            controlAffinity: ListTileControlAffinity.trailing,
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: checked
                ? Padding(
                    key: ValueKey('$phaseKey-metronome-bpm-container'),
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: TextField(
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
                        labelText: 'Beats per minute',
                        suffixText: 'BPM',
                        helperText: 'Enter a value from 70 to 180.',
                        errorText: errorText,
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
