import 'package:flutter/material.dart';
import '../../theme/app_spacing.dart';

/// Compact card widget untuk grid dashboard Home.
///
/// Pattern: icon box (kiri atas) + badge (kanan atas) + value (tengah) + label (bawah).
/// Dipakai oleh semua admin card dan staff dashboard card.
class HomeCompactCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  final String? badge;
  final Color? badgeColor;
  final VoidCallback? onTap;
  final bool isLoading;

  const HomeCompactCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    this.badge,
    this.badgeColor,
    this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final displayValue = isLoading ? '...' : value;

    final card = Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: AppSpacing.paddingSM,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Row atas: icon kiri + badge kanan
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.15),
                    borderRadius: AppSpacing.borderRadiusSM,
                  ),
                  child: Icon(icon, color: iconColor, size: 16),
                ),
                if (badge != null)
                  Text(
                    badge!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: badgeColor ?? colorScheme.error,
                      fontWeight: FontWeight.bold,
                      fontSize: 9,
                    ),
                  )
                else
                  const SizedBox.shrink(),
              ],
            ),
            // Value tengah
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                displayValue,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            // Label bawah
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: AppSpacing.borderRadiusMD,
        child: card,
      );
    }
    return card;
  }
}
