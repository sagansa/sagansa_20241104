import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ModernDateField extends StatelessWidget {
  final String labelText;
  final DateTime? value;
  final Function(DateTime?) onChanged;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final String? errorText;
  final bool enabled;

  const ModernDateField({
    super.key,
    required this.labelText,
    required this.value,
    required this.onChanged,
    this.firstDate,
    this.lastDate,
    this.errorText,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: TextEditingController(
        text: value == null ? '' : DateFormat('dd MMM yyyy').format(value!),
      ),
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: const Icon(Icons.calendar_today),
        errorText: errorText,
      ),
      readOnly: true,
      enabled: enabled,
      onTap: enabled
          ? () async {
              final effectiveFirstDate = firstDate ?? DateTime.now();
              final effectiveLastDate =
                  lastDate ?? DateTime.now().add(const Duration(days: 365));
              final initial = value ?? DateTime.now();
              final clamped = initial.isBefore(effectiveFirstDate)
                  ? effectiveFirstDate
                  : initial.isAfter(effectiveLastDate)
                      ? effectiveLastDate
                      : initial;
              final date = await showDatePicker(
                context: context,
                initialDate: clamped,
                firstDate: effectiveFirstDate,
                lastDate: effectiveLastDate,
              );
              if (date != null) {
                onChanged(date);
              }
            }
          : null,
    );
  }
}