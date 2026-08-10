import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Field spec untuk FilterBottomSheet.
abstract class FilterField<T> {
  final String label;
  final T value;
  const FilterField({required this.label, required this.value});
}

/// Dropdown field (karyawan, status, dll — nilai dari API).
class DropdownFilterField<T> extends FilterField<T?> {
  final List<(T, String)> options;
  const DropdownFilterField({
    required super.label,
    required super.value,
    required this.options,
  }) : super();
}

/// Date-range field.
class DateRangeFilterField extends FilterField<(DateTime, DateTime)?> {
  const DateRangeFilterField({required super.label, required super.value})
      : super();
}

/// Chip field untuk filter cepat inline (≤1 filter).
class ChipFilterField<T> extends FilterField<T?> {
  final List<(T, String)> options;
  const ChipFilterField({
    required super.label,
    required super.value,
    required this.options,
  }) : super();
}

/// Bottom sheet generik untuk filter.
/// Panggil: FilterBottomSheet.show(context, fields: [...], onApply: (...) {})
class FilterBottomSheet extends StatefulWidget {
  final List<FilterField> fields;
  final void Function(Map<String, dynamic>) onApply;
  final String title;
  final VoidCallback? onReset;

  const FilterBottomSheet({
    super.key,
    required this.fields,
    required this.onApply,
    this.title = 'Filter',
    this.onReset,
  });

  static Future<void> show(
    BuildContext context, {
    required List<FilterField> fields,
    required void Function(Map<String, dynamic>) onApply,
    String title = 'Filter',
    VoidCallback? onReset,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => FilterBottomSheet(
        fields: fields,
        onApply: onApply,
        title: title,
        onReset: onReset,
      ),
    );
  }

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late Map<String, dynamic> _values;

  @override
  void initState() {
    super.initState();
    _values = {for (var f in widget.fields) f.label: f.value};
  }

  void _updateValue(String label, dynamic value) {
    setState(() => _values[label] = value);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          color: cs.surface.withValues(alpha: 0.85),
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: cs.onSurfaceVariant.withValues(alpha: 0.4),
              borderRadius: AppSpacing.borderRadiusXS,
            ),
          ),
          Padding(
            padding: AppSpacing.paddingMD,
            child: Row(
              children: [
                Text(widget.title, style: tt.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const Spacer(),
                if (widget.onReset != null)
                  TextButton(onPressed: widget.onReset, child: const Text('Reset')),
              ],
            ),
          ),
          const Divider(height: 1),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: AppSpacing.paddingMD,
              itemCount: widget.fields.length,
              separatorBuilder: (_, __) => AppSpacing.gapVerticalLG,
              itemBuilder: (_, i) {
                final field = widget.fields[i];
                return _buildField(field);
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: AppSpacing.paddingMD,
              child: Row(
                children: [
                  if (widget.onReset != null)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: widget.onReset,
                        child: const Text('Reset'),
                      ),
                    ),
                  if (widget.onReset != null) AppSpacing.gapHorizontalMD,
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onApply(_values);
                      },
                      child: const Text('Terapkan'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  ),
  ),
);
  }

  Widget _buildField(FilterField field) {
    if (field is DropdownFilterField) {
      return _DropdownFieldWidget(
        label: field.label,
        value: _values[field.label],
        options: field.options,
        onChanged: (v) => _updateValue(field.label, v),
      );
    }
    if (field is DateRangeFilterField) {
      return _DateRangeFieldWidget(
        label: field.label,
        value: _values[field.label],
        onChanged: (v) => _updateValue(field.label, v),
      );
    }
    if (field is ChipFilterField) {
      return _ChipFieldWidget(
        label: field.label,
        value: _values[field.label],
        options: field.options,
        onChanged: (v) => _updateValue(field.label, v),
      );
    }
    return const SizedBox.shrink();
  }
}

class _DropdownFieldWidget<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<(T, String)> options;
  final ValueChanged<T?> onChanged;

  const _DropdownFieldWidget({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: tt.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
        AppSpacing.gapVerticalXS,
        InkWell(
          onTap: () => _showDropdown(context),
          borderRadius: AppSpacing.borderRadiusMD,
          child: Container(
            padding: AppSpacing.paddingSM.copyWith(right: AppSpacing.md),
            decoration: BoxDecoration(
              border: Border.all(color: cs.outlineVariant),
              borderRadius: AppSpacing.borderRadiusMD,
              color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value != null ? _labelFor(value) : 'Pilih $label',
                    style: tt.bodyMedium?.copyWith(
                      color: value != null ? cs.onSurface : cs.onSurfaceVariant,
                    ),
                  ),
                ),
                Icon(Icons.keyboard_arrow_down, color: cs.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Returns the display label for [v] from [options], or a fallback string
  /// when [v] is not present (e.g. the selected id is no longer in the list).
  ///
  /// A plain loop is used instead of `firstWhere(orElse:)` on purpose: the
  /// sheet is generic on `T` but built with `T = dynamic` (see `_buildField`),
  /// so an `orElse` fallback closure would be checked against the *runtime*
  /// element type of `options` (e.g. `(int, String)`) and crash with a
  /// `(dynamic, String) is not a subtype of (int, String)` TypeError when
  /// `value` isn't found.
  ///
  /// The parameter is `T?` (not `T`) because `T` may itself be nullable (e.g.
  /// `DropdownFilterField<int?>`), so a `value != null` check cannot promote
  /// `T?` to `T` for a type parameter.
  String _labelFor(T? v) {
    for (final opt in options) {
      if (opt.$1 == v) return opt.$2;
    }
    return '$v';
  }

  void _showDropdown(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        expand: false,
        builder: (_, controller) => Column(
          children: [
            const SizedBox(height: 10),
            Container(width: 40, height: 4, color: Theme.of(context).colorScheme.outlineVariant),
            Padding(
              padding: AppSpacing.paddingMD,
              child: Row(
                children: [
                  Text(label, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                controller: controller,
                padding: AppSpacing.paddingHorizontalMD,
                itemCount: options.length + 1,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  if (i == 0) {
                    return ListTile(
                      title: Text('Semua $label', style: Theme.of(context).textTheme.bodyMedium),
                      leading: Radio<T?>(
                        value: null,
                        // ignore: deprecated_member_use
                        groupValue: value,
                        // ignore: deprecated_member_use
                        onChanged: (v) {
                          onChanged(v);
                          Navigator.pop(ctx);
                        },
                      ),
                    );
                  }
                  final opt = options[i - 1];
                  return ListTile(
                    title: Text(opt.$2),
                    leading: Radio<T?>(
                      value: opt.$1,
                      // ignore: deprecated_member_use
                      groupValue: value,
                      // ignore: deprecated_member_use
                      onChanged: (v) {
                        onChanged(v);
                        Navigator.pop(ctx);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateRangeFieldWidget extends StatelessWidget {
  final String label;
  final (DateTime, DateTime)? value;
  final ValueChanged<(DateTime, DateTime)?> onChanged;

  const _DateRangeFieldWidget({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final fmt = DateFormat('dd MMM yyyy', 'id_ID');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: tt.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
        AppSpacing.gapVerticalXS,
        InkWell(
          onTap: () => _pickDateRange(context),
          borderRadius: AppSpacing.borderRadiusMD,
          child: Container(
            padding: AppSpacing.paddingSM.copyWith(right: AppSpacing.md),
            decoration: BoxDecoration(
              border: Border.all(color: cs.outlineVariant),
              borderRadius: AppSpacing.borderRadiusMD,
              color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
            ),
            child: Row(
              children: [
                Icon(Icons.date_range, color: AppColors.info, size: 20),
                AppSpacing.gapHorizontalSM,
                Expanded(
                  child: Text(
                    value != null
                        ? '${fmt.format(value!.$1)} - ${fmt.format(value!.$2)}'
                        : 'Pilih $label',
                    style: tt.bodyMedium?.copyWith(
                      color: value != null ? cs.onSurface : cs.onSurfaceVariant,
                    ),
                  ),
                ),
                if (value != null)
                  IconButton(
                    icon: Icon(Icons.clear, size: 18, color: cs.onSurfaceVariant),
                    onPressed: () => onChanged(null),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _pickDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: value != null
          ? DateTimeRange(start: value!.$1, end: value!.$2)
          : null,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(colorScheme: Theme.of(ctx).colorScheme),
        child: child!,
      ),
    );
    if (picked != null) onChanged((picked.start, picked.end));
  }
}

class _ChipFieldWidget<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<(T, String)> options;
  final ValueChanged<T?> onChanged;

  const _ChipFieldWidget({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: tt.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
        AppSpacing.gapVerticalXS,
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            ChoiceChip(
              label: Text('Semua'),
              selected: value == null,
              onSelected: (_) => onChanged(null),
            ),
            ...options.map((opt) => ChoiceChip(
                  label: Text(opt.$2),
                  selected: value == opt.$1,
                  onSelected: (_) => onChanged(opt.$1),
                )),
          ],
        ),
      ],
    );
  }
}