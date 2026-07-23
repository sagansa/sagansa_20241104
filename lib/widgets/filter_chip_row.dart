import 'package:flutter/material.dart';

class FilterChipRow<T> extends StatelessWidget {
  final List<T> options;
  final T? selected;
  final ValueChanged<T?> onSelected;
  final String Function(T) getLabel;
  final bool scrollable;

  const FilterChipRow({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
    required this.getLabel,
    this.scrollable = true,
  });

  @override
  Widget build(BuildContext context) {
    final chips = options.map((option) {
      final isSelected = option == selected;
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(getLabel(option)),
          selected: isSelected,
          onSelected: (val) => onSelected(val ? option : null),
        ),
      );
    }).toList();

    if (scrollable) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: chips),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: chips,
    );
  }
}
