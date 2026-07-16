import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NumericField extends StatelessWidget {
  const NumericField({
    required this.fieldKey,
    required this.controller,
    required this.label,
    required this.enabled,
    required this.onChanged,
    this.semanticLabel,
    super.key,
  });

  final Key fieldKey;
  final TextEditingController controller;
  final String label;
  final String? semanticLabel;
  final bool enabled;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      textField: true,
      label: semanticLabel ?? label,
      child: TextField(
        key: fieldKey,
        controller: controller,
        enabled: enabled,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.next,
        inputFormatters: <TextInputFormatter>[
          FilteringTextInputFormatter.digitsOnly,
        ],
        onChanged: onChanged,
        decoration: InputDecoration(labelText: label, counterText: ''),
      ),
    );
  }
}
