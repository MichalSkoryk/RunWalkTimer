import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/duration_input_format.dart';

class CompactDurationField extends StatelessWidget {
  const CompactDurationField({
    required this.fieldKey,
    required this.controller,
    required this.format,
    required this.semanticLabel,
    required this.enabled,
    required this.onChanged,
    this.errorText,
    super.key,
  });

  final Key fieldKey;
  final TextEditingController controller;
  final DurationInputFormat format;
  final String semanticLabel;
  final bool enabled;
  final VoidCallback onChanged;
  final String? errorText;

  void _normalize() {
    final duration = parseDurationInput(controller.text, format);
    if (duration == null) {
      return;
    }
    final normalized = formatDurationInput(duration, format);
    if (normalized == controller.text) {
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
    return Focus(
      onFocusChange: (hasFocus) {
        if (!hasFocus) {
          _normalize();
        }
      },
      child: Semantics(
        textField: true,
        label: '$semanticLabel, ${format.label}',
        child: TextField(
          key: fieldKey,
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
            isDense: true,
            errorText: errorText,
            errorMaxLines: 2,
          ),
        ),
      ),
    );
  }
}
