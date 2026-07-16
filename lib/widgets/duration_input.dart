import 'package:flutter/material.dart';

import 'numeric_field.dart';

class DurationInput extends StatelessWidget {
  const DurationInput({
    required this.inputKey,
    required this.title,
    required this.icon,
    required this.accentColor,
    required this.minutesController,
    required this.secondsController,
    required this.enabled,
    required this.onChanged,
    this.hoursController,
    this.errorText,
    super.key,
  });

  final Key inputKey;
  final String title;
  final IconData icon;
  final Color accentColor;
  final TextEditingController? hoursController;
  final TextEditingController minutesController;
  final TextEditingController secondsController;
  final bool enabled;
  final VoidCallback onChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      key: inputKey,
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
              Icon(icon, color: accentColor),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hoursController != null) ...[
                Expanded(
                  child: NumericField(
                    fieldKey: ValueKey('${_keyPrefix(inputKey)}-hours'),
                    controller: hoursController!,
                    label: 'Hours',
                    semanticLabel: '$title hours',
                    enabled: enabled,
                    onChanged: (_) => onChanged(),
                  ),
                ),
                const _TimeSeparator(),
              ],
              Expanded(
                child: NumericField(
                  fieldKey: ValueKey('${_keyPrefix(inputKey)}-minutes'),
                  controller: minutesController,
                  label: 'Minutes',
                  semanticLabel: '$title minutes',
                  enabled: enabled,
                  onChanged: (_) => onChanged(),
                ),
              ),
              const _TimeSeparator(),
              Expanded(
                child: NumericField(
                  fieldKey: ValueKey('${_keyPrefix(inputKey)}-seconds'),
                  controller: secondsController,
                  label: 'Seconds',
                  semanticLabel: '$title seconds',
                  enabled: enabled,
                  onChanged: (_) => onChanged(),
                ),
              ),
            ],
          ),
          if (errorText != null) ...[
            const SizedBox(height: 8),
            Text(
              errorText!,
              style: textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _keyPrefix(Key key) {
    if (key is ValueKey<String>) {
      return key.value;
    }
    return 'duration';
  }
}

class _TimeSeparator extends StatelessWidget {
  const _TimeSeparator();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(7, 18, 7, 0),
      child: ExcludeSemantics(
        child: Text(
          ':',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
