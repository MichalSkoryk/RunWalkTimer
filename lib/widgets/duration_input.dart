import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/duration_input_format.dart';

class DurationInput extends StatelessWidget {
  const DurationInput({
    required this.inputKey,
    required this.title,
    required this.icon,
    required this.accentColor,
    required this.controller,
    required this.format,
    required this.enabled,
    required this.onChanged,
    this.errorText,
    super.key,
  });

  final Key inputKey;
  final String title;
  final IconData icon;
  final Color accentColor;
  final TextEditingController controller;
  final DurationInputFormat format;
  final bool enabled;
  final VoidCallback onChanged;
  final String? errorText;

  void _normalize() {
    final duration = parseDurationInput(controller.text, format);
    if (duration == null) {
      return;
    }

    final normalized = formatDurationInput(duration, format);
    if (controller.text == normalized) {
      return;
    }

    controller.value = TextEditingValue(
      text: normalized,
      selection: TextSelection.collapsed(offset: normalized.length),
    );
    onChanged();
  }

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
          Focus(
            onFocusChange: (hasFocus) {
              if (!hasFocus) {
                _normalize();
              }
            },
            child: Semantics(
              textField: true,
              label: '$title, ${format.label}',
              child: TextField(
                key: ValueKey('${_keyPrefix(inputKey)}-duration'),
                controller: controller,
                enabled: enabled,
                keyboardType: TextInputType.datetime,
                textInputAction: TextInputAction.next,
                autocorrect: false,
                enableSuggestions: false,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9:]')),
                ],
                onChanged: (_) => onChanged(),
                onEditingComplete: () {
                  _normalize();
                  FocusManager.instance.primaryFocus?.nextFocus();
                },
                decoration: InputDecoration(
                  labelText: format.label,
                  hintText: switch (format) {
                    DurationInputFormat.minutesSeconds => '01:30',
                    DurationInputFormat.hoursMinutesSeconds => '00:20:00',
                  },
                ),
              ),
            ),
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
