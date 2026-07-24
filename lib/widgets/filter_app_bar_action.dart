import 'package:badges/badges.dart' as badges;
import 'package:flutter/material.dart';

/// AppBar action untuk filter.
/// [activeCount] = jumlah filter aktif (tampil sebagai badge).
/// [onTap] = biasanya buka FilterBottomSheet.
class FilterAppBarAction extends StatelessWidget {
  final int activeCount;
  final VoidCallback onTap;
  final String tooltip;

  const FilterAppBarAction({
    super.key,
    required this.activeCount,
    required this.onTap,
    this.tooltip = 'Filter',
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return IconButton(
      onPressed: onTap,
      tooltip: tooltip,
      icon: activeCount > 0
          ? badges.Badge(
              position: badges.BadgePosition.topEnd(top: -4, end: -4),
              badgeContent: Text(
                activeCount > 9 ? '9+' : activeCount.toString(),
                style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              badgeStyle: badges.BadgeStyle(
                badgeColor: cs.primary,
                padding: const EdgeInsets.all(4),
              ),
              child: const Icon(Icons.tune),
            )
          : const Icon(Icons.tune),
    );
  }
}