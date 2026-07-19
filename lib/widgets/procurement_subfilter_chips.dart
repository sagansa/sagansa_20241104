import 'package:flutter/material.dart';

/// Sub-filter chip row horizontal, scrollable.
///
/// Generic: panggilan yang menentukan options, activeColor, dan activeIndex.
/// Stage Request/Invoice/Payment punya opsi berbeda (lihat spec section 4.4).
class ProcurementSubfilterChips extends StatelessWidget {
  final List<String> options;
  final int activeIndex;
  final Color activeColor;
  final void Function(int index)? onChipTap;

  const ProcurementSubfilterChips({
    super.key,
    required this.options,
    required this.activeIndex,
    required this.activeColor,
    this.onChipTap,
  });

  @override
  Widget build(BuildContext context) {
    if (options.isEmpty) return const SizedBox.shrink();
    return Container(
      color: Theme.of(context)
          .colorScheme
          .surfaceContainerHighest
          .withValues(alpha: 0.3),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(options.length, (i) => _buildChip(context, i)),
        ),
      ),
    );
  }

  Widget _buildChip(BuildContext context, int index) {
    final isActive = index == activeIndex;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: () => onChipTap?.call(index),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isActive ? activeColor : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: isActive
                ? null
                : Border.all(
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                  ),
          ),
          child: Text(
            options[index],
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isActive ? Colors.white : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
