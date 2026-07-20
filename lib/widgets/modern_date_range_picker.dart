import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class ModernDateRangePicker extends StatelessWidget {
  final DateTime? startDate;
  final DateTime? endDate;
  final Function(DateTime?, DateTime?) onDateRangeSelected;
  final DateTime? minDate;
  final DateTime? maxDate;
  final String? errorText;

  const ModernDateRangePicker({
    super.key,
    this.startDate,
    this.endDate,
    required this.onDateRangeSelected,
    this.minDate,
    this.maxDate,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final borderColor = errorText != null
        ? colorScheme.error
        : colorScheme.outlineVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: borderColor, width: 1),
            borderRadius: AppSpacing.borderRadiusSM,
          ),
          child: Column(
            children: [
              Padding(
                padding: AppSpacing.paddingSM,
                child: Row(
                  children: [
                    Icon(Icons.date_range, color: AppColors.info),
                    AppSpacing.gapHorizontalSM,
                    Expanded(
                      child: Text(
                        _formatDateRange(startDate, endDate),
                        style: textTheme.bodyLarge,
                      ),
                    ),
                  ],
                ),
              ),
              SfDateRangePicker(
                selectionMode: DateRangePickerSelectionMode.range,
                initialSelectedRange: startDate != null && endDate != null
                    ? PickerDateRange(startDate, endDate)
                    : null,
                minDate: minDate ?? DateTime.now(),
                maxDate: maxDate,
                onSelectionChanged: (DateRangePickerSelectionChangedArgs args) {
                  if (args.value is PickerDateRange) {
                    final range = args.value as PickerDateRange;
                    onDateRangeSelected(range.startDate, range.endDate);
                  }
                },
                monthViewSettings: DateRangePickerMonthViewSettings(
                  firstDayOfWeek: 1,
                  viewHeaderStyle: DateRangePickerViewHeaderStyle(
                    textStyle: textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                headerStyle: DateRangePickerHeaderStyle(
                  textStyle: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                monthFormat: 'MMMM',
                todayHighlightColor: colorScheme.primary,
                selectionColor: colorScheme.primary,
                rangeSelectionColor:
                    colorScheme.primary.withValues(alpha: 0.1),
                startRangeSelectionColor: colorScheme.primary,
                endRangeSelectionColor: colorScheme.primary,
              ),
            ],
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 12),
            child: Text(
              errorText!,
              style: textTheme.labelSmall?.copyWith(
                color: colorScheme.error,
              ),
            ),
          ),
      ],
    );
  }

  String _formatDateRange(DateTime? start, DateTime? end) {
    if (start == null && end == null) {
      return 'Pilih tanggal';
    }

    final DateFormat formatter = DateFormat('dd MMM yyyy', 'id_ID');
    if (start != null && end != null) {
      return '${formatter.format(start)} - ${formatter.format(end)}';
    } else if (start != null) {
      return formatter.format(start);
    } else if (end != null) {
      return formatter.format(end);
    }

    return 'Pilih tanggal';
  }
}